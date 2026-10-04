#!/bin/bash
# Standalone uninstaller
# Usage: curl -sSL https://.../uninstall.sh | bash

set -euo pipefail

INSTALL_DIR="$HOME/.local/share/omarchy-flatpak-menu"

if [[ -f "$INSTALL_DIR/uninstall.sh" ]]; then
    exec "$INSTALL_DIR/uninstall.sh"
else
    echo "❌ Not installed or already removed"
    exit 1
fi