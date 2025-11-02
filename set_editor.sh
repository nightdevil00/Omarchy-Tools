#!/usr/bin/env bash
# Sets a chosen default editor for all text/code MIME types
# and syncs $EDITOR and $VISUAL environment variables.
# Works perfectly with Hyprland (detects your terminal).

set -e

# ─────────────────────────────────────────────
# Detect terminal emulator
# ─────────────────────────────────────────────
TERMINALS=("kitty" "alacritty" "wezterm" "foot" "gnome-terminal" "konsole" "xfce4-terminal" "xterm")
for t in "${TERMINALS[@]}"; do
    if command -v "$t" &>/dev/null; then
        TERMINAL="$t"
        break
    fi
done
TERMINAL=${TERMINAL:-xterm}

echo "🖥️  Using terminal emulator: $TERMINAL"

# ─────────────────────────────────────────────
# Known editors
# ─────────────────────────────────────────────
KNOWN_EDITORS=(
    "nvim"
    "vim"
    "nano"
    "gedit"
    "kate"
    "code"
    "mousepad"
    "xed"
    "leafpad"
    "geany"
)

# ─────────────────────────────────────────────
# Common text/code MIME types
# ─────────────────────────────────────────────
MIME_TYPES=(
    "text/plain"
    "text/x-csrc"
    "text/x-chdr"
    "text/x-c++src"
    "text/x-c++hdr"
    "text/x-python"
    "text/x-shellscript"
    "text/x-java"
    "text/x-php"
    "text/x-go"
    "text/x-ruby"
    "text/x-perl"
    "text/x-sql"
    "text/x-markdown"
    "application/json"
    "application/xml"
    "application/x-yaml"
    "application/javascript"
)

# ─────────────────────────────────────────────
# Detect installed editors and create .desktop for terminal editors
# ─────────────────────────────────────────────
echo "🔍 Detecting available editors..."
EDITORS=()

for e in "${KNOWN_EDITORS[@]}"; do
    if [ -f "/usr/share/applications/${e}.desktop" ]; then
        echo "✅ Found GUI editor: $e"
        EDITORS+=("${e}.desktop")
    elif command -v "$e" &>/dev/null; then
        echo "✅ Found terminal editor: $e — creating .desktop entry..."
        DESKTOP_FILE="$HOME/.local/share/applications/${e}.desktop"
        mkdir -p "$(dirname "$DESKTOP_FILE")"
        cat >"$DESKTOP_FILE" <<EOF
[Desktop Entry]
Name=${e^}
Exec=${TERMINAL} -e $e %F
Type=Application
Terminal=false
MimeType=text/plain;
NoDisplay=false
Categories=Utility;TextEditor;
EOF
        EDITORS+=("${e}.desktop")
    fi
done

if [ ${#EDITORS[@]} -eq 0 ]; then
    echo "❌ No editors found! Try installing one, e.g. 'sudo pacman -S nano gedit code'."
    exit 1
fi

# ─────────────────────────────────────────────
# Prompt user
# ─────────────────────────────────────────────
echo ""
echo "📝 Available editors:"
select CHOICE in "${EDITORS[@]}"; do
    if [ -n "$CHOICE" ]; then
        EDITOR_DESKTOP="$CHOICE"
        EDITOR_NAME="${CHOICE%.desktop}"
        break
    else
        echo "Invalid choice, try again."
    fi
done

# ─────────────────────────────────────────────
# Set defaults via xdg-mime
# ─────────────────────────────────────────────
echo ""
echo "⚙️  Setting $EDITOR_DESKTOP as default for text/code MIME types..."
for MIME in "${MIME_TYPES[@]}"; do
    xdg-mime default "$EDITOR_DESKTOP" "$MIME"
done

update-desktop-database ~/.local/share/applications/ >/dev/null 2>&1 || true

# ─────────────────────────────────────────────
# Sync environment variables ($EDITOR and $VISUAL)
# ─────────────────────────────────────────────
echo ""
echo "🔧 Updating environment variables..."

PROFILE_FILES=("$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile" "$HOME/.bash_profile")
for f in "${PROFILE_FILES[@]}"; do
    if [ -f "$f" ]; then
        # Remove old EDITOR/VISUAL lines
        sed -i '/export EDITOR=/d' "$f"
        sed -i '/export VISUAL=/d' "$f"
        # Add new ones
        echo "export EDITOR=$EDITOR_NAME" >>"$f"
        echo "export VISUAL=$EDITOR_NAME" >>"$f"
    fi
done

echo ""
echo "✅ Default editor set to: $EDITOR_DESKTOP"
echo "✅ Environment variables updated: EDITOR=$EDITOR_NAME, VISUAL=$EDITOR_NAME"
echo ""
echo "🔎 Verify MIME default:"
echo "  xdg-mime query default text/plain"
echo ""
echo "💡 Reopen your terminal or source your shell config to apply:"
echo "  source ~/.bashrc  # or ~/.zshrc"

