#!/bin/bash
# Test VM operations
BASE="http://localhost:8444"
TOKEN=$(curl -s -X POST $BASE/api/auth/login -H 'Content-Type: application/json' -d '{"username":"admin","password":"admin123"}' | python3 -c 'import sys,json; print(json.load(sys.stdin).get("token","FAIL"))')
AUTH="Authorization: Bearer $TOKEN"

# Get first VM
VM_ID=$(curl -s $BASE/api/vms -H "$AUTH" | python3 -c 'import sys,json; d=json.load(sys.stdin)["data"]; print(d[0]["id"] if d else "NONE")')
echo "TEST VM: $VM_ID"

# Try to start it 
echo "=== START VM ==="
curl -s -X POST "$BASE/api/vms/$VM_ID/action" -H "$AUTH" -H 'Content-Type: application/json' -d '{"action":"start"}' | python3 -m json.tool 2>/dev/null

# Check server log for errors
echo "=== RECENT SERVER LOG ==="
tail -30 /tmp/mc.log

# Check if virsh sees the VM
echo ""
echo "=== VIRSH LIST ==="
virsh list --all 2>&1

# Check virsh VM by name
echo ""
echo "=== VIRSH DOMINFO ==="
virsh dominfo test-vm-001 2>&1
