# Applying omarchy PR #9783: Fix Windows VM helper rejecting setgid source directories

**PR:** https://github.com/omacom/omarchy/pull/9783
**Branch:** `fix/windows-vm-setgid-chmod` → `omacom:quattro`
**Affected file:** `bin/omarchy-windows-vm` (installed at `/usr/bin/omarchy-windows-vm`)

---

## 1. The problem

GNU `chmod 0700` **leaves setuid/setgid bits set on directories** when the numeric mode is four digits or fewer. On a real directory it does the equivalent of `u=rwx,go=` and never touches the special bits.

The Windows VM helper then requires the VM source directories (`~/.windows`, `~/Windows`) to be *exactly* mode `700`. When `~/Windows` was created setgid (commonly `2700` or `2777`) — for example after dockur's `samba.sh` does `chmod 2777` on the empty `/shared` bind — every privileged VM action fails closed with **no diagnostic**. This is the silent "launch fails every other run" bug.

Related issues fixed: #9698, #9374, #9334, #9540, #9567, #9884, #9943, #9746.

### Why the check fails

```bash
stat -Lc '%a' ~/Windows    # 2777 under setgid
chmod 0700 ~/Windows       # still 2777 — numeric chmod does NOT clear g+s
stat -Lc '%a' ~/Windows    # 2777 → exact-700 check fails → launch refused
```

`chmod a-s,u=rwx,go=` *does* clear the special bits, which is the whole fix.

---

## 2. What the PR changes

1. **`chmod_private_dir()`** — new helper: `chmod a-s,u=rwx,go=` (clears setuid/setgid/sticky). Replaces all three `chmod 0700` sites:
   - `prepare_caller_mounts` (privileged hardening of pinned FDs before the exact-700 check)
   - `prepare_user_mount_sources` (user-side preflight)
   - `write_credentials` (credentials dir)
2. **Diagnostic on failure** — the post-chmod mode check now prints `storage=<mode> shared=<mode>` instead of failing silently.
3. **`restore_shared_privacy()` / `restore_all_shared_privacy()`** — re-harden `~/Windows` after dockur's `chmod 2777`, acting only on the root-owned **bind anchor** (`/var/lib/omarchy/windows/mounts/users/<uid>/shared`), never on the caller-owned `~/Windows` pathname. This closes the TOCTOU arbitrary-chmod hole.
4. **Restore timing** — restore happens after `windows started successfully` (so it lands after samba.sh, not racing `dc up -d`), on `up_wait` timeout, and on `stop`/`down` (root walks the tree; sudoless-Docker users restore their own anchor owner-side). Best-effort — a restore failure never fails a successful start/stop.
5. **Install-path watcher** — `install` goes through `priv up` (a 10–15 min download), so it schedules `watch_share_privacy` (via a transient systemd user unit, falling back to a HUP/TERM-immune background subshell) that chmods `~/Windows` once it becomes `2777`. Budget: 1 hour.
6. **`privileged_copy_matches()`** — refuses to elevate via `pkexec` if the packaged copy at `/usr/bin/omarchy-windows-vm` differs from the running build (a stale package would re-apply the old `chmod 0700` semantics with no diagnostic).

---

## 3. The full patch

Save the block below as `pr9783.patch`:

```diff
--- a/bin/omarchy-windows-vm
+++ b/bin/omarchy-windows-vm
@@ -77,6 +77,24 @@
   printf '%s\n' "$candidate"
 }
 
+# pkexec can only run the packaged copy at its fixed root-owned path, which a
+# dev-link checkout never shadows: the unprivileged half then runs the checkout
+# while the elevated half runs the package. All privileged mount work happens in
+# the elevated half, so a stale packaged copy would re-apply whatever chmod
+# semantics it shipped with and fail closed with no diagnostic (observed as a
+# launch refusing a 2777 share and leaving it at 2700). Refuse unless both
+# halves are the same build.
+privileged_copy_matches() {
+  local target="$1" target_hash self_hash
+  [[ -r ${BASH_SOURCE[0]} && -r $target ]] || return 1
+  # The common case runs both halves from the same file; only a dev checkout
+  # needs the content comparison.
+  [[ ${BASH_SOURCE[0]} -ef $target ]] && return 0
+  target_hash=$(sha256sum -- "$target") || return 1
+  self_hash=$(sha256sum -- "${BASH_SOURCE[0]}") || return 1
+  [[ ${target_hash%% *} == "${self_hash%% *}" ]]
+}
+
 # Run a privileged VM action. write_compose always elevates (the compose is
 # root-owned); the daemon operations run directly when sudoless Docker is on and
 # otherwise behind a polkit prompt. The stock org.freedesktop.policykit.exec
@@ -104,6 +122,10 @@
     echo "omarchy-windows-vm: refusing to run a non-root-owned command as root" >&2
     return 1
   }
+  privileged_copy_matches "$target" || {
+    echo "omarchy-windows-vm: refusing to elevate: $target is not this command; refresh the installed omarchy package so root runs the same build" >&2
+    return 1
+  }
   pkexec "$target" __priv "$action" "$@"
 }
 
@@ -554,6 +576,102 @@
   }
 }
 
+# Make a directory mode 700, including leftover setuid/setgid. GNU chmod keeps
+# those bits on directories for numeric modes of four digits or fewer, so
+# `chmod 0700` cannot satisfy the exact-700 checks when ~/Windows was created
+# setgid (omacom/omarchy#9698).
+chmod_private_dir() {
+  chmod a-s,u=rwx,go= -- "$@"
+}
+
+# dockur samba.sh chmod 2777s an empty /shared at container start. Re-harden
+# only the protected anchor, which sits in the root-owned boundary tree the
+# caller cannot write: it is a bind of the same inode as $LEGACY_SHARED, so this
+# is what ~/Windows ends up at. Never chmod $LEGACY_SHARED by pathname — the
+# caller can swap it for a symlink between the test and the chmod.
+# Best-effort: a failed chmod must not fail a VM that already started.
+restore_shared_privacy() {
+  [[ -n $EXPECTED_SHARED && -d $EXPECTED_SHARED && ! -L $EXPECTED_SHARED ]] || return 0
+  chmod_private_dir "$EXPECTED_SHARED" || true
+}
+
+# Root-only: the mounts tree is 0711, so an unprivileged caller cannot list it
+# and the glob below would silently match nothing. After `dc down` there is no
+# PKEXEC_UID on a direct `sudo ... stop`, and a second user on the box would
+# resolve a different per-uid anchor, so root walks the tree instead. A
+# sudoless caller restores its own anchor through restore_shared_privacy.
+restore_all_shared_privacy() {
+  local dir canonical prefix
+  ((EUID == 0)) || return 0
+  # Same refusal prepare_runtime_tree applies: a non-standard privileged
+  # runtime is supported only for unprivileged tests/development.
+  [[ $RUNTIME_DIR == /var/lib/omarchy/windows ]] || return 0
+  prefix=$(realpath -e -- "$RUNTIME_DIR/mounts/users" 2>/dev/null) || return 0
+  for dir in "$prefix"/*/shared; do
+    [[ -d $dir && ! -L $dir ]] || continue
+    canonical=$(realpath -e -- "$dir" 2>/dev/null) || continue
+    [[ $canonical == "$dir" ]] || continue
+    [[ $canonical == "$prefix/"*"/shared" ]] || continue
+    chmod_private_dir "$canonical" || true
+  done
+}
+
+# Unprivileged: samba.sh runs only after dockur's ISO download (10-15 minutes
+# on a fresh install). Do not hold a polkit session open for that. Watch the
+# caller's own share and chmod it as the owner once it becomes 2777.
+watch_share_privacy() {
+  local dir="$1" i mode result
+  [[ -e $dir ]] || return 0
+  # 2x the documented 10-15 minute download is a thin margin on a slow link,
+  # so budget an hour; on expiry restore only if the share is still exposed.
+  for i in {1..3600}; do
+    mode=$(stat -Lc '%a' "$dir" 2>/dev/null) || mode=""
+    if [[ $mode == 2777 || $mode == 777 ]]; then
+      chmod_private_dir "$dir" 2>/dev/null || true
+      # Do not exit on a failed chmod: a transient failure (a swapped path,
+      # an unwritable moment) must not end the watcher permanently while the
+      # share is still exposed. Leave only once the mode is really 700.
+      [[ $(stat -Lc '%a' "$dir" 2>/dev/null) == 700 ]] && return 0
+    fi
+    sleep 1
+  done
+  mode=$(stat -Lc '%a' "$dir" 2>/dev/null) || mode=""
+  if [[ $mode == 2777 || $mode == 777 ]]; then
+    chmod_private_dir "$dir" 2>/dev/null || true
+  fi
+  result=$(stat -Lc '%a' "$dir" 2>/dev/null) || result="missing"
+  logger -t omarchy-windows-vm \
+    "share privacy watcher timed out; $dir mode is $result" 2>/dev/null || true
+}
+
+schedule_share_privacy_restore() {
+  local dir="$HOME/Windows" self
+  [[ -e $dir ]] || return 0
+  self=$(readlink -f -- "${BASH_SOURCE[0]}") || self="${BASH_SOURCE[0]}"
+  # install runs inside omarchy-launch-floating-terminal-with-presentation,
+  # which is a uwsm-app systemd scope. Dismissing that window SIGTERMs leftover
+  # cgroup members; trap '' HUP does not cover that. A user unit is outside
+  # the scope, so the wait survives the terminal.
+  if omarchy-cmd-present systemd-run; then
+    systemctl --user reset-failed omarchy-windows-share-privacy.service 2>/dev/null || true
+    systemctl --user stop omarchy-windows-share-privacy.service 2>/dev/null || true
+    if systemd-run --user --quiet --collect \
+      --unit=omarchy-windows-share-privacy \
+      --description="Restore ~/Windows mode after dockur samba.sh" \
+      /bin/bash -c 'set -- help; source "$1" >/dev/null; watch_share_privacy "$2"' \
+      bash "$self" "$dir"; then
+      return 0
+    fi
+  fi
+  # No user bus (tests, a stripped session): ignore HUP/TERM so a closing
+  # terminal cannot kill the wait the way the scope would.
+  (
+    trap '' HUP TERM
+    watch_share_privacy "$dir"
+  ) >/dev/null 2>&1 &
+  disown || true
+}
+
 prepare_caller_mounts() {
   local storage_fd storage_id shared_fd shared_id storage_mode shared_mode
   CALLER_MOUNTS_NEW_STORAGE=0
@@ -580,7 +698,7 @@
   # Privacy is an explicit preflight step for both already-pinned sources, not
   # a side effect halfway through the two-mount transaction. Old umask-022
   # installs are hardened together before either Docker-facing anchor changes.
-  chmod 0700 -- "/proc/$BASHPID/fd/$storage_fd" "/proc/$BASHPID/fd/$shared_fd" || {
+  chmod_private_dir "/proc/$BASHPID/fd/$storage_fd" "/proc/$BASHPID/fd/$shared_fd" || {
     exec {storage_fd}<&-
     exec {shared_fd}<&-
     return 1
@@ -588,6 +706,7 @@
   storage_mode=$(stat -Lc '%a' "/proc/$BASHPID/fd/$storage_fd" 2>/dev/null) || storage_mode=""
   shared_mode=$(stat -Lc '%a' "/proc/$BASHPID/fd/$shared_fd" 2>/dev/null) || shared_mode=""
   if [[ $storage_mode != 700 || $shared_mode != 700 ]]; then
+    echo "omarchy-windows-vm: VM source directories must be mode 700 (storage=$storage_mode shared=$shared_mode)" >&2
     exec {storage_fd}<&-
     exec {shared_fd}<&-
     return 1
@@ -895,7 +1014,25 @@
 
 __priv_up() { assert_mounts_safe && dc up -d; }
 
-__priv_down() { dc down; }
+__priv_down() {
+  local rc=0
+  dc down || rc=$?
+  if ((EUID == 0)); then
+    restore_all_shared_privacy
+  else
+    # A sudoless-Docker stop runs unelevated, where the mounts tree is not
+    # listable. restore_shared_privacy still works here: the anchor sits under
+    # the root-owned boundary tree the caller cannot rename, and while the
+    # bind exists it is the caller's own inode, so the owner chmod succeeds.
+    # If the bind is gone (fresh reboot) the chmod fails and the next launch
+    # re-hardens through prepare_caller_mounts instead. Best-effort: the
+    # container is already down, so a failed restore must not fail the stop.
+    if resolve_caller; then
+      restore_shared_privacy
+    fi
+  fi
+  return "$rc"
+}
 
 # Bring the VM up and wait until the guest reports it is ready, all under a
 # single elevation so the readiness poll does not prompt on every iteration.
@@ -913,11 +1050,15 @@
   while true; do
     started_at=$(docker inspect --format='{{.State.StartedAt}}' "$CONTAINER" 2>/dev/null)
     if [[ -n $started_at ]] && docker logs --since "$started_at" "$CONTAINER" 2>&1 | grep -qi "windows started successfully"; then
+      # samba.sh has already run by the time the guest reports ready, so this
+      # chmod lands after the 2777 rather than racing `dc up -d`.
+      restore_shared_privacy
       return 0
     fi
     sleep 2
     ((++count > 60)) && {
       echo "Timeout: Windows VM did not report ready within 2 minutes" >&2
+      restore_shared_privacy
       return 1
     }
   done
@@ -1015,7 +1156,7 @@
     echo "omarchy-windows-vm: storage and shared must be different directories" >&2
     return 1
   }
-  chmod 0700 -- "$storage" "$shared"
+  chmod_private_dir "$storage" "$shared" || return 1
 }
 
 storage_space_path() {
@@ -1058,7 +1199,7 @@
   local username="$1" password="$2" old_umask dir tmp
   dir=$(dirname -- "$CREDENTIALS_FILE")
   mkdir -p "$dir" || return 1
-  chmod 0700 "$dir" || return 1
+  chmod_private_dir "$dir" || return 1
   old_umask=$(umask)
   umask 077
   tmp=$(mktemp "$dir/.credentials.XXXXXX") || { umask "$old_umask"; return 1; }
@@ -1334,6 +1475,7 @@
     echo "   - Port already in use: check if another VM is running"
     exit 1
   fi
+  schedule_share_privacy_restore
 
   echo ""
   echo "Windows VM is starting up!"
```

---

## 4. Steps for a normal user to apply

### Option A — apply the patch (recommended if you have the PR patch file)

```bash
# 1. Save the diff above as pr9783.patch (in this directory it is already saved)

# 2. Watch out: the installed file lives under /usr/bin and the patch expects
#    the file at bin/omarchy-windows-vm relative to the repo root. To apply it
#    to the installed copy, copy it out and patch that copy:
cp /usr/bin/omarchy-windows-vm ./
patch --dry-run -p1 -i pr9783.patch <<< '' 2>&1 | head   # not needed, see below
```

The cleanest route:

```bash
# Prep: back up the current installed copy
sudo cp /usr/bin/omarchy-windows-vm /usr/bin/omarchy-windows-vm.bak

# Make a working copy inside a bin/ dir so -p1 lines up
mkdir -p bin
cp /usr/bin/omarchy-windows-vm bin/omarchy-windows-vm

# Apply the patch
patch --batch -p1 -i pr9783.patch
# expect: patching file bin/omarchy-windows-vm (applied at lines ...)

# Sanity check the syntax before installing
bash -n bin/omarchy-windows-vm && echo "syntax OK"

# Install as root with the original ownership/mode
sudo cp bin/omarchy-windows-vm /usr/bin/omarchy-windows-vm
sudo chown root:root /usr/bin/omarchy-windows-vm
sudo chmod 755 /usr/bin/omarchy-windows-vm

# Confirm it runs
/usr/bin/omarchy-windows-vm --help
```

### Option B — apply manually (no patch file)

Make these edits to `/usr/bin/omarchy-windows-vm` (back it up first: `sudo cp /usr/bin/omarchy-windows-vm /usr/bin/omarchy-windows-vm.bak`):

1. **Add the new functions.** Immediately after the `priv_target()` function (the one ending in `printf '%s\n' "$candidate"` + `}`), insert `privileged_copy_matches()`. Then, immediately before `prepare_caller_mounts()` (the function that calls `resolve_caller && prepare_runtime_tree`), insert `chmod_private_dir`, `restore_shared_privacy`, `restore_all_shared_privacy`, `watch_share_privacy`, and `schedule_share_privacy_restore` — all exactly as in the patch in section 3.

2. **In `priv()`**, after the `target=$(priv_target) || { ... return 1; }` block and before `pkexec "$target" ...`, add:

   ```bash
   privileged_copy_matches "$target" || {
     echo "omarchy-windows-vm: refusing to elevate: $target is not this command; refresh the installed omarchy package so root runs the same build" >&2
     return 1
   }
   ```

3. **In `prepare_caller_mounts()`**, change:

   ```bash
   chmod 0700 -- "/proc/$BASHPID/fd/$storage_fd" "/proc/$BASHPID/fd/$shared_fd"
   ```
   to:
   ```bash
   chmod_private_dir "/proc/$BASHPID/fd/$storage_fd" "/proc/$BASHPID/fd/$shared_fd"
   ```
   and inside the `if [[ $storage_mode != 700 || $shared_mode != 700 ]]; then` block add this **before** the `exec` calls:
   ```bash
   echo "omarchy-windows-vm: VM source directories must be mode 700 (storage=$storage_mode shared=$shared_mode)" >&2
   ```

4. **Replace `__priv_down`:**

   ```bash
   __priv_down() { dc down; }
   ```
   with the new `__priv_down()` from the patch (section 3).

5. **In `__priv_up_wait()`,** add `restore_shared_privacy` before both `return 0` (inside the `windows started successfully` branch) and `return 1` (inside the timeout block).

6. **In `prepare_user_mount_sources()`,** change `chmod 0700 -- "$storage" "$shared"` to:
   ```bash
   chmod_private_dir "$storage" "$shared" || return 1
   ```

7. **In `write_credentials()`,** change `chmod 0700 "$dir"` to:
   ```bash
   chmod_private_dir "$dir" || return 1
   ```

8. **In `install_windows()`,** after the `if ! priv up; then ... exit 1; fi` block and before the blank line / `echo ""`, add:
   ```bash
   schedule_share_privacy_restore
   ```

9. **Install:** `sudo cp` the edited file back to `/usr/bin/omarchy-windows-vm` (root:root, mode 755).

---

## 5. Verify it works

```bash
# 1. Syntax + basic run
bash -n /usr/bin/omarchy-windows-vm && /usr/bin/omarchy-windows-vm --help >/dev/null

# 2. The core fix — reproduce the old failure mode (do this as the VM user):
chmod 2777 ~/Windows            # simulate dockur's setgid leftover
stat -Lc '%a' ~/Windows         # => 2777

# 3. Run any privileged VM action (e.g. launch, stop). The helper should now
#    clear the bits and succeed instead of silently refusing:
omarchy-windows-vm status
stat -Lc '%a' ~/Windows         # => 700 after a launch/stop cycle
```

If something is still wrong, the new code prints a real diagnostic:

```
omarchy-windows-vm: VM source directories must be mode 700 (storage=... shared=...)
omarchy-windows-vm: refusing to elevate: /usr/bin/omarchy-windows-vm is not this command; ...
```

---

## 6. Reverting

```bash
sudo mv /usr/bin/omarchy-windows-vm.bak /usr/bin/omarchy-windows-vm
```

---

## 7. Notes

- **Only `bin/omarchy-windows-vm` was changed on this system.** The PR also adds regression tests (`test/shell.d/windows-vm-test.sh`, `test/shell.d/windows-vm-mount-boundary-test.sh`). Those live in the upstream repo's test suite (run on a disposable VM) and were **not** applied here because there is no omarchy source checkout on this machine.
- **Backup:** `/usr/bin/omarchy-windows-vm.bak-pr-9783` is the untouched pre-change copy (same content as the recommended `.bak` in section 4 — the restore command above works either way, adjust the filename).
- The patch was applied and verified with `bash -n` and `--help` on this machine (Sep 17 2026). You can rebuild a package delta later from the official PR if you prefer an RPM/deb-patched distribution; the manual patch is identical to the PR head.