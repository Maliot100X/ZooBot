#!/usr/bin/env bash
# ZooBot Installer v2 - Fixed symlink approach

set -e

NC='\033[0m'
BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'

INSTALL_HOME="${HOME:-/root}"
ZOOBOT_DIR="$INSTALL_HOME/.zoobot"

echo -e "${BOLD}========================================${NC}"
echo -e "${BOLD}   ZooBot Installer v2${NC}"
echo -e "${BOLD}========================================${NC}"
echo ""

# Detect install mode
if [ -d "/usr/local/bin" ] && [ -w "/usr/local/bin" ]; then
    BIN_DIR="/usr/local/bin"
else
    BIN_DIR="$ZOOBOT_DIR/bin"
    mkdir -p "$BIN_DIR"
fi

echo "Installing ZooBot CLI to: $BIN_DIR"

# Download ZooBot repo as tarball
TARBALL_URL="https://github.com/Maliot100X/ZooBot/archive/refs/heads/main.tar.gz"
TARBALL_TMP="/tmp/zoobot-install.tar.gz"

echo -e "${YELLOW}Downloading ZooBot...${NC}"
if curl -fsSL "$TARBALL_URL" -o "$TARBALL_TMP" 2>/dev/null; then
    echo -e "${GREEN}✓ Downloaded${NC}"
else
    echo -e "${RED}✗ Download failed${NC}"
    exit 1
fi

# Extract
echo -e "${YELLOW}Installing ZooBot files...${NC}"
rm -rf "$ZOOBOT_DIR"
mkdir -p "$(dirname "$ZOOBOT_DIR")"
if tar -xzf "$TARBALL_TMP" -C "$(dirname "$ZOOBOT_DIR")" 2>/dev/null; then
    # Handle both ZooBot-main and zoobot-main (capital/lowercase)
    EXTRACTED_DIR="$(dirname "$ZOOBOT_DIR")/$(ls "$(dirname "$ZOOBOT_DIR")" | grep -i 'ZooBot' | head -1)"
    if [ -d "$EXTRACTED_DIR" ]; then
        mv "$EXTRACTED_DIR" "$ZOOBOT_DIR"
    else
        echo -e "${RED}✗ Extracted directory not found${NC}"
        exit 1
    fi
    rm -f "$TARBALL_TMP"
    echo -e "${GREEN}✓ Installed to $ZOOBOT_DIR${NC}"
else
    echo -e "${RED}✗ Extraction failed${NC}"
    rm -f "$TARBALL_TMP"
    exit 1
fi

# Create wrapper script that directly calls the .mjs file
WRAPPER_PATH="$BIN_DIR/zoobot"
echo -e "${YELLOW}Creating CLI wrapper...${NC}"

cat > "$WRAPPER_PATH" << 'WRAPPER'
#!/usr/bin/env bash
exec node /root/.zoobot/packages/cli/bin/zoobot.mjs "$@"
WRAPPER

chmod +x "$WRAPPER_PATH"

# If installed to /usr/local/bin, also symlink for PATH
if [ "$BIN_DIR" = "/usr/local/bin" ]; then
    ln -sf "$ZOOBOT_DIR/bin/zoobot" "$BIN_DIR/zoobot" 2>/dev/null || true
fi

echo ""
echo -e "${GREEN}✓${NC} ZooBot CLI installed successfully!"
echo ""
echo -e "${BOLD}Usage:${NC}"
echo "  zoobot --help       Show all commands"
echo "  zoobot version      Show version"
echo "  zoobot install     Install (re-run to update)"
echo "  zoobot setup       Configure API keys"
echo "  zoobot start       Start daemon"
echo "  zoobot office      Open ZooOffice web portal"
echo ""
echo -e "${GREEN}Get started:${NC} zoobot --help"
