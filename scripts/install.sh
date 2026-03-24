#!/usr/bin/env bash
# ZooBot CLI Installer
# Supports custom HOME via HOME=/path/to/home bash install.sh

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default install home
DEFAULT_HOME="${HOME:-/root}"
INSTALL_HOME="${ZOOBOT_HOME:-$DEFAULT_HOME/.zoobot}"

echo -e "${BLUE}ZooBot CLI Installer${NC}"
echo "====================="
echo ""

# Check if already installed
if [ -d "$INSTALL_HOME" ] && [ -f "$INSTALL_HOME/packages/cli/bin/zoobot.mjs" ]; then
    echo -e "${GREEN}✓ ZooBot already installed at $INSTALL_HOME${NC}"
    echo ""
    echo "Run '${GREEN}zoobot update${NC}' to update or '${GREEN}zoobot uninstall${NC}' to remove."
    exit 0
fi

echo -e "Installing to: ${GREEN}$INSTALL_HOME${NC}"

# Create install directory
mkdir -p "$INSTALL_HOME"

# Get the directory where THIS script lives (not the symlink)
SOURCE="${BASH_SOURCE[0]}"
while [ -L "$SOURCE" ]; do
    SOURCE="$(readlink "$SOURCE")"
    [ "${SOURCE#/}" = "$SOURCE" ] && SOURCE="$(dirname "$SOURCE")/$SOURCE"
done
SCRIPT_DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"

echo "Installing from: $SCRIPT_DIR"

# Check for npm
if ! command -v npm &> /dev/null; then
    echo -e "${RED}✗ npm not found. Please install Node.js 18+ first.${NC}"
    exit 1
fi

# Check node version
NODE_VERSION=$(node -v 2>/dev/null | sed 's/v//' | cut -d. -f1)
if [ -z "$NODE_VERSION" ] || [ "$NODE_VERSION" -lt 18 ]; then
    echo -e "${RED}✗ Node.js 18+ required. Current version: $(node -v 2>/dev/null || echo 'none')${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Node.js $(node -v)${NC}"

# Install tmux if needed
if ! command -v tmux &> /dev/null; then
    echo -e "${YELLOW}→ Installing tmux...${NC}"
    if command -v apt-get &> /dev/null; then
        apt-get update -qq && apt-get install -y -qq tmux 2>/dev/null || apt-get install -y tmux
    elif command -v brew &> /dev/null; then
        brew install tmux 2>/dev/null || brew install tmux
    else
        echo -e "${RED}✗ Cannot install tmux automatically. Please install it manually.${NC}"
        exit 1
    fi
fi
if command -v tmux &> /dev/null; then
    echo -e "${GREEN}✓ tmux $(tmux -V 2>/dev/null || echo 'installed')${NC}"
else
    echo -e "${RED}✗ tmux installation failed${NC}"
    exit 1
fi

# Copy files (exclude .git, node_modules, .next, huge dirs)
echo -e "${YELLOW}→ Copying ZooBot files...${NC}"
rsync -av --exclude='.git' --exclude='node_modules' --exclude='.next' --exclude='*.log' --exclude='Trash' "$SCRIPT_DIR/../" "$INSTALL_HOME/" 2>/dev/null || {
    echo -e "${YELLOW}→ rsync not available, using cp...${NC}"
    mkdir -p "$INSTALL_HOME"
    shopt -s dotglob
    for item in "$SCRIPT_DIR/../"*; do
        basename="$(basename "$item")"
        case "$basename" in
            .git|node_modules|.next|Trash) continue ;;
        esac
        cp -r "$item" "$INSTALL_HOME/" 2>/dev/null || true
    done
    shopt -u dotglob
}

# Install npm dependencies if needed
if [ ! -d "$INSTALL_HOME/node_modules" ] && [ -f "$INSTALL_HOME/package.json" ]; then
    echo -e "${YELLOW}→ Installing dependencies...${NC}"
    cd "$INSTALL_HOME" && npm install --silent 2>&1 | tail -3
fi

# Create symlink in /usr/local/bin
echo -e "${YELLOW}→ Creating CLI symlink...${NC}"
if [ -w /usr/local/bin ]; then
    ln -sf "$INSTALL_HOME/scripts/zoobot-wrapper" /usr/local/bin/zoobot 2>/dev/null || true
    echo -e "${GREEN}✓ Symlinked to /usr/local/bin/zoobot${NC}"
elif [ -w "$HOME/bin" ]; then
    mkdir -p "$HOME/bin"
    ln -sf "$INSTALL_HOME/scripts/zoobot-wrapper" "$HOME/bin/zoobot"
    echo -e "${GREEN}✓ Symlinked to $HOME/bin/zoobot${NC}"
else
    # Make wrapper executable
    chmod +x "$INSTALL_HOME/scripts/zoobot-wrapper" 2>/dev/null || true
    echo -e "${YELLOW}⚠ Cannot create /usr/local/bin symlink. Add to PATH:${NC}"
    echo "   export PATH=\"\$PATH:$INSTALL_HOME/scripts\""
fi

echo ""
echo -e "${GREEN}✓ ZooBot installed successfully!${NC}"
echo ""
echo "Get started:"
echo "  ${GREEN}zoobot${NC}          # Start ZooBot and open ZooOffice"
echo "  ${GREEN}zoobot --help${NC}   # Show all commands"
echo "  ${GREEN}zoobot setup${NC}    # First-time configuration"