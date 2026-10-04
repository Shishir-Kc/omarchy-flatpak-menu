#!/bin/bash
# omarchy-flatpak-menu local installer
# Usage: ./install-local.sh (run from the project directory)

set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="$HOME/.local/share/omarchy-flatpak-menu"
BIN_DIR="$HOME/.local/bin"

echo "[INSTALL] Installing Omarchy Flatpak Menu (local)..."

# 0. Install Flatpak and add Flathub remote (auto)
echo "[FLATPAK] Setting up Flatpak..."
if ! command -v flatpak >/dev/null 2>&1; then
    echo "[FLATPAK] Flatpak not found. Installing..."
    FLATPAK_INSTALLED=0
    if command -v omarchy-pkg-add >/dev/null 2>&1; then
        if omarchy-pkg-add flatpak; then
            FLATPAK_INSTALLED=1
            echo "[FLATPAK] Flatpak installed successfully"
        fi
    elif [ -t 0 ] || [ -t 1 ] || [ -t 2 ]; then
        # We have a TTY, use sudo
        if sudo pacman -S --noconfirm --needed flatpak; then
            FLATPAK_INSTALLED=1
            echo "[FLATPAK] Flatpak installed successfully"
        fi
    elif command -v pkexec >/dev/null 2>&1; then
        # GUI environment, use pkexec
        if pkexec pacman -S --noconfirm --needed flatpak; then
            FLATPAK_INSTALLED=1
            echo "[FLATPAK] Flatpak installed successfully"
        fi
    fi

    if [[ $FLATPAK_INSTALLED -eq 0 ]]; then
        echo "[WARN] Could not auto-install Flatpak. Continuing with menu setup..."
        echo "[INFO] After install, run: sudo pacman -S flatpak"
        echo "[INFO] Then: flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo"
    fi
else
    echo "[FLATPAK] Flatpak already installed"
    FLATPAK_INSTALLED=1
fi

# Add Flathub remote if flatpak is available
if command -v flatpak >/dev/null 2>&1; then
    if ! flatpak remotes | grep -q "^flathub\s"; then
        echo "[FLATPAK] Adding Flathub remote..."
        flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    else
        echo "[FLATPAK] Flathub remote already configured"
    fi
    # Update appstream metadata (optional, for better search results)
    flatpak update --appstream 2>/dev/null || true
elif [[ "${FLATPAK_INSTALLED:-0}" -eq 0 ]]; then
    echo "[WARN] Skipping Flathub setup - Flatpak not installed yet"
fi

# 1. Create directories
mkdir -p "$INSTALL_DIR" "$BIN_DIR"

# 2. Copy scripts locally
echo "[COPY] Copying scripts..."
cp "$SCRIPT_DIR/bin/omarchy-ensure-flatpak" "$BIN_DIR/omarchy-ensure-flatpak"
cp "$SCRIPT_DIR/bin/omarchy-flatpak-install" "$BIN_DIR/omarchy-flatpak-install"
chmod +x "$BIN_DIR/omarchy-ensure-flatpak" "$BIN_DIR/omarchy-flatpak-install"

# 3. Ensure ~/.local/bin is in PATH
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo "[WARN] Add ~/.local/bin to PATH in your shell config"
fi

# 4. Append menu entries (idempotent, robust)
echo "[CONFIG] Adding Flatpak menu to Omarchy..."
MENU_FILE="$HOME/.config/omarchy/extensions/omarchy-menu.jsonc"
mkdir -p "$(dirname "$MENU_FILE")"

append_menu_entries() {
    local menu_jsonc="$SCRIPT_DIR/menu/flatpak-menu.jsonc"
    local tmp="/tmp/flatpak-menu-entries.jsonc"

    # Strip outer braces and comments to get just the key/value entries
    python3 -c "
import json, re, sys
with open('$menu_jsonc') as f:
    content = f.read()
# Find first {
start = content.index('{')
content = content[start:]
# Remove // comments
lines = []
for line in content.split('\n'):
    if line.strip().startswith('//'): continue
    if '//' in line and '://' not in line:
        idx = line.index('//')
        if line[:idx].count('\"') % 2 == 0:
            line = line[:idx]
    lines.append(line)
content = '\n'.join(lines)
# Remove trailing commas
content = re.sub(r',(\s*[}\]])', r'\1', content)
# Parse to validate
data = json.loads(content)
# Write only the inner entries (skip outer {})
with open('$tmp', 'w') as out:
    out.write(content[1:-1].strip())
" || { echo "[ERROR] Failed to parse flatpak-menu.jsonc" >&2; exit 1; }

    # Backup
    [[ -f "$MENU_FILE" ]] && cp "$MENU_FILE" "$MENU_FILE.bak.$(date +%s)"

    # If menu doesn't exist, create with template header + entries
    if [[ ! -f "$MENU_FILE" ]]; then
        cat > "$MENU_FILE" << 'EOF'
{
  // Extend the Quickshell Omarchy menu with JSONC.
  //
  // IDs are object keys. The parent is inferred from the dotted id, so
  // "personal.notes" appears under "personal", and "personal" appears on the
  // root menu. Reuse an existing id to override/extend it.
  //
  // Fields:
  //   icon        Nerd Font glyph shown in the icon column.
  //   label       Visible row title.
  //   action      Shell command to run. If omitted, the row is a submenu.
  //   target      Existing submenu id to open. Use for links/aliases.
  //   provider    Runtime provider function/command returning JSON rows.
  //   aliases     alternate `omarchy menu summon <name>` routes; also searchable.
  //   description Optional subtitle and extra search text.
  //   when        Shell condition; hide row when it fails.
  //   checked     Shell condition; append ✓ when it succeeds.
  //
  // Examples:
  // "personal": {"icon":"","label":"Personal"},
  // "personal.notes": {"icon":"󰎞","label":"Notes","action":"omarchy-launch-editor ~/notes"},
  // "personal.files": {"icon":"","label":"Files","action":"uwsm-app -- nautilus ~/Documents"},
  //
  // Only use provider when a provider_name function or command named "name"
  // returns JSON rows. Static submenus only need dotted ids.
  //
  // Example: replace the default About action by reusing the same id. Existing
  // fields are kept unless overridden.
  // "about": {"icon":"","label":"About","action":"omarchy-launch-or-focus-tui \"zsh -c 'fastfetch; read -k 1'\""},
EOF
        cat "$tmp" >> "$MENU_FILE"
        echo "}" >> "$MENU_FILE"
        echo "[CONFIG] Created new menu file with Flatpak entries"
        return
    fi

    # If flatpak entries already present, skip (idempotent)
    if grep -q '"install\.flatpak"' "$MENU_FILE"; then
        echo "[CONFIG] Flatpak menu entries already present, skipping..."
        return
    fi

    # Remove final }, append entries, add }
    sed -i '$ d' "$MENU_FILE"
    cat "$tmp" >> "$MENU_FILE"
    echo "}" >> "$MENU_FILE"
    echo "[CONFIG] Appended Flatpak entries to existing menu"
}

append_menu_entries

# 5. Install hook for auto-refresh
echo "[HOOK] Installing post-update hook..."
mkdir -p "$HOME/.config/omarchy/hooks/post-update.d"
cp "$SCRIPT_DIR/hooks/post-update.d/99-flatpak-menu-refresh" "$HOME/.config/omarchy/hooks/post-update.d/99-flatpak-menu-refresh"
chmod +x "$HOME/.config/omarchy/hooks/post-update.d/99-flatpak-menu-refresh"

# 6. Install append script for hook to use
echo "[APPEND] Installing menu-append helper..."
mkdir -p "$BIN_DIR"
cat > "$BIN_DIR/omarchy-flatpak-menu-append" << 'EOF'
#!/bin/bash
# Called by post-update hook to re-apply Flatpak menu entries
set -euo pipefail
SCRIPT_DIR="$HOME/.local/share/omarchy-flatpak-menu"
export SCRIPT_DIR
exec "$SCRIPT_DIR/install-local.sh" --append-only 2>/dev/null
EOF
chmod +x "$BIN_DIR/omarchy-flatpak-menu-append"

# 7. Create uninstaller
echo "[UNINSTALL] Creating uninstaller..."
cat > "$INSTALL_DIR/uninstall.sh" << 'UNINSTALL_EOF'
#!/bin/bash
# omarchy-flatpak-menu uninstaller

set -euo pipefail

echo "[REMOVE] Uninstalling Omarchy Flatpak Menu..."

# Remove bin scripts
rm -f "$HOME/.local/bin/omarchy-ensure-flatpak"
rm -f "$HOME/.local/bin/omarchy-flatpak-install"
rm -f "$HOME/.local/bin/omarchy-flatpak-menu-append"

# Remove menu entries cleanly using Python (preserves JSONC structure)
MENU_FILE="$HOME/.config/omarchy/extensions/omarchy-menu.jsonc"
if [[ -f "$MENU_FILE" ]]; then
    python3 -c "
import json, re, sys
with open('$MENU_FILE') as f:
    content = f.read()
start = content.index('{')
header = content[:start]
jsonc = content[start:]
# Remove // comments for parsing
lines = []
for line in jsonc.split('\n'):
    if line.strip().startswith('//'): continue
    if '//' in line and '://' not in line:
        idx = line.index('//')
        if line[:idx].count('\"') % 2 == 0:
            line = line[:idx]
    lines.append(line)
jsonc = '\n'.join(lines)
jsonc = re.sub(r',(\s*[}\]])', r'\1', jsonc)
data = json.loads(jsonc)
# Delete flatpak keys
keys_to_del = [k for k in data if k.startswith('install.flatpak')]
for k in keys_to_del:
    del data[k]
# Rebuild: keep header, write remaining keys
out = header + '{\n'
items = list(data.items())
for i, (k, v) in enumerate(items):
    out += json.dumps({k: v})[1:-1]
    if i < len(items) - 1:
        out += ',\n'
    else:
        out += '\n'
out += '}'
with open('$MENU_FILE', 'w') as f:
    f.write(out)
print(f'Removed {len(keys_to_del)} flatpak entries')
"
fi

# Remove hook
rm -f "$HOME/.config/omarchy/hooks/post-update.d/99-flatpak-menu-refresh"

# Remove cache
rm -rf "$HOME/.cache/omarchy-flatpak-apps.tsv"

# Remove install dir
rm -rf "$HOME/.local/share/omarchy-flatpak-menu"

echo "[DONE] Uninstall complete. Restart Omarchy shell or run 'omarchy restart shell'"
UNINSTALL_EOF
chmod +x "$INSTALL_DIR/uninstall.sh"

echo ""
echo "[DONE] Installation complete!"
if [[ "${FLATPAK_INSTALLED:-0}" -eq 0 ]]; then
    echo ""
    echo "[ACTION REQUIRED] Flatpak was not installed automatically."
    echo "   Run: sudo pacman -S flatpak"
    echo "   Then: flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo"
    echo "   Then restart shell: omarchy restart shell"
fi
echo ""
echo "Next steps:"
echo "   1. Open menu (Super+Space) -> Install -> Flatpak Apps"
echo "   2. Try 'Search Flathub...' for fuzzy search"
echo ""
echo "To uninstall: ~/.local/share/omarchy-flatpak-menu/uninstall.sh"

# 8. Auto-restart Omarchy shell (optional, guarded)
if command -v omarchy >/dev/null 2>&1; then
    echo "[SHELL] Restarting Omarchy shell..."
    omarchy restart shell
else
    echo "[WARN] 'omarchy' not in PATH; restart shell manually: omarchy restart shell"
fi