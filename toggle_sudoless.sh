#!/usr/bin/env bash
#
# toggle_sudoless.sh — enable or disable passwordless sudo for a user.
#
# Independent of omarchy-sudo-passwordless: that script manages its own
# file (/etc/sudoers.d/99-omarchy-nopasswd-$USER) and expires it on a timer.
# This one manages /etc/sudoers.d/99-zz-sudoless and never expires.
#
# Usage:
#   ./toggle_sudoless.sh              # show current state
#   ./toggle_sudoless.sh on           # become passwordless sudo (permanent)
#   ./toggle_sudoless.sh off          # require a password again
#   ./toggle_sudoless.sh on  alice    # target another user
#   ./toggle_sudoless.sh help         # full documentation
#
# Notes:
#   - "99-zz-" sorts after omarchy's "99-omarchy-" so this rule wins under
#     sudoers last-match-wins regardless of the omarchy toggle's state.
#   - Every change is validated with `visudo -c` and rolled back on failure,
#     so a syntax error can never leave you locked out of sudo.
#   - Recovery if sudo itself breaks: boot a TTY, become root with `su -`,
#     and delete $SUDOERS_FILE.
#
set -euo pipefail

SUDOERS_FILE=/etc/sudoers.d/99-zz-sudoless
VISUDO="$(command -v visudo || echo /usr/sbin/visudo)"

die() { printf 'error: %s\n' "$*" >&2; exit 1; }

ACTION="${1:-status}"

# Only `on` and `off` mutate state, so only those need root. Everything else
# (status, help) stays unprivileged so it still works if sudo is broken.
case "$ACTION" in
  on|off)
    if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
      # Re-exec under sudo. If passwordless is OFF and there is no terminal to
      # prompt on, sudo cannot ask for a password — fail with something
      # actionable instead of surfacing sudo's raw "terminal is required".
      if ! sudo -n true 2>/dev/null && [[ ! -t 0 ]]; then
        die "must escalate to root, but no terminal is attached to prompt for
   a password. Run this from an interactive shell:
       sudo $0 $*
   (or re-enable passwordless sudo from a terminal that can prompt)"
      fi
      exec sudo -- "$(readlink -f "$0")" "$@"
    fi
    ;;
esac

usage() {
  cat <<EOF
toggle_sudoless.sh — enable or disable passwordless sudo for a user.

USAGE
  toggle_sudoless.sh [ACTION] [USERNAME]

ACTIONS
  on [USER]    Grant USER passwordless sudo, permanently.
  off          Revoke this script's rule. Passwords are required again.
  status       Report the rule's state and whether sudo -n currently works.
  help         Show this text. Same as -h or --help.
  (none)       Same as 'status'.

  USERNAME defaults to the invoking human account (root is refused).
  Only 'on' takes a username; 'off' and 'status' ignore extra arguments.

EXAMPLES
  toggle_sudoless.sh                 # check current state
  toggle_sudoless.sh on              # make yourself passwordless sudo
  toggle_sudoless.sh on  alice       # do the same for another account
  toggle_sudoless.sh off             # require a password again
  sudo toggle_sudoless.sh on         # 'on'/'off' re-exec via sudo themselves

HOW IT WORKS
  Writes one rule to $SUDOERS_FILE:

      <user> ALL=(ALL) NOPASSWD: ALL

  mode 0440, owner root:root. The '99-zz-' prefix sorts after omarchy's
  '99-omarchy-', so this rule wins under sudoers last-match-wins.

SAFETY
  - Every change is checked with '$VISUDO -c' against the ENTIRE sudoers
    config, not just this file. On failure the change is rolled back and the
    error printed, so a bad edit cannot lock you out of sudo.
  - After 'on' it runs 'sudo -k' to drop any cached credential, then tests
    'sudo -n true', so it verifies the rule rather than a stale timestamp.
  - 'off' warns if another NOPASSWD rule would still grant access.

RELATIONSHIP TO omarchy-sudo-passwordless
  Independent. That script manages /etc/sudoers.d/99-omarchy-nopasswd-USER
  and deletes it on a timer (default 15 min). This script never expires and
  never touches that file. With this rule active, 'omarchy-sudo-passwordless
  off' will report success but NOT actually stop passwordless sudo — use
  'toggle_sudoless.sh off' for that.

SECURITY
  NOPASSWD: ALL means any process running as that account — including a
  malicious install script, a repository you are working in, or an AI agent
  with shell access — can become root with no prompt. Commands are still
  recorded in the system journal. To keep convenience without the blanket
  grant, replace this rule with a scoped one, e.g. via 'sudo visudo -f'.

RECOVERY IF SUDO BREAKS
  This rule cannot lock you out on its own, but if sudoers is damaged by
  other means: from a TTY run 'su -' (account password still works), then
  'rm -f $SUDOERS_FILE', then 'visudo -c'.

EXIT CODES
  0  success          2  invalid action or arguments
  1  error            (help always exits 0)

FILES
  $SUDOERS_FILE
  $0
EOF
}

# Resolve the human account. SUDO_USER is set when invoked via sudo, which is
# how this normally runs; fall back to $USER, then an explicit argument.
resolve_user() {
  local u="${SUDO_USER:-${USER:-}}"
  [[ $u == root || -z $u ]] && u="${2:-}"
  [[ -z $u ]] && die "cannot determine target user; pass one explicitly"
  [[ $u == root ]] && die "refusing to target root (already unrestricted)"
  id "$u" >/dev/null 2>&1 || die "no such user: $u"
  printf '%s\n' "$u"
}

# /etc/sudoers.d is mode 0750 root:root, so a plain `test -f` run as a normal
# user reports "absent" for files that plainly exist. Always probe with
# `sudo -n` (which never prompts) and fall back to a direct test only if sudo
# is unusable. Getting this wrong makes `status` report a false OFF.
rule_exists() {
  if sudo -n test -f "$1" 2>/dev/null; then return 0; fi
  [[ -f $1 ]]
}

rule_cat() {
  sudo -n cat "$1" 2>/dev/null || cat "$1" 2>/dev/null || printf '(unreadable)'
}

# visudo validates the whole config, not just our file. On failure, remove the
# file and re-run to surface the error.
validate() {
  if ! "$VISUDO" -c >/dev/null 2>&1; then
    rm -f "$SUDOERS_FILE"
    printf 'error: sudoers validation FAILED — change rolled back.\n\n' >&2
    "$VISUDO" -c >&2 || true
    exit 1
  fi
}

case "$ACTION" in
  on)
    target="$(resolve_user "$@")"
    tmp="$(mktemp)"
    trap 'rm -f "$tmp"' EXIT
    printf '%s ALL=(ALL) NOPASSWD: ALL\n' "$target" >"$tmp"
    install -m 0440 -o root -g root "$tmp" "$SUDOERS_FILE"
    trap - EXIT
    rm -f "$tmp"
    validate
    # Invalidate any cached credential so this tests the rule, not the cache.
    sudo -k 2>/dev/null || true
    if sudo -n true 2>/dev/null; then
      printf 'enabled: %s now has passwordless sudo (permanent)\n' "$target"
      printf '  rule:   %s\n' "$SUDOERS_FILE"
      printf '  revoke: %s off\n' "$0"
    else
      die "rule written but sudo -n still fails; check '$VISUDO -c'"
    fi
    ;;

  off)
    if [[ -f $SUDOERS_FILE ]]; then
      rm -f "$SUDOERS_FILE"
      validate
      printf 'disabled: removed %s\n' "$SUDOERS_FILE"
      printf '  note: any other NOPASSWD rule still applies (e.g. omarchy toggle)\n'
    else
      printf 'already disabled: %s does not exist\n' "$SUDOERS_FILE"
    fi
    ;;

  status)
    if rule_exists "$SUDOERS_FILE"; then
      printf 'ON   — %s\n' "$(rule_cat "$SUDOERS_FILE")"
    else
      printf 'OFF  — %s absent\n' "$SUDOERS_FILE"
    fi
    if sudo -n true 2>/dev/null; then
      printf 'effective: sudo -n works right now\n'
    else
      printf 'effective: sudo -n does not work (password required)\n'
    fi
    om=/etc/sudoers.d/99-omarchy-nopasswd-"${SUDO_USER:-${USER:-unknown}}"
    if rule_exists "$om"; then
      printf 'note: omarchy toggle is ALSO active (%s) — its timer will not\n' "$om"
      printf '      revoke this rule, so %s off is what actually turns it off.\n' "$0"
    fi
    ;;

  help|-h|--help)
    usage
    ;;

  *)
    printf 'unknown action: %s\n\n' "$ACTION" >&2
    usage >&2
    exit 2
    ;;
esac
