#!/bin/bash
# ─────────────────────────────────────────────────────────────
# Claude Desktop Switcher — Installer
# ─────────────────────────────────────────────────────────────

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="$HOME/.local/bin"
APP_DIR="$HOME/.local/share/applications"
ICON_NAME="claude-desktop"

echo "Installing Claude Desktop Switcher..."

# ── Check dependencies ────────────────────────────────────────
if ! command -v zenity &> /dev/null; then
    echo "Installing zenity..."
    if command -v dnf &> /dev/null; then
        sudo dnf install -y zenity
    elif command -v apt &> /dev/null; then
        sudo apt install -y zenity
    elif command -v pacman &> /dev/null; then
        sudo pacman -S --noconfirm zenity
    else
        echo "ERROR: Could not install zenity. Please install it manually."
        exit 1
    fi
fi

if ! command -v claude-desktop &> /dev/null; then
    echo "WARNING: claude-desktop not found in PATH."
    echo "Install it from: https://github.com/aaddrick/claude-desktop-debian"
fi

# ── Install script ────────────────────────────────────────────
mkdir -p "$BIN_DIR"
cp "$SCRIPT_DIR/claude-switcher.sh" "$BIN_DIR/claude-switcher.sh"
chmod +x "$BIN_DIR/claude-switcher.sh"
echo "✓ Script installed to $BIN_DIR/claude-switcher.sh"

# ── Install .desktop entry ────────────────────────────────────
mkdir -p "$APP_DIR"
cat > "$APP_DIR/claude-switcher.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Claude Switcher
Comment=Switch between Claude Desktop accounts
Exec=bash $BIN_DIR/claude-switcher.sh
Icon=$ICON_NAME
Terminal=false
Categories=Utility;
Keywords=claude;account;switch;
StartupNotify=false
EOF

update-desktop-database "$APP_DIR" 2>/dev/null || true
echo "✓ App launcher entry installed"

# ── Ensure ~/.local/bin is in PATH ────────────────────────────
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    echo ""
    echo "NOTE: $HOME/.local/bin is not in your PATH."
    echo "Add this to your ~/.bashrc or ~/.zshrc:"
    echo '  export PATH="$HOME/.local/bin:$PATH"'
fi

echo ""
echo "✅ Installation complete!"
echo ""
echo "Run it:"
echo "  bash ~/.local/bin/claude-switcher.sh"
echo "  — or search 'Claude Switcher' in your app launcher (Super key)"
echo ""
echo "First time: open the switcher → Add new account → log in."
