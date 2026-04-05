#!/bin/bash
# Restart cockpit with fresh DB
pkill -f 'node cockpit/server' || true
sleep 1
rm -f /opt/kvm-space/cockpit/server/data/cockpit.db
cd /opt/kvm-space
nohup /usr/local/node-v14.21.3-linux-arm64/bin/node cockpit/server/src/app.js > /tmp/cockpit.log 2>&1 &
sleep 2
echo "Cockpit PID: $(pgrep -f 'node cockpit/server')"
curl -s http://localhost:9091/api/info
echo ""
echo "--- Startup log ---"
tail -5 /tmp/cockpit.log
