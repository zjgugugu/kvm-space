#!/bin/bash
# VM lifecycle actions: start, stop, delete
TOKEN=$(curl -sk --max-time 10 -X POST https://localhost:8444/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"root","password":"root"}' | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])")

VM_ID="53c14555-26ea-44a8-937c-743ac5e0b6a1"
echo "Testing VM: $VM_ID"

echo ""
echo "=== 1. Start VM ==="
curl -sk --max-time 15 -X POST -H "Authorization: Bearer $TOKEN" \
  "https://localhost:8444/api/vms/$VM_ID/start" 2>&1 | head -c 500
echo ""

sleep 2

echo ""
echo "=== 2. Check virsh state ==="
virsh domstate $VM_ID 2>&1
virsh dominfo $VM_ID 2>&1 | head -10

echo ""
echo "=== 3. Check API state ==="
curl -sk --max-time 10 -H "Authorization: Bearer $TOKEN" \
  "https://localhost:8444/api/vms/$VM_ID" 2>&1 | python3 -c "
import sys,json
d = json.load(sys.stdin)
print(f'API status: {d.get(\"status\",\"?\")}, name: {d.get(\"name\",\"?\")}, ip: {d.get(\"ip\",\"?\")}')
" 2>/dev/null

echo ""
echo "=== 4. Stop VM ==="
curl -sk --max-time 15 -X POST -H "Authorization: Bearer $TOKEN" \
  "https://localhost:8444/api/vms/$VM_ID/stop" 2>&1 | head -c 500
echo ""

sleep 2

echo ""
echo "=== 5. Check virsh after stop ==="
virsh domstate $VM_ID 2>&1

echo ""
echo "=== 6. Delete VM ==="
curl -sk --max-time 15 -X DELETE -H "Authorization: Bearer $TOKEN" \
  "https://localhost:8444/api/vms/$VM_ID" 2>&1 | head -c 500
echo ""

sleep 1

echo ""
echo "=== 7. Check virsh after delete ==="
virsh dominfo $VM_ID 2>&1 || echo "OK: VM removed from libvirt"

echo ""
echo "=== 8. Final virsh list ==="
virsh list --all 2>&1

echo ""
echo "Done."
