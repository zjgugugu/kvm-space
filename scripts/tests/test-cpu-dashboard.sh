#!/bin/bash
# Quick dashboard CPU test - create VM, start, check CPU, cleanup
export PATH=/usr/local/node-v14.21.3-linux-arm64/bin:$PATH

TOKEN=$(curl -sk https://localhost:8444/api/auth/login -X POST \
  -H 'Content-Type: application/json' \
  -d '{"username":"root","password":"root"}' -m 5 \
  | python3 -c 'import sys,json; print(json.load(sys.stdin).get("token",""))' 2>/dev/null)

echo "=== Before: CPU data ==="
curl -sk https://localhost:8444/api/dashboard/overview -H "Authorization: Bearer $TOKEN" -m 10 \
  | python3 -c 'import sys,json; d=json.load(sys.stdin); print("CPU used=" + str(d["cpu"]["used"]) + " total=" + str(d["cpu"]["total"]) + " VMs_running=" + str(d["vm"]["connected"]))'

echo ""
echo "=== Create+Start VM ==="
VM_RESP=$(curl -sk https://localhost:8444/api/vms -X POST \
  -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -d '{"name":"cpu-test","cpu":4,"memory":4096,"disk":5,"os_type":"linux"}' -m 15)
VM_ID=$(echo "$VM_RESP" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("id",""))' 2>/dev/null)
echo "VM ID: $VM_ID"

curl -sk https://localhost:8444/api/vms/$VM_ID/action -X POST \
  -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -d '{"action":"start"}' -m 30 | python3 -m json.tool

echo ""
echo "=== After Start: CPU data ==="
curl -sk https://localhost:8444/api/dashboard/overview -H "Authorization: Bearer $TOKEN" -m 10 \
  | python3 -c 'import sys,json; d=json.load(sys.stdin); print("CPU used=" + str(d["cpu"]["used"]) + " total=" + str(d["cpu"]["total"]) + " VMs_running=" + str(d["vm"]["connected"]))'

echo ""
echo "=== Cleanup: stop+delete ==="
curl -sk https://localhost:8444/api/vms/$VM_ID/action -X POST \
  -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -d '{"action":"stop"}' -m 45 > /dev/null 2>&1
curl -sk https://localhost:8444/api/vms/$VM_ID -X DELETE \
  -H "Authorization: Bearer $TOKEN" -m 10 > /dev/null 2>&1
echo "Cleaned up"

echo ""
echo "=== Stale VMs in virsh ==="
virsh list --all 2>/dev/null
