#!/bin/bash
cd /opt/kvm-space
rm -f cockpit/server/data/cockpit.db
/usr/local/node-v14.21.3-linux-arm64/bin/node cockpit/server/src/app.js &
CPID=$!
echo "Cockpit PID: $CPID"
sleep 3
if kill -0 $CPID 2>/dev/null; then
  echo "Process alive"
  curl -s http://localhost:9091/api/info
else
  echo "Process DEAD"
fi
