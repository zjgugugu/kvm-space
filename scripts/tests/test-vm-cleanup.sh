#!/bin/bash
# Cleanup: force stop and permanently delete test VM
TOKEN=$(curl -sk --max-time 10 -X POST https://localhost:8444/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"root","password":"root"}' | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])")

VM_ID="53c14555-26ea-44a8-937c-743ac5e0b6a1"

echo "=== Force stop ==="
curl -sk --max-time 10 -X POST -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -d '{"action":"force_stop"}' \
  "https://localhost:8444/api/vms/$VM_ID/action" 2>&1
echo ""
sleep 2

echo "=== Virsh state ==="
virsh domstate $VM_ID 2>&1

echo ""
echo "=== Permanent delete ==="
curl -sk --max-time 15 -X DELETE -H "Authorization: Bearer $TOKEN" \
  "https://localhost:8444/api/vms/$VM_ID?permanent=true" 2>&1
echo ""
sleep 1

echo ""
echo "=== Virsh after delete ==="
virsh dominfo $VM_ID 2>&1 && echo "STILL EXISTS" || echo "OK: Removed"

echo ""
echo "=== Final list ==="
virsh list --all 2>&1
