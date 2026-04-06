#!/bin/bash
# Simple VM test
TOKEN=$(curl -sk --max-time 10 -X POST https://localhost:8444/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"root","password":"root"}' | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])")

echo "TOKEN: ${TOKEN:0:20}..."

echo ""
echo "=== VMs List ==="
curl -sk --max-time 15 -H "Authorization: Bearer $TOKEN" https://localhost:8444/api/vms 2>&1 | head -c 2000
echo ""

echo "=== Virsh List ==="  
virsh list --all 2>&1

echo ""
echo "=== Create VM ==="
curl -sk --max-time 15 -X POST -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -d '{"name":"test-vm-001","cpu":1,"memory":512,"os":"linux","disk_size":10}' \
  https://localhost:8444/api/vms 2>&1 | head -c 1000
echo ""

echo "=== Done ==="
