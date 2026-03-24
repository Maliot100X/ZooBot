#!/usr/bin/env bash
# ZooBot Installer - Clean curl+tar, no rsync
set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
INSTALL_HOME="${ZOOBOT_HOME:-$HOME/.zoobot}"
TARBALL_URL="https://github.com/Maliot100X/ZooBot/archive/refs/heads/main.tar.gz"
TARBALL_TMP="/tmp/zoobot-$$.tar.gz"

echo -e "${BLUE}ZooBot CLI Installer${NC}"
echo "====================="
echo -e "Installing to: ${GREEN}$INSTALL_HOME${NC}"

# Check Node.js
! command -v node &>/dev/null && echo -e "${RED}✗ Node.js not found${NC}" && exit 1
echo -e "${GREEN}✓ Node.js $(node --version)${NC}"

# Check tmux
! command -v tmux &>/dev/null && echo -e "${RED}✗ tmux not found${NC}" && exit 1
echo -e "${GREEN}✓ tmux $(tmux -V)${NC}"

# Download and extract
echo -e "${YELLOW}→ Downloading ZooBot...${NC}"
curl -fsSL "$TARBALL_URL" -o "$TARBALL_TMP"

echo -e "${YELLOW}→ Extracting...${NC}"
mkdir -p "$INSTALL_HOME"
tar -xzf "$TARBALL_TMP" -C "$INSTALL_HOME" --strip-components=1
rm -f "$TARBALL_TMP"

# Install dependencies and build
if [ -f "$INSTALL_HOME/package.json" ]; then
    echo -e "${YELLOW}→ Installing dependencies...${NC}"
    cd "$INSTALL_HOME" && npm install 2>/dev/null | tail -3
    
    echo -e "${YELLOW}→ Building...${NC}"
    npm run build 2>/dev/null || npx tsc --build
fi

# Create bin wrapper
mkdir -p "$INSTALL_HOME/bin"
cat > "$INSTALL_HOME/bin/zoobot" << 'WRAPPER'
#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec node "$SCRIPT_DIR/packages/cli/bin/zoobot.mjs" "$@"
WRAPPER
chmod +x "$INSTALL_HOME/bin/zoobot"

# Link to PATH
for bin_dir in /usr/local/bin "$HOME/bin"; do
    if [ -d "$bin_dir" ] && [ -w "$bin_dir" ]; then
        ln -sf "$INSTALL_HOME/bin/zoobot" "$bin_dir/zoobot" 2>/dev/null && break
    fi
done

# Create daemon script
mkdir -p "$INSTALL_HOME/scripts"
cat > "$INSTALL_HOME/scripts/zoobot-daemon.sh" << 'DAEMON'
#!/usr/bin/env bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export ZOOBOT_HOME="$(dirname "$SCRIPT_DIR")"
exec node "$ZOOBOT_HOME/packages/cli/bin/zoobot.mjs" start "$@"
DAEMON
chmod +x "$INSTALL_HOME/scripts/zoobot-daemon.sh"

echo -e "${GREEN}✓ ZooBot installed to $INSTALL_HOME${NC}"
echo ""
echo "Run 'zoobot --help' to get started!"