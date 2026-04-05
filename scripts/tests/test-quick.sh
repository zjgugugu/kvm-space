#!/bin/bash
# Quick test of MC and Cockpit login
echo "=== MC LOGIN (root/root) ==="
curl -s -X POST http://localhost:8444/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"root","password":"root"}' | python3 -m json.tool 2>/dev/null

echo ""
echo "=== MC LOGIN (admin/admin123) ==="
curl -s -X POST http://localhost:8444/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"admin123"}' | python3 -m json.tool 2>/dev/null

echo ""
echo "=== COCKPIT LOGIN (root/root) ==="
curl -s -X POST http://localhost:9091/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"root","password":"root"}' | python3 -m json.tool 2>/dev/null

echo ""
echo "=== NOW TEST VM CREATE & START ==="
TOKEN=$(curl -s -X POST http://localhost:8444/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"admin123"}' | python3 -c 'import sys,json; print(json.load(sys.stdin).get("token","FAIL"))')

AUTH="Authorization: Bearer $TOKEN"

echo ""
echo "=== CREATE VM ==="
curl -s -X POST http://localhost:8444/api/vms \
  -H "$AUTH" \
  -H 'Content-Type: application/json' \
  -d '{"name":"test-aarch64-vm","cpu":2,"memory":1024,"disk":10,"os_type":"linux","os_version":"kylin-v10"}' | python3 -m json.tool 2>/dev/null

echo ""
echo "=== LIST VMs (first 2) ==="
curl -s http://localhost:8444/api/vms -H "$AUTH" | python3 -c '
import sys, json
data = json.load(sys.stdin)
vms = data.get("data", [])[:2]
for vm in vms:
    print(f"  {vm[\"id\"][:8]}... name={vm[\"name\"]} status={vm[\"status\"]} cpu={vm[\"cpu\"]} mem={vm[\"memory\"]}")
'

echo ""
echo "=== VIRSH LIST ==="
virsh list --all

echo ""
echo "=== STARTUP LOG (last 10 lines) ==="
tail -10 /tmp/mc.log
