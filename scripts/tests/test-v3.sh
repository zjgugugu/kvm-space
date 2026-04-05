#!/bin/bash
NODE=/usr/local/node-v14.21.3-linux-arm64/bin/node
cd /opt/kvm-space

# Undefine old test VM and clean up
virsh undefine bece04cf-bdbe-4f0f-8257-ca590842b103 2>/dev/null
virsh undefine e89ab432-b985-46f2-826b-a788089b34b6 2>/dev/null

# Restart MC
pkill -f 'node.*server/src/app.js' 2>/dev/null
sleep 2
> /tmp/mc.log
KVM_MODE=libvirt nohup $NODE server/src/app.js >> /tmp/mc.log 2>&1 &
sleep 4
cat /tmp/mc.log

echo ""
echo "=== LOGIN ==="
RESP=$(curl -s -X POST http://localhost:8444/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"root","password":"root"}')
TOKEN=$(echo "$RESP" | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])" 2>/dev/null)
echo "Root login: OK (token ${TOKEN:0:15}...)"

echo ""
echo "=== CREATE VM ==="
CREATE_RESP=$(curl -s -X POST http://localhost:8444/api/vms \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"name":"test-v3","cpu":2,"memory":1024,"disk":10,"os_type":"linux","os_version":"kylin-v10"}')
VM_ID=$(echo "$CREATE_RESP" | python3 -c "import sys,json; print(json.load(sys.stdin)['id'])" 2>/dev/null)
echo "VM ID: $VM_ID"

if [ -n "$VM_ID" ]; then
  echo ""
  echo "=== DISK OWNERSHIP ==="
  ls -la /data/kvm-cloud/images/${VM_ID}-sys.qcow2

  echo ""
  echo "=== VM XML KEY PARTS ==="
  virsh dumpxml $VM_ID 2>/dev/null | grep -E 'emulator|hugepages|memoryBacking|memory unit|machine'

  echo ""
  echo "=== START VM ==="
  START_RESP=$(curl -s -X POST "http://localhost:8444/api/vms/$VM_ID/action" \
    -H "Authorization: Bearer $TOKEN" \
    -H 'Content-Type: application/json' \
    -d '{"action":"start"}')
  echo "$START_RESP"

  sleep 3
  echo ""
  echo "=== VIRSH LIST ==="
  virsh list --all | head -10

  echo ""
  echo "=== MC LOG TAIL ==="
  tail -10 /tmp/mc.log
fi
