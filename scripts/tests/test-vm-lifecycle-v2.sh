#!/bin/bash
# MC VM Lifecycle Test v2 - Tests create, list, start, stop, delete operations
set -e

TOKEN=$(curl -sk -X POST https://localhost:8444/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"root","password":"root"}' | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])")

echo "Login: OK"
echo ""

# 1. List current VMs from our API
echo "=== 1. Our API: Current VMs ==="
curl -sk -H "Authorization: Bearer $TOKEN" https://localhost:8444/api/vms 2>/dev/null | python3 -c "
import sys,json
data = json.load(sys.stdin)
vms = data.get('data', data if isinstance(data, list) else [])
if isinstance(vms, dict): vms = vms.get('data', [])
if not isinstance(vms, list): vms = []
print(f'API reports {len(vms)} VMs:')
for vm in vms:
    if isinstance(vm, dict):
        print(f'  {vm.get(\"name\",\"?\")}: status={vm.get(\"status\",\"?\")}, cpu={vm.get(\"cpu\",\"?\")}, mem={vm.get(\"memory\",vm.get(\"mem\",\"?\"))}MB, host={vm.get(\"host_name\",vm.get(\"host\",\"?\"))}')
" 2>/dev/null
echo ""

# 2. Real libvirt VMs
echo "=== 2. Real libvirt VMs ==="
virsh list --all 2>/dev/null || echo "(virsh not available)"
echo ""

# 3. Test VM create
echo "=== 3. Create Test VM ==="
CREATE_RESP=$(curl -sk -X POST -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -d '{"name":"test-lifecycle-vm","cpu":1,"memory":512,"os":"linux","disk_size":10}' \
  https://localhost:8444/api/vms 2>/dev/null)
echo "Create response:"
echo "$CREATE_RESP" | python3 -m json.tool 2>/dev/null || echo "$CREATE_RESP"

NEW_VM_ID=$(echo "$CREATE_RESP" | python3 -c "
import sys,json
d = json.load(sys.stdin)
vm = d.get('data', d.get('vm', d))
if isinstance(vm, dict): print(vm.get('id',''))
elif isinstance(d, dict) and 'id' in d: print(d['id'])
" 2>/dev/null)
echo "New VM ID: $NEW_VM_ID"

# Check if VM appeared in libvirt
echo ""
echo "Checking libvirt..."
virsh list --all 2>/dev/null | grep -i "test-lifecycle" || echo "(not found in virsh)"
echo ""

# 4. Test VM actions
if [ -n "$NEW_VM_ID" ]; then
  echo "=== 4a. Start VM ==="
  curl -sk -X POST -H "Authorization: Bearer $TOKEN" \
    "https://localhost:8444/api/vms/$NEW_VM_ID/start" 2>/dev/null | python3 -m json.tool 2>/dev/null
  sleep 1
  
  echo ""
  echo "=== 4b. Check Status ==="
  curl -sk -H "Authorization: Bearer $TOKEN" \
    "https://localhost:8444/api/vms/$NEW_VM_ID" 2>/dev/null | python3 -c "
import sys,json
d = json.load(sys.stdin)
vm = d.get('data', d)
if isinstance(vm, dict): print(f'Status: {vm.get(\"status\",\"?\")}, Name: {vm.get(\"name\",\"?\")}')
" 2>/dev/null
  
  echo ""
  echo "Libvirt state:"
  virsh domstate test-lifecycle-vm 2>/dev/null || echo "(not in virsh)"
  
  echo ""
  echo "=== 4c. Stop VM ==="
  curl -sk -X POST -H "Authorization: Bearer $TOKEN" \
    "https://localhost:8444/api/vms/$NEW_VM_ID/stop" 2>/dev/null | python3 -m json.tool 2>/dev/null
  sleep 1
  
  echo ""
  echo "=== 4d. Delete VM ==="
  curl -sk -X DELETE -H "Authorization: Bearer $TOKEN" \
    "https://localhost:8444/api/vms/$NEW_VM_ID" 2>/dev/null | python3 -m json.tool 2>/dev/null
  
  echo ""
  echo "Verify deleted from libvirt:"
  virsh domstate test-lifecycle-vm 2>/dev/null && echo "WARNING: still exists!" || echo "OK: removed (or never existed)"
fi

# 5. Host detail
echo ""
echo "=== 5. Host Detail ==="
curl -sk -H "Authorization: Bearer $TOKEN" https://localhost:8444/api/hosts 2>/dev/null | python3 -c "
import sys,json
data = json.load(sys.stdin).get('data',[])
for h in (data if isinstance(data, list) else [data] if data else []):
    print(json.dumps(h, indent=2, ensure_ascii=False))
" 2>/dev/null | head -30

# 6. Templates
echo ""
echo "=== 6. Templates ==="
curl -sk -H "Authorization: Bearer $TOKEN" https://localhost:8444/api/templates 2>/dev/null | python3 -m json.tool 2>/dev/null | head -20

echo ""
echo "Done."
