#!/bin/bash
# ZooOffice Hosting Package
# Run: node server.js

PORT=${PORT:-3000}
echo "Starting ZooOffice on port $PORT..."
cd "$(dirname "$0")"
node zoobot-office/server.js
