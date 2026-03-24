#!/usr/bin/env bash
# ZooBot CLI Installation Script
# Installs ZooBot to ~/.zoobot and creates global symlinks.
#
# Supports: curl -fsSL <url>/install.sh | bash
# When piped, downloads the release tarball, extracts it, and installs.

set -e

INSTALL_HOME="$HOME/.zoobot"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# If piped (no BASH_SOURCE path), download and extract first
if [ -z "${BASH_SOURCE[0]}" ] || [ "${BASH_SOURCE[0]}" = "bash" ]; then
    INSTALL_TMPDIR="$(mktemp -d)"
    TARBALL_URL="https://github.com/ZooBot/zoobot/releases/latest/download/zoobot-bundle.tar.gz"
    echo "Downloading ZooBot..."
    curl -fsSL "$TARBALL_URL" | tar -xz -C "$INSTALL_TMPDIR"
    exec bash "$INSTALL_TMPDIR/zoobot/scripts/install.sh"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo -e "${BLUE}ZooBot CLI Installer${NC}"
echo "====================="
echo ""

# Migrate from ~/.zoobot if needed
if [ -d "$HOME/.zoobot" ] && [ ! -d "$INSTALL_HOME" ]; then
    echo -e "Migrating ${YELLOW}~/.zoobot${NC} → ${GREEN}~/.zoobot${NC}"
    mv "$HOME/.zoobot" "$INSTALL_HOME"
    # Rename database files
    [ -f "$INSTALL_HOME/zoobot.db" ] && mv "$INSTALL_HOME/zoobot.db" "$INSTALL_HOME/zoobot.db"
    [ -f "$INSTALL_HOME/zoobot.db-wal" ] && mv "$INSTALL_HOME/zoobot.db-wal" "$INSTALL_HOME/zoobot.db-wal"
    [ -f "$INSTALL_HOME/zoobot.db-shm" ] && mv "$INSTALL_HOME/zoobot.db-shm" "$INSTALL_HOME/zoobot.db-shm"
    echo -e "  ${GREEN}✓${NC} Migrated from ~/.zoobot"
fi

# Copy project files to ~/.zoobot (permanent location)
if [ "$PROJECT_ROOT" != "$INSTALL_HOME" ]; then
    echo -e "Installing to: ${GREEN}~/.zoobot${NC}"
    mkdir -p "$INSTALL_HOME"
    # Copy everything from the extracted/source bundle
    cp -a "$PROJECT_ROOT/." "$INSTALL_HOME/"
    PROJECT_ROOT="$INSTALL_HOME"
    echo -e "  ${GREEN}✓${NC} Files installed to ~/.zoobot"
else
    echo -e "Updating in: ${GREEN}~/.zoobot${NC}"
fi

WRAPPER="$PROJECT_ROOT/bin/zoobot"

# Check if wrapper exists
if [ ! -f "$WRAPPER" ]; then
    echo -e "${RED}Error: Wrapper script not found at $WRAPPER${NC}"
    exit 1
fi

chmod +x "$WRAPPER"
chmod +x "$PROJECT_ROOT/bin/zoobot" 2>/dev/null || true
chmod +x "$PROJECT_ROOT/lib/zoobot.sh" 2>/dev/null || true

# Rebuild native modules for this platform (bundle was built on Linux)
if command -v npm &> /dev/null; then
    echo -e "Rebuilding native modules..."
    cd "$PROJECT_ROOT" && npm rebuild better-sqlite3 --silent 2>/dev/null || true
    echo -e "  ${GREEN}✓${NC} Native modules rebuilt"
fi

# Determine symlink directory
INSTALL_DIR=""

if [ -w "/usr/local/bin" ]; then
    INSTALL_DIR="/usr/local/bin"
    echo -e "Symlinks in: ${GREEN}/usr/local/bin${NC} (system-wide)"
elif [ -d "$HOME/.local/bin" ]; then
    INSTALL_DIR="$HOME/.local/bin"
    echo -e "Symlinks in: ${GREEN}~/.local/bin${NC} (user)"
else
    mkdir -p "$HOME/.local/bin"
    INSTALL_DIR="$HOME/.local/bin"
    echo -e "Symlinks in: ${GREEN}~/.local/bin${NC} (user, created)"
fi

# Install a symlink (removes existing if present)
install_symlink() {
    local name="$1"
    local target="$2"

    if [ -L "$INSTALL_DIR/$name" ]; then
        rm "$INSTALL_DIR/$name"
    elif [ -e "$INSTALL_DIR/$name" ]; then
        echo -e "${RED}Error: $INSTALL_DIR/$name exists but is not a symlink${NC}"
        echo "Please remove it manually and try again."
        return 1
    fi

    ln -s "$target" "$INSTALL_DIR/$name"
    echo -e "  ${GREEN}✓${NC} $name → $target"
}

echo ""
echo "Creating symlinks..."
install_symlink "zoobot" "$WRAPPER"
install_symlink "zoobot" "$WRAPPER"  # backward compat

echo ""
echo -e "${GREEN}✓ ZooBot CLI installed successfully!${NC}"
echo ""
echo "You can now run 'zoobot' from any directory:"
echo ""
echo -e "  ${GREEN}zoobot start${NC}     - Start ZooBot"
echo -e "  ${GREEN}zoobot status${NC}    - Check status"
echo -e "  ${GREEN}zoobot --help${NC}    - Show all commands"
echo ""

# Verify it works — if not in PATH, add it to the shell profile
if command -v zoobot &> /dev/null; then
    echo -e "${GREEN}✓ 'zoobot' command is available${NC}"
elif [ "$INSTALL_DIR" = "$HOME/.local/bin" ]; then
    SHELL_NAME="$(basename "$SHELL")"
    SHELL_PROFILE=""
    case "$SHELL_NAME" in
        zsh)  SHELL_PROFILE="$HOME/.zshrc" ;;
        bash)
            if [ -f "$HOME/.bash_profile" ]; then
                SHELL_PROFILE="$HOME/.bash_profile"
            else
                SHELL_PROFILE="$HOME/.bashrc"
            fi
            ;;
        *)    SHELL_PROFILE="$HOME/.profile" ;;
    esac

    PATH_LINE='export PATH="$HOME/.local/bin:$PATH"'

    if [ -n "$SHELL_PROFILE" ] && ! grep -qF '.local/bin' "$SHELL_PROFILE" 2>/dev/null; then
        echo "" >> "$SHELL_PROFILE"
        echo "# Added by ZooBot installer" >> "$SHELL_PROFILE"
        echo "$PATH_LINE" >> "$SHELL_PROFILE"
        echo -e "${GREEN}✓ Added ~/.local/bin to PATH in ${SHELL_PROFILE/#$HOME/\~}${NC}"
    fi

    export PATH="$HOME/.local/bin:$PATH"
    echo -e "${YELLOW}⚠ Restart your terminal or run:  source ${SHELL_PROFILE/#$HOME/\~}${NC}"
else
    echo -e "${YELLOW}⚠ 'zoobot' command not found in PATH${NC}"
    echo "  Add $INSTALL_DIR to your PATH."
fi

echo ""
echo "To uninstall: rm -rf ~/.zoobot && rm $INSTALL_DIR/zoobot $INSTALL_DIR/zoobot"
echo ""
