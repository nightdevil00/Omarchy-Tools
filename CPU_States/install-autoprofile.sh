#!/usr/bin/env bash
# Installer for the autoprofile daemon (Lenovo DYTC platform-profile auto-switcher)
# Requires root. Idempotent - safe to re-run.

set -euo pipefail

BIN=/usr/local/sbin/autoprofile.sh
UNIT=/etc/systemd/system/autoprofile.service

if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run as root (sudo $0)" >&2
    exit 1
fi

if [ ! -w /sys/firmware/acpi/platform_profile ]; then
    echo "WARNING: /sys/firmware/acpi/platform_profile not writable." >&2
    echo "DYTC profiles (Fn+Q) are not supported here or ideapad_laptop.allow_v4_dytc=Y is missing from the kernel cmdline." >&2
fi

install -d /usr/local/sbin
cat > "$BIN" <<'EOF'
#!/usr/bin/env bash
# autoprofile - auto-switch Lenovo DYTC platform_profile by CPU temp & load
# Profiles: low-power | balanced | performance

PROFILE=/sys/firmware/acpi/platform_profile
TEMP_FILE=/sys/class/hwmon/hwmon6/temp1_input     # coretemp "Package id 0"
INTERVAL=5

# Hysteresis thresholds
UP_TEMP=80          # balanced -> performance
UP_LOAD=85
DN_TEMP=55          # performance -> balanced (temp fallback)
DN_LOAD=40
LO_TEMP=50          # balanced -> low-power
LO_LOAD=25
UP_TEMP4=60         # low-power -> balanced
UP_LOAD4=50

get_temp() {
    [ -r "$TEMP_FILE" ] || return 1
    local t; t=$(cat "$TEMP_FILE" 2>/dev/null)
    echo $((t / 1000))
}

get_load() {
    local n; n=$(nproc)
    awk -v n="$n" '{print int($1*100/n)}' /proc/loadavg 2>/dev/null
}

[ -w "$PROFILE" ] || { echo "autoprofile: $PROFILE not writable" >&2; exit 1; }

current=$(cat $PROFILE 2>/dev/null)
echo "autoprofile: starting from profile=$current" >&2

while :; do
    temp=$(get_temp)
    load=$(get_load)
    cur=$(cat $PROFILE 2>/dev/null)

    case "$cur" in
        performance)
            if { [ -n "$load" ] && [ "$load" -lt "$DN_LOAD" ]; } || { [ -n "$temp" ] && [ "$temp" -lt "$DN_TEMP" ]; }; then
                echo balanced > "$PROFILE"
                echo "autoprofile: performance -> balanced (temp=${temp}C load=${load}%)" >&2
            fi ;;
        low-power)
            if { [ -n "$temp" ] && [ "$temp" -gt "$UP_TEMP4" ]; } || { [ -n "$load" ] && [ "$load" -gt "$UP_LOAD4" ]; }; then
                echo balanced > "$PROFILE"
                echo "autoprofile: low-power -> balanced (temp=${temp}C load=${load}%)" >&2
            fi ;;
        *)
            if { [ -n "$temp" ] && [ "$temp" -gt "$UP_TEMP" ]; } || { [ -n "$load" ] && [ "$load" -gt "$UP_LOAD" ]; }; then
                echo performance > "$PROFILE"
                echo "autoprofile: balanced -> performance (temp=${temp}C load=${load}%)" >&2
            elif { [ -n "$temp" ] && [ "$temp" -lt "$LO_TEMP" ]; } && { [ -n "$load" ] && [ "$load" -lt "$LO_LOAD" ]; }; then
                echo low-power > "$PROFILE"
                echo "autoprofile: balanced -> low-power (temp=${temp}C load=${load}%)" >&2
            fi ;;
    esac

    sleep "$INTERVAL"
done
EOF
chmod 755 "$BIN"

cat > "$UNIT" <<'EOF'
[Unit]
Description=Auto-switch Lenovo DYTC platform profile by CPU temp/load
After=multi-user.target

[Service]
Type=simple
ExecStart=/usr/local/sbin/autoprofile.sh
Restart=always
RestartSec=10
Nice=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now autoprofile >/dev/null 2>&1 || true

echo "Installed $BIN and $UNIT"
systemctl is-active autoprofile
echo "Profile: $(cat /sys/firmware/acpi/platform_profile 2>/dev/null || echo n/a)"
echo "Logs: journalctl -u autoprofile -f"