# Boot Time Optimizations

Everything done to speed up boot, with before/after numbers and how to revert.

## Baseline

First measurement, before any changes (`systemd-analyze`):

```
firmware       4.722s
loader (Limine) 15.183s
kernel         4.917s
userspace      4.214s
total          29.037s
```

## Changes

### 1. Masked three TPM2 systemd services

```bash
sudo systemctl mask systemd-tpm2-setup-early.service \
                    systemd-tpm2-setup.service \
                    systemd-pcrlogin@1000.service
```

What they do:

| Service | Purpose |
|---------|---------|
| `systemd-tpm2-setup-early.service` | Early TPM Storage Root Key (SRK) provisioning during boot |
| `systemd-tpm2-setup.service` | Ensures a TPM SRK exists; enables TPM sealing (LUKS-to-TPM, `systemd-creds`, measured boot) |
| `systemd-pcrlogin@1000.service` | Measures the UID 1000 user record into an NvPCR (only relevant for `systemd-homed`) |

Why it was safe to mask:

- No `/etc/crypttab` entries, no LUKS-to-TPM binding
- No systemd-homed home directories (`~/.identity` absent)
- Secure Boot disabled
- All three are `--graceful`, so they never error out when disabled

These services appeared on the critical path but ran in parallel, so their real
impact on total userspace boot time was modest (~0.34s on the critical path).

To revert:

```bash
sudo systemctl unmask systemd-tpm2-setup-early.service \
                      systemd-tpm2-setup.service \
                      systemd-pcrlogin@1000.service
```

### 2. Lowered Limine menu timeout

`/boot/limine.conf`: `timeout: 3` -> `timeout: 1`

Older kernels still reachable by pressing a key at the Limine menu. Applied with
`sed` (file is root-owned):

```bash
sudo sed -i 's/^timeout: 3$/timeout: 1/' /boot/limine.conf
```

This line is in the hand-written header of the file, so `limine-entry-tool` does
not overwrite it on kernel updates. Note: `timeout: 0` disables auto-boot, so 1
is the lowest safe value.

To revert: set it back to `3`.

### 3. Masked systemd-binfmt.service

```bash
sudo systemctl mask systemd-binfmt.service
```

`systemd-binfmt` was the last real blocker on the userspace critical path
(~950ms). It registers binary formats via `binfmt_misc`. This machine had dozens
of `qemu-*-static` interpreter configs registered at every boot.

Trade-off: foreign-arch binaries/containers (e.g. ARM) will no longer
auto-register via binfmt. The `qemu-user-static` packages are still installed, so
re-enabling it is one command:

```bash
sudo systemctl unmask systemd-binfmt.service
```

## Results

```
            baseline    after TPM  today (all changes)
firmware    4.722s      4.742s     4.762s
loader     15.183s     11.687s    10.993s
kernel      4.917s      4.901s     4.923s
userspace   4.214s      3.877s     3.006s
total      29.037s     25.208s    23.685s
```

- Userspace: 4.2s -> 3.0s (-29%)
- Total boot: 29.0s -> 23.7s (~5.3s faster)
- `graphical.target` reached after ~3.0s of userspace

## What blocked boot (current critical chain)

```
graphical.target
└─power-profiles-daemon     +39ms
└─plymouth-quit             +139ms
└─wpa_supplicant            +14ms
└─systemd-pcrphase-sysinit  +40ms
└─sysinit.target
  └─systemd-binfmt.service  +949ms  * was the last real blocker (now masked)
```

Remaining top userspace services (all kept, all functional):

- `NetworkManager.service` (~710ms) - networking
- `thermald.service` (~670ms) - thermal management
- `upower.service` (~430ms) - power/reporting
- Remaining TPM PCR measurement services (~600ms total) - part of measured boot

`systemd-binfmt` and `systemd-tpm2-setup*` were the only services large enough
to mask; everything else left is healthy but uncredited for boot speed.

## Still on the table

Remaining time is dominated by firmware + loader (~15.7s of 23.7s):

- Lenovo Insyde BIOS: enable Fast Boot, update firmware (FW update via
  `fwupd` / `omarchy update firmware`)
- The loader figure is EFI-driver/TPM-dependent and swings several seconds
  between boots at the same config - external to the OS

## Verification

After any config change: `hyprctl reload && hyprctl configerrors` (Hyprland
configs). Boot timing: `systemd-analyze`, `systemd-analyze blame`,
`systemd-analyze critical-chain`.