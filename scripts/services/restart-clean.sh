#!/bin/bash
# Clean restart of MC and Cockpit services
NODE=/usr/local/node-v14.21.3-linux-arm64/bin/node
BASEDIR=/opt/kvm-space

# Kill existing processes
pkill -9 -f 'node.*server/src/app.js' 2>/dev/null
pkill -9 -f 'node.*cockpit/server/src/app.js' 2>/dev/null
sleep 2

# Clear logs
> /tmp/mc.log
> /tmp/cockpit.log

# Start MC
cd $BASEDIR
KVM_MODE=libvirt nohup $NODE server/src/app.js >> /tmp/mc.log 2>&1 &
MC_PID=$!
echo "MC PID: $MC_PID"

# Start Cockpit
nohup $NODE cockpit/server/src/app.js >> /tmp/cockpit.log 2>&1 &
CK_PID=$!
echo "Cockpit PID: $CK_PID"

# Wait for startup
sleep 5

echo "=== MC LOG ==="
cat /tmp/mc.log
echo ""
echo "=== COCKPIT LOG ==="
cat /tmp/cockpit.log
echo ""
echo "=== PORTS ==="
ss -tlnp | grep -E '8444|9091'
echo "=== DONE ==="
