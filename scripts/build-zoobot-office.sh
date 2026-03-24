#!/bin/bash
# ZooOffice Build Script - Creates standalone production build
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/zoobot-office"

echo "Building ZooOffice..."
npm run build

echo "Creating standalone package..."
cd ..
rm -rf zoobot-office-standalone
mkdir -p zoobot-office-standalone

# Copy standalone server files
cp -r zoobot-office/.next/standalone/zoobot-office/. zoobot-office-standalone/

# Copy static files
mkdir -p zoobot-office-standalone/.next
cp -r zoobot-office/.next/static zoobot-office-standalone/.next/
cp zoobot-office/.next/BUILD_ID zoobot-office-standalone/.next/

# Create start script
cat > zoobot-office-standalone/start.sh << 'SCRIPT'
#!/bin/bash
cd "$(dirname "$0")"
PORT=${PORT:-3010} nohup node server.js > /tmp/zoooffice.log 2>&1 &
echo "ZooOffice started on port $PORT (PID: $!)"
SCRIPT
chmod +x zoobot-office-standalone/start.sh

echo "Done! To run ZooOffice:"
echo "  cd zoobot-office-standalone"
echo "  ./start.sh"
echo "  Then visit http://localhost:3010"
