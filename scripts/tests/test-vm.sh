#!/bin/bash
# Test MC and Cockpit APIs
echo "=== MC LOGIN (root/root) ==="
curl -s -X POST http://localhost:8444/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"root","password":"root"}' | python3 -m json.tool 2>/dev/null || echo "FAILED"

echo ""
echo "=== MC LOGIN (admin/admin123) ==="
ADMIN_RESP=$(curl -s -X POST http://localhost:8444/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"admin123"}')
echo "$ADMIN_RESP" | python3 -m json.tool 2>/dev/null || echo "FAILED: $ADMIN_RESP"

TOKEN=$(echo "$ADMIN_RESP" | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])" 2>/dev/null)

if [ -z "$TOKEN" ]; then
  echo "NO TOKEN - cannot continue tests"
  exit 1
fi

echo ""
echo "=== LIST EXISTING VMs ==="
curl -s http://localhost:8444/api/vms -H "Authorization: Bearer $TOKEN" | python3 -c "
import sys,json
data=json.load(sys.stdin)
vms=data.get('data',data) if isinstance(data,dict) else data
if isinstance(vms,list):
    print(f'Total VMs: {len(vms)}')
    for vm in vms[:3]:
        print(f'  {vm[\"id\"][:8]}... name={vm[\"name\"]} status={vm[\"status\"]}')
else:
    print(data)
" 2>/dev/null

echo ""
echo "=== DELETE STALE TEST VMs ==="
curl -s http://localhost:8444/api/vms -H "Authorization: Bearer $TOKEN" | python3 -c "
import sys,json
data=json.load(sys.stdin)
vms=data.get('data',data) if isinstance(data,dict) else data
for vm in vms:
    if 'test' in vm.get('name','').lower():
        print(f'Will delete: {vm[\"id\"]} ({vm[\"name\"]})')
" 2>/dev/null

echo ""
echo "=== CREATE NEW TEST VM ==="
CREATE_RESP=$(curl -s -X POST http://localhost:8444/api/vms \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "test-aarch64-ok",
    "cpu": 2,
    "memory": 1024,
    "disk": 10,
    "os_type": "linux",
    "os_version": "kylin-v10"
  }')
echo "$CREATE_RESP" | python3 -m json.tool 2>/dev/null || echo "FAILED: $CREATE_RESP"
VM_ID=$(echo "$CREATE_RESP" | python3 -c "import sys,json; print(json.load(sys.stdin)['id'])" 2>/dev/null)
echo "Created VM ID: $VM_ID"

if [ -n "$VM_ID" ]; then
  echo ""
  echo "=== CHECK GENERATED XML ==="
  cat /tmp/kvm-cloud-vm-${VM_ID}.xml 2>/dev/null || echo "No XML file found"

  echo ""
  echo "=== VIRSH LIST ==="
  virsh list --all | head -10

  echo ""
  echo "=== START VM ==="
  START_RESP=$(curl -s -X POST http://localhost:8444/api/vms/${VM_ID}/start \
    -H "Authorization: Bearer $TOKEN")
  echo "$START_RESP" | python3 -m json.tool 2>/dev/null || echo "FAILED: $START_RESP"

  sleep 3
  echo ""
  echo "=== VIRSH LIST AFTER START ==="
  virsh list --all | head -10

  echo ""
  echo "=== MC LOG (last 20 lines) ==="
  tail -20 /tmp/mc.log
fi
