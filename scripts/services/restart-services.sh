#!/bin/bash
# Restart both services with HTTPS
export PATH=/usr/local/node-v14.21.3-linux-arm64/bin:$PATH
cd /opt/kvm-space

# Start MC
KVM_MODE=libvirt nohup node server/src/app.js > /tmp/mc.log 2>&1 &
echo "MC PID: $!"

# Start Cockpit
nohup node cockpit/server/src/app.js > /tmp/cockpit.log 2>&1 &
echo "Cockpit PID: $!"

sleep 3

echo "=== MC log ==="
tail -5 /tmp/mc.log
echo "=== Cockpit log ==="
tail -5 /tmp/cockpit.log
echo "=== Ports ==="
ss -tlnp | grep -E '9091|8444'
