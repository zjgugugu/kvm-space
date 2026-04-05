#!/bin/bash
# Restart MC server
pkill -f 'node server/src/app.js' || true
sleep 1
rm -f /opt/kvm-space/server/data/kvm-cloud.db
cd /opt/kvm-space
KVM_MODE=libvirt nohup /usr/local/node-v14.21.3-linux-arm64/bin/node server/src/app.js > /tmp/kvm.log 2>&1 &
sleep 2
echo "MC PID: $(pgrep -f 'node server/src/app.js')"
curl -s http://localhost:8444/api/info
echo ""
tail -3 /tmp/kvm.log
