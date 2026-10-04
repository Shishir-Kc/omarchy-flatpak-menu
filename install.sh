#!/bin/bash
# omarchy-flatpak-menu installer
# Usage: curl -sSL https://.../install.sh | bash

set -euo pipefail

REPO_BASE="https://raw.githubusercontent.com/omarchy/omarchy-flatpak-menu/main"
INSTALL_DIR="$HOME/.local/share/omarchy-flatpak-menu"
BIN_DIR="$HOME/.local/bin"

echo "📦 Installing Omarchy Flatpak Menu..."

# 1. Create directories
mkdir -p "$INSTALL_DIR" "$BIN_DIR"

# 2. Download scripts
echo "📥 Downloading scripts..."
curl -fsSL "$REPO_BASE/bin/omarchy-ensure-flatpak" -o "$BIN_DIR/omarchy-ensure-flatpak"
curl -fsSL "$REPO_BASE/bin/omarchy-flatpak-install" -o "$BIN_DIR/omarchy-flatpak-install"
chmod +x "$BIN_DIR/omarchy-ensure-flatpak" "$BIN_DIR/omarchy-flatpak-install"

# 3. Ensure ~/.local/bin is in PATH
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo "⚠️  Add ~/.local/bin to PATH in your shell config"
fi

# 4. Append menu entries
echo "📝 Adding Flatpak menu to Omarchy..."
MENU_FILE="$HOME/.config/omarchy/extensions/omarchy-menu.jsonc"
mkdir -p "$(dirname "$MENU_FILE")"

# Backup existing
[[ -f "$MENU_FILE" ]] && cp "$MENU_FILE" "$MENU_FILE.bak.$(date +%s)"

# Append our entries (idempotent - removes old entries first)
append_menu_entries() {
    local menu_content=$(curl -fsSL "$REPO_BASE/menu/flatpak-menu.jsonc")

    # Remove any existing flatpak entries
    if [[ -f "$MENU_FILE" ]]; then
        # Create temp file without our entries
        awk '
            /^\s*"install\.flatpak/ { in_flatpak=1; next }
            in_flatpak && /^\s*}/ { in_flatpak=0; next }
            !in_flatpak { print }
        ' "$MENU_FILE" > "$MENU_FILE.tmp"
        mv "$MENU_FILE.tmp" "$MENU_FILE"
    fi

    # Append our entries before the closing brace
    if [[ -f "$MENU_FILE" ]]; then
        sed -i '$ d' "$MENU_FILE"  # Remove closing }
        echo "$menu_content" >> "$MENU_FILE"
        echo "}" >> "$MENU_FILE"
    else
        echo "$menu_content" > "$MENU_FILE"
    fi
}

append_menu_entries

# 5. Install hook for auto-refresh
echo "🔧 Installing post-update hook..."
mkdir -p "$HOME/.config/omarchy/hooks/post-update.d"
curl -fsSL "$REPO_BASE/hooks/post-update.d/99-flatpak-menu-refresh" -o "$HOME/.config/omarchy/hooks/post-update.d/99-flatpak-menu-refresh"
chmod +x "$HOME/.config/omarchy/hooks/post-update.d/99-flatpak-menu-refresh"

# 6. Create uninstaller
echo "📝 Creating uninstaller..."
cat > "$INSTALL_DIR/uninstall.sh" << 'UNINSTALL_EOF'
#!/bin/bash
# omarchy-flatpak-menu uninstaller

set -euo pipefail

echo "🗑️  Uninstalling Omarchy Flatpak Menu..."

# Remove bin scripts
rm -f "$HOME/.local/bin/omarchy-ensure-flatpak"
rm -f "$HOME/.local/bin/omarchy-flatpak-install"

# Remove menu entries
MENU_FILE="$HOME/.config/omarchy/extensions/omarchy-menu.jsonc"
if [[ -f "$MENU_FILE" ]]; then
    awk '
        /^\s*"install\.flatpak/ { in_flatpak=1; next }
        in_flatpak && /^\s*}/ { in_flatpak=0; next }
        !in_flatpak { print }
    ' "$MENU_FILE" > "$MENU_FILE.tmp"
    mv "$MENU_FILE.tmp" "$MENU_FILE"
fi

# Remove hook
rm -f "$HOME/.config/omarchy/hooks/post-update.d/99-flatpak-menu-refresh"

# Remove cache
rm -rf "$HOME/.cache/omarchy-flatpak-apps.tsv"

# Remove install dir
rm -rf "$HOME/.local/share/omarchy-flatpak-menu"

echo "✅ Uninstall complete. Restart Omarchy shell or run 'omarchy restart shell'"
UNINSTALL_EOF
chmod +x "$INSTALL_DIR/uninstall.sh"

echo ""
echo "✅ Installation complete!"
echo ""
echo "📋 Next steps:"
echo "   1. Restart Omarchy shell: omarchy restart shell"
echo "   2. Open menu (Super+Space) → Install → Flatpak Apps"
echo "   3. Try 'Search Flathub...' for fuzzy search"
echo ""
echo "🗑️  To uninstall: ~/.local/share/omarchy-flatpak-menu/uninstall.sh"