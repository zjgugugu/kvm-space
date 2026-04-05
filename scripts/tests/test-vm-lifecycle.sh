#!/bin/bash
# Quick VM lifecycle test
export PATH=/usr/local/node-v14.21.3-linux-arm64/bin:$PATH

TOKEN=$(curl -sk https://localhost:8444/api/auth/login -X POST \
  -H 'Content-Type: application/json' \
  -d '{"username":"root","password":"root"}' -m 5 \
  | python3 -c 'import sys,json; print(json.load(sys.stdin).get("token",""))' 2>/dev/null)

echo "=== Before: Dashboard CPU ==="
curl -sk https://localhost:8444/api/dashboard/overview \
  -H "Authorization: Bearer $TOKEN" -m 5 \
  | python3 -c 'import sys,json; d=json.load(sys.stdin); print(f"CPU: {d[\"cpu\"][\"used\"]}/{d[\"cpu\"][\"total\"]}, VMs: {d[\"vm\"][\"total\"]}")'

echo ""
echo "=== Create VM ==="
VM_RESP=$(curl -sk https://localhost:8444/api/vms -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"name":"lifecycle-test","cpu":2,"memory":2048,"disk":10,"os_type":"linux"}' -m 15)
# Extract ID directly from root object
VM_ID=$(echo "$VM_RESP" | python3 -c 'import sys,json; d=json.load(sys.stdin); print(d.get("id",""))' 2>/dev/null)
echo "VM ID: $VM_ID"
echo "VM Status: $(echo "$VM_RESP" | python3 -c 'import sys,json; d=json.load(sys.stdin); print(d.get("status",""))' 2>/dev/null)"

if [ -z "$VM_ID" ]; then echo "CREATE FAILED"; echo "$VM_RESP"; exit 1; fi

echo ""
echo "=== virsh list before start ==="
virsh list --all 2>/dev/null | head -8

echo ""
echo "=== Start VM ==="
START_RESP=$(curl -sk https://localhost:8444/api/vms/$VM_ID/action -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"action":"start"}' -m 30)
echo "$START_RESP" | python3 -m json.tool

echo ""
echo "=== virsh list after start ==="
virsh list --all 2>/dev/null | head -8

echo ""
echo "=== After Start: Dashboard CPU ==="
curl -sk https://localhost:8444/api/dashboard/overview \
  -H "Authorization: Bearer $TOKEN" -m 10 \
  | python3 -c 'import sys,json; d=json.load(sys.stdin); print(f"CPU: {d[\"cpu\"][\"used\"]}/{d[\"cpu\"][\"total\"]}, VMs running: {d[\"vm\"][\"connected\"]}")'

echo ""
echo "=== VM Detail ==="
curl -sk https://localhost:8444/api/vms/$VM_ID \
  -H "Authorization: Bearer $TOKEN" -m 5 \
  | python3 -c 'import sys,json; d=json.load(sys.stdin); print(f"Status: {d.get(\"status\")}, CPU: {d.get(\"cpu\")}, Mem: {d.get(\"memory\")}MB, VNC: {d.get(\"vnc_port\")}")'

echo ""
echo "=== Stop VM ==="
STOP_RESP=$(curl -sk https://localhost:8444/api/vms/$VM_ID/action -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"action":"stop"}' -m 45)
echo "$STOP_RESP" | python3 -m json.tool

echo ""
echo "=== Delete VM ==="
DEL_RESP=$(curl -sk https://localhost:8444/api/vms/$VM_ID -X DELETE \
  -H "Authorization: Bearer $TOKEN" -m 10)
echo "$DEL_RESP" | python3 -m json.tool

echo ""
echo "=== virsh list after delete ==="
virsh list --all 2>/dev/null | head -8

echo ""
echo "=== LIFECYCLE TEST COMPLETE ==="
