#!/bin/bash
# ZooOffice Standalone Start Script
cd "$(dirname "$0")"
PORT=${PORT:-3010} nohup node server.js > /tmp/zoooffice.log 2>&1 &
echo "ZooOffice started on port $PORT (PID: $!)"
