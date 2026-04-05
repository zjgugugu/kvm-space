#!/bin/bash
# Test all users and VM start
echo "=== LOGIN as admin ==="
RESP=$(curl -s -X POST http://localhost:8444/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"admin123"}')
TOKEN=$(echo "$RESP" | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])" 2>/dev/null)
echo "Token: ${TOKEN:0:20}..."

echo ""
echo "=== LIST USERS ==="
curl -s http://localhost:8444/api/users \
  -H "Authorization: Bearer $TOKEN" | python3 -c "
import sys, json
data = json.load(sys.stdin)
users = data.get('data', data) if isinstance(data, dict) else data
for u in users:
    print(f\"  {u.get('username'):15s} role={u.get('role'):15s} status={u.get('status')}\")
"

echo ""
echo "=== LOGIN as root ==="
curl -s -X POST http://localhost:8444/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"root","password":"root"}' | python3 -m json.tool

echo ""
echo "=== START VM via action API ==="
VM_ID=$(curl -s http://localhost:8444/api/vms \
  -H "Authorization: Bearer $TOKEN" | python3 -c "
import sys, json
data = json.load(sys.stdin)
vms = data.get('data', data) if isinstance(data, dict) else data
for vm in vms:
    if vm.get('status') == 'stopped':
        print(vm['id'])
        break
" 2>/dev/null)
echo "Starting VM: $VM_ID"

if [ -n "$VM_ID" ]; then
  START_RESP=$(curl -s -X POST "http://localhost:8444/api/vms/$VM_ID/action" \
    -H "Authorization: Bearer $TOKEN" \
    -H 'Content-Type: application/json' \
    -d '{"action":"start"}')
  echo "$START_RESP" | python3 -m json.tool 2>/dev/null || echo "RAW: $START_RESP"

  sleep 3
  echo ""
  echo "=== VIRSH LIST ==="
  virsh list --all | head -10

  echo ""
  echo "=== MC LOG (last 15) ==="
  tail -15 /tmp/mc.log
fi
