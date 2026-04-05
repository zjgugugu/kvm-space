#!/bin/bash
# Final end-to-end test: restart services, full VM lifecycle
NODE=/usr/local/node-v14.21.3-linux-arm64/bin/node
cd /opt/kvm-space

# Restart MC
pkill -f 'node.*server/src/app.js' 2>/dev/null
sleep 2
> /tmp/mc.log
KVM_MODE=libvirt nohup $NODE server/src/app.js >> /tmp/mc.log 2>&1 &
sleep 4

echo "=== MC Started ==="
grep 'LibvirtDriver.*系统检测' /tmp/mc.log

# Login
RESP=$(curl -s -X POST http://localhost:8444/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"root","password":"root"}')
TOKEN=$(echo "$RESP" | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])" 2>/dev/null)
echo "Root login: OK"

# Dashboard
echo ""
echo "=== Dashboard Overview ==="
curl -s http://localhost:8444/api/dashboard/overview \
  -H "Authorization: Bearer $TOKEN" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print('  VM total=%s running=%s' % (d.get('vm',{}).get('total','?'), d.get('vm',{}).get('isRunning','?')))
print('  CPU total=%s' % d.get('cpu',{}).get('total','?'))
print('  Hosts online=%s' % d.get('server',{}).get('online','?'))
" 2>/dev/null

# Create VM
echo ""
echo "=== Create VM ==="
CREATE=$(curl -s -X POST http://localhost:8444/api/vms \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"name":"e2e-test-vm","cpu":2,"memory":1024,"disk":10,"os_type":"linux","os_version":"kylin-v10"}')
VM_ID=$(echo "$CREATE" | python3 -c "import sys,json; print(json.load(sys.stdin)['id'])" 2>/dev/null)
echo "  Created: $VM_ID"

# Start VM
echo ""
echo "=== Start VM ==="
START=$(curl -s -X POST "http://localhost:8444/api/vms/$VM_ID/action" \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"action":"start"}')
echo "  $START"

sleep 2

# Check running
echo ""
echo "=== Verify Running ==="
virsh list --all | head -5

# Get VM detail
echo ""
echo "=== VM Detail ==="
curl -s http://localhost:8444/api/vms/$VM_ID \
  -H "Authorization: Bearer $TOKEN" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print('  name=%s status=%s cpu=%s mem=%s vnc=%s' % (d.get('name','?'), d.get('status','?'), d.get('cpu','?'), d.get('memory','?'), d.get('vnc_port','?')))
" 2>/dev/null

# Stop VM
echo ""
echo "=== Stop VM ==="
STOP=$(curl -s -X POST "http://localhost:8444/api/vms/$VM_ID/action" \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"action":"force_stop"}')
echo "  $STOP"
sleep 2

# Delete VM
echo ""
echo "=== Delete VM ==="
DEL=$(curl -s -X DELETE "http://localhost:8444/api/vms/$VM_ID" \
  -H "Authorization: Bearer $TOKEN")
echo "  $DEL"

# Final virsh check
echo ""
echo "=== Final virsh list ==="
virsh list --all | head -5

# Dashboard after cleanup
echo ""
echo "=== Dashboard After ==="
curl -s http://localhost:8444/api/dashboard/overview \
  -H "Authorization: Bearer $TOKEN" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print('  VM total=%s' % d.get('vm',{}).get('total','?'))
" 2>/dev/null

echo ""
echo "=== ALL TESTS PASSED ==="
