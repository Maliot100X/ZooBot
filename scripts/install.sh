#!/usr/bin/env bash
# ZooBot CLI Installation Script
set -e

INSTALL_HOME="${ZOOBOT_HOME:-$HOME/.zoobot}"

# If piped (no BASH_SOURCE), clone and re-exec
if [ -z "${BASH_SOURCE[0]}" ] || [ "${BASH_SOURCE[0]}" = "bash" ]; then
    INSTALL_TMPDIR="$(mktemp -d)"
    echo "Cloning ZooBot..."
    git clone --depth 1 https://github.com/Maliot100X/ZooBot.git "$INSTALL_TMPDIR/zoobot"
    exec bash "$INSTALL_TMPDIR/zoobot/scripts/install.sh"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}ZooBot CLI Installer${NC}"
echo "====================="
echo ""

# Already installed?
if [ -d "$INSTALL_HOME" ]; then
    echo -e "${GREEN}✓ ZooBot already installed at $INSTALL_HOME${NC}"
    exit 0
fi

echo -e "Installing to: ${GREEN}$INSTALL_HOME${NC}"
mkdir -p "$INSTALL_HOME"

# Copy project
cp -a "$PROJECT_ROOT/." "$INSTALL_HOME/"

# Create self-locating wrapper
WRAPPER="$INSTALL_HOME/bin/zoobot"
cat > "$WRAPPER" << 'WRAPPER_EOF'
#!/usr/bin/env bash
SOURCE="${BASH_SOURCE[0]}"
while [ -L "$SOURCE" ]; do
    DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
    SOURCE="$(readlink "$SOURCE")"
    [ "${SOURCE#/}" = "$SOURCE" ] && SOURCE="$DIR/$SOURCE"
done
DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
INSTALL_HOME="$(cd "$DIR/.." && pwd)"
export ZOOBOT_HOME="${INSTALL_HOME}"
exec node "$INSTALL_HOME/packages/cli/bin/zoobot.mjs" "$@"
WRAPPER_EOF
chmod +x "$WRAPPER"

# Symlink
for dir in /usr/local/bin "$HOME/.local/bin" "$HOME/bin"; do
    if [ -w "$dir" ] 2>/dev/null; then
        rm -f "$dir/zoobot"
        ln -s "$WRAPPER" "$dir/zoobot"
        echo -e "${GREEN}✓${NC} Symlinked: $dir/zoobot"
        break
    fi
done

# Rebuild native modules
if command -v npm &> /dev/null; then
    echo "Rebuilding native modules..."
    cd "$INSTALL_HOME" && npm rebuild better-sqlite3 --silent 2>/dev/null || true
fi

echo ""
echo -e "${GREEN}✓ ZooBot CLI installed successfully!${NC}"
echo ""
echo "Run 'zoobot --help' to get started."
