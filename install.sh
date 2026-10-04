#!/bin/bash
# omarchy-flatpak-menu installer
# Usage: curl -sSL https://.../install.sh | bash

set -euo pipefail

REPO_BASE="https://raw.githubusercontent.com/Shishir-Kc/omarchy-flatpak-menu/refs/heads/master"
INSTALL_DIR="$HOME/.local/share/omarchy-flatpak-menu"
BIN_DIR="$HOME/.local/bin"

echo "[INSTALL] Installing Omarchy Flatpak Menu..."

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

# 2. Download scripts
echo "[DOWNLOAD] Downloading scripts..."
curl -fsSL "$REPO_BASE/bin/omarchy-ensure-flatpak" -o "$BIN_DIR/omarchy-ensure-flatpak"
curl -fsSL "$REPO_BASE/bin/omarchy-flatpak-install" -o "$BIN_DIR/omarchy-flatpak-install"
chmod +x "$BIN_DIR/omarchy-ensure-flatpak" "$BIN_DIR/omarchy-flatpak-install"

# 3. Ensure ~/.local/bin is in PATH
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo "[WARN] Add ~/.local/bin to PATH in your shell config"
fi

# 4. Append menu entries
echo "[CONFIG] Adding Flatpak menu to Omarchy..."
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
echo "[HOOK] Installing post-update hook..."
mkdir -p "$HOME/.config/omarchy/hooks/post-update.d"
curl -fsSL "$REPO_BASE/hooks/post-update.d/99-flatpak-menu-refresh" -o "$HOME/.config/omarchy/hooks/post-update.d/99-flatpak-menu-refresh"
chmod +x "$HOME/.config/omarchy/hooks/post-update.d/99-flatpak-menu-refresh"

# 6. Create uninstaller
echo "[UNINSTALL] Creating uninstaller..."
cat > "$INSTALL_DIR/uninstall.sh" << 'UNINSTALL_EOF'
#!/bin/bash
# omarchy-flatpak-menu uninstaller

set -euo pipefail

echo "[REMOVE] Uninstalling Omarchy Flatpak Menu..."

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
echo "   1. Restart Omarchy shell: omarchy restart shell"
echo "   2. Open menu (Super+Space) -> Install -> Flatpak Apps"
echo " 3. Try 'Search Flathub...' for fuzzy search"
echo ""
echo "To uninstall: ~/.local/share/omarchy-flatpak-menu/uninstall.sh"