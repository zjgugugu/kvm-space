#!/bin/bash
RESP=$(curl -s -X POST http://localhost:8444/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"root","password":"root"}')
TOKEN=$(echo "$RESP" | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])" 2>/dev/null)

echo "=== System Config ==="
curl -s http://localhost:8444/api/system/config -H "Authorization: Bearer $TOKEN" | head -c 500
echo ""

echo "=== Stats ==="
curl -s http://localhost:8444/api/stats -H "Authorization: Bearer $TOKEN" | head -c 500
echo ""

echo "=== Clean stale VMs ==="
curl -s http://localhost:8444/api/vms -H "Authorization: Bearer $TOKEN" | python3 -c "
import sys, json, subprocess
d = json.load(sys.stdin)
vms = d.get('data', d)
for vm in vms:
    vid = vm['id']
    name = vm.get('name', '?')
    # Check if actually defined in libvirt
    import os
    ret = os.system('virsh dominfo %s >/dev/null 2>&1' % vid)
    status = 'libvirt-ok' if ret == 0 else 'STALE'
    print('  %s  %s  %s' % (status, vid[:12], name))
"
