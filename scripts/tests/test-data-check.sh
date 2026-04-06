#!/bin/bash
# Quick data check
TOKEN=$(curl -sk --max-time 10 -X POST https://localhost:8444/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"root","password":"root"}' | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])")

echo "=== Hosts raw ==="
curl -sk -H "Authorization: Bearer $TOKEN" https://localhost:8444/api/hosts 2>/dev/null | python3 -m json.tool 2>/dev/null | head -30

echo ""
echo "=== VMs raw ==="
curl -sk -H "Authorization: Bearer $TOKEN" https://localhost:8444/api/vms 2>/dev/null | python3 -m json.tool 2>/dev/null | head -40

echo ""
echo "=== Networks raw ==="
curl -sk -H "Authorization: Bearer $TOKEN" https://localhost:8444/api/networks 2>/dev/null | python3 -m json.tool 2>/dev/null | head -20

echo ""
echo "=== Storage pools raw ==="
curl -sk -H "Authorization: Bearer $TOKEN" https://localhost:8444/api/storage/pools 2>/dev/null | python3 -m json.tool 2>/dev/null | head -20

echo ""
echo "=== DB host count ==="
/usr/local/bin/node14 -e "
const db = require('/opt/kvm-space/server/src/db/sqlite-wrapper');
(async () => {
  const d = await db.openDatabase('/opt/kvm-space/server/data/kvm-cloud.db');
  const hosts = d.prepare('SELECT COUNT(*) as c FROM hosts').get();
  const vms = d.prepare('SELECT COUNT(*) as c FROM vms WHERE deleted=0').get();
  const nets = d.prepare('SELECT COUNT(*) as c FROM networks').get();
  const pools = d.prepare('SELECT COUNT(*) as c FROM storage_pools').get();
  console.log('DB counts: hosts=' + hosts.c + ', vms=' + vms.c + ', networks=' + nets.c + ', pools=' + pools.c);
  const h = d.prepare('SELECT * FROM hosts').all();
  h.forEach(r => console.log('  host: ' + r.name + ' ip=' + r.ip + ' status=' + r.status));
})().catch(e => console.error(e));
" 2>&1
