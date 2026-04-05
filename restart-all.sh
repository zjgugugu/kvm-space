#!/bin/bash
# Restart MC and Cockpit services
pkill -9 -f 'node server/src/app' 2>/dev/null
pkill -9 -f 'node cockpit/server' 2>/dev/null
sleep 2

cd /opt/kvm-space
KVM_MODE=libvirt nohup /usr/local/node-v14.21.3-linux-arm64/bin/node server/src/app.js > /tmp/mc.log 2>&1 &
echo "MC PID: $!"

nohup /usr/local/node-v14.21.3-linux-arm64/bin/node cockpit/server/src/app.js > /tmp/cockpit.log 2>&1 &
echo "Cockpit PID: $!"

sleep 3

echo "=== MC test ==="
curl -s -X POST http://localhost:8444/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"root","password":"root"}' | head -c 200
echo

echo "=== Cockpit test ==="
curl -s -X POST http://localhost:9091/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"root","password":"root"}' | head -c 200
echo

echo "=== Ports ==="
ss -tlnp | grep -E '8444|9091'

echo "=== MC startup log ==="
tail -10 /tmp/mc.log

echo "=== Done ==="
