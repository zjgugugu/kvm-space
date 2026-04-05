#!/bin/bash
NODE=/usr/local/node-v14.21.3-linux-arm64/bin/node
pkill -f 'node.*cockpit/server' 2>/dev/null
sleep 1
cd /opt/kvm-space
nohup $NODE cockpit/server/src/app.js > /tmp/cockpit.log 2>&1 &
sleep 3
curl -s -X POST http://localhost:9091/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"root","password":"root"}'
