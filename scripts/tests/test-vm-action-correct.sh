#!/bin/bash
# VM lifecycle using correct /action endpoint
TOKEN=$(curl -sk --max-time 10 -X POST https://localhost:8444/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"root","password":"root"}' | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])")

# The soft-deleted test VM should still be in libvirt
VM_ID="53c14555-26ea-44a8-937c-743ac5e0b6a1"

echo "=== 1. Restore from recycle bin ==="
curl -sk --max-time 10 -X POST -H "Authorization: Bearer $TOKEN" \
  "https://localhost:8444/api/vms/$VM_ID/restore" 2>&1 | head -c 500
echo ""

echo ""
echo "=== 2. Start VM (action endpoint) ==="
curl -sk --max-time 15 -X POST -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -d '{"action":"start"}' \
  "https://localhost:8444/api/vms/$VM_ID/action" 2>&1 | head -c 500
echo ""

sleep 3

echo ""
echo "=== 3. Virsh state after start ==="
virsh domstate $VM_ID 2>&1

echo ""
echo "=== 4. API status ==="
curl -sk --max-time 10 -H "Authorization: Bearer $TOKEN" \
  "https://localhost:8444/api/vms/$VM_ID" 2>&1 | python3 -c "
import sys,json
d = json.load(sys.stdin)
print(f'status={d.get(\"status\",\"?\")}, name={d.get(\"name\",\"?\")}, ip={d.get(\"ip\",\"?\")}')
" 2>/dev/null

echo ""
echo "=== 5. Stop VM ==="
curl -sk --max-time 15 -X POST -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -d '{"action":"stop"}' \
  "https://localhost:8444/api/vms/$VM_ID/action" 2>&1 | head -c 500
echo ""

sleep 3

echo ""
echo "=== 6. Virsh state after stop ==="
virsh domstate $VM_ID 2>&1

echo ""
echo "=== 7. Permanent delete ==="
curl -sk --max-time 15 -X DELETE -H "Authorization: Bearer $TOKEN" \
  "https://localhost:8444/api/vms/$VM_ID?permanent=true" 2>&1 | head -c 500
echo ""

sleep 1

echo ""
echo "=== 8. Virsh after permanent delete ==="
virsh dominfo $VM_ID 2>&1 || echo "OK: VM fully removed from libvirt"

echo ""
echo "=== 9. Final virsh list ==="
virsh list --all 2>&1

echo ""
echo "Done."
