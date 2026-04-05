#!/bin/bash
NODE=/usr/local/node-v14.21.3-linux-arm64/bin/node
cd /opt/kvm-space

# Undefine old broken VM
echo "=== UNDEFINE OLD VM ==="
virsh undefine e89ab432-b985-46f2-826b-a788089b34b6 2>/dev/null && echo "Undefined" || echo "Not found"

# Clean up stale disk images (keep only the real MC VM's)
echo "=== CLEAN STALE DISKS ==="
ls /data/kvm-cloud/images/ | wc -l
# Keep only the real disk, remove test ones
# Actually let's just restart and test with a fresh VM

# Restart MC
echo "=== RESTART MC ==="
pkill -f 'node.*server/src/app.js' 2>/dev/null
sleep 2
> /tmp/mc.log
KVM_MODE=libvirt nohup $NODE server/src/app.js >> /tmp/mc.log 2>&1 &
sleep 4

echo "=== MC LOG ==="
cat /tmp/mc.log

echo ""
echo "=== TEST ROOT LOGIN ==="
ROOT_RESP=$(curl -s -X POST http://localhost:8444/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"root","password":"root"}')
echo "$ROOT_RESP"
ROOT_TOKEN=$(echo "$ROOT_RESP" | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])" 2>/dev/null)

echo ""
echo "=== TEST ADMIN LOGIN ==="
ADMIN_RESP=$(curl -s -X POST http://localhost:8444/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"admin123"}')
TOKEN=$(echo "$ADMIN_RESP" | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])" 2>/dev/null)
echo "Admin token: ${TOKEN:0:20}..."

# Use whichever token works
ACTIVE_TOKEN=${ROOT_TOKEN:-$TOKEN}

echo ""
echo "=== CREATE & START VM ==="
CREATE_RESP=$(curl -s -X POST http://localhost:8444/api/vms \
  -H "Authorization: Bearer $ACTIVE_TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"name":"test-final","cpu":2,"memory":1024,"disk":10,"os_type":"linux","os_version":"kylin-v10"}')
echo "CREATE: $CREATE_RESP" | head -c 200
echo ""
VM_ID=$(echo "$CREATE_RESP" | python3 -c "import sys,json; print(json.load(sys.stdin)['id'])" 2>/dev/null)
echo "VM ID: $VM_ID"

if [ -n "$VM_ID" ]; then
  echo ""
  echo "=== VERIFY XML (no hugepages) ==="
  virsh dumpxml $VM_ID 2>/dev/null | grep -A2 'memoryBacking' && echo "FOUND hugepages (BAD)" || echo "No hugepages (GOOD)"

  echo ""
  echo "=== START VM ==="
  START_RESP=$(curl -s -X POST "http://localhost:8444/api/vms/$VM_ID/action" \
    -H "Authorization: Bearer $ACTIVE_TOKEN" \
    -H 'Content-Type: application/json' \
    -d '{"action":"start"}')
  echo "$START_RESP"

  sleep 3
  echo ""
  echo "=== VIRSH STATUS ==="
  virsh list --all | head -10

  echo ""
  echo "=== MC LOG (last 15) ==="
  tail -15 /tmp/mc.log
fi
