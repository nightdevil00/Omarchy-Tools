#!/usr/bin/env bash
set -euo pipefail

MIMEAPPS="$HOME/.config/mimeapps.list"
LOCAL_APPS="$HOME/.local/share/applications"
GLOBS="/usr/share/mime/globs"

declare -A EDITORS=(
  [zed]="dev.zed.Zed.desktop"
  [code]="code.desktop"
)

editor=""
if [[ $# -ge 1 ]]; then
  editor="$1"
else
  printf 'Choose your text editor:\n'
  for name in "${!EDITORS[@]}"; do
    printf '  %s) %s\n' "$name" "${EDITORS[$name]}"
  done
  read -rp '> ' editor
fi

desktop="${EDITORS[$editor]:-}"
if [[ -z "$desktop" ]]; then
  echo "Unknown editor: $editor. Use: ${!EDITORS[*]}" >&2
  exit 1
fi

mkdir -p "$LOCAL_APPS"

mapfile -t text_mimes < <(
  awk -F: '/^text\// {print $1}' "$GLOBS" | sort -u
)

text_mimes+=(
  application/toml
  application/yaml
  application/json
  application/json5
  application/x-zerosize
)

all_mimes=$(printf '%s\n' "${text_mimes[@]}" | sort -u)

echo "Binding $(printf '%s\n' "${text_mimes[@]}" | wc -l) text/config MIME types to $editor"
echo "Includes: .txt .md .sh .lua .conf .toml .yaml .json .xml .py .rs .c ..."

tmp=$(mktemp)

mime_section=0
{
  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" == "[Default Applications]" ]]; then
      mime_section=1
      continue
    fi
    if [[ "$line" =~ ^\[ ]] && [[ "$mime_section" == 1 ]]; then
      mime_section=0
    fi
    if [[ "$mime_section" == 1 ]] && [[ "$line" =~ ^text/ || "$line" =~ ^application/(toml|yaml|json|json5|x-zerosize)= ]]; then
      continue
    fi
    [[ -n "$line" ]] && printf '%s\n' "$line"
  done < <(sed 's/\r$//' "$MIMEAPPS" 2>/dev/null || true)
} > "$tmp"

printf '\n[Default Applications]\n' >> "$tmp"
{
  while IFS= read -r m; do
    printf '%s=%s\n' "$m" "$desktop"
  done <<< "$all_mimes"
} >> "$tmp"

mv "$tmp" "$MIMEAPPS"

desktop_mime=$(printf '%s;' "${text_mimes[@]}" | sort | uniq)
cat > "$LOCAL_APPS/$desktop" <<EOF
[Desktop Entry]
Type=Application
Name=$(grep -m1 '^Name=' "/usr/share/applications/$desktop" | cut -d= -f2)
Comment=$(grep -m1 '^Comment=' "/usr/share/applications/$desktop" | cut -d= -f2)
Exec=$(grep -m1 '^Exec=' "/usr/share/applications/$desktop" | cut -d= -f2)
Icon=$(grep -m1 '^Icon=' "/usr/share/applications/$desktop" | cut -d= -f2)
Terminal=false
Categories=$(grep -m1 '^Categories=' "/usr/share/applications/$desktop" | cut -d= -f2)
MimeType=$desktop_mime
EOF

update-desktop-database "$LOCAL_APPS" 2>/dev/null || true

echo "Done. Files updated:"
echo "  $MIMEAPPS"
echo "  $LOCAL_APPS/$desktop"
echo "Rebuild your file manager's MIME cache or run: update-desktop-database"
