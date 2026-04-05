#!/bin/bash
# Restart and test both services
export PATH=/usr/local/node-v14.21.3-linux-arm64/bin:$PATH

echo '=== Restarting services ==='
pkill -9 -f 'node.*app.js' 2>/dev/null
sleep 2

cd /opt/kvm-space
KVM_MODE=libvirt nohup node server/src/app.js > /tmp/mc.log 2>&1 &
MC_PID=$!
nohup node cockpit/server/src/app.js > /tmp/cockpit.log 2>&1 &
CK_PID=$!
sleep 3

echo "MC PID: $MC_PID, Cockpit PID: $CK_PID"
echo '--- MC Log ---'
tail -3 /tmp/mc.log
echo '--- Cockpit Log ---'
tail -2 /tmp/cockpit.log

echo ''
echo '=== Test 1: MC Login (root/root) ==='
TOKEN=$(curl -sk https://localhost:8444/api/auth/login -X POST \
  -H 'Content-Type: application/json' \
  -d '{"username":"root","password":"root"}' -m 5 \
  | python3 -c 'import sys,json; d=json.load(sys.stdin); print(d.get("token",""))' 2>/dev/null)
if [ -n "$TOKEN" ]; then echo "Login OK"; else echo "Login FAILED"; exit 1; fi

echo ''
echo '=== Test 2: Dashboard Overview ==='
curl -sk https://localhost:8444/api/dashboard/overview \
  -H "Authorization: Bearer $TOKEN" -m 5 | python3 -m json.tool

echo ''
echo '=== Test 3: Create VM ==='
VM_RESP=$(curl -sk https://localhost:8444/api/vms -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"name":"test-e2e-vm","cpu":2,"memory":2048,"disk":10,"os_type":"linux"}' -m 15)
echo "$VM_RESP" | python3 -m json.tool
VM_ID=$(echo "$VM_RESP" | python3 -c 'import sys,json; d=json.load(sys.stdin); print(d.get("vm",{}).get("id",""))' 2>/dev/null)
echo "Created VM ID: $VM_ID"

if [ -n "$VM_ID" ]; then
  echo ''
  echo '=== Test 4: Start VM ==='
  curl -sk https://localhost:8444/api/vms/$VM_ID/action -X POST \
    -H "Authorization: Bearer $TOKEN" \
    -H 'Content-Type: application/json' \
    -d '{"action":"start"}' -m 30 | python3 -m json.tool

  sleep 2

  echo ''
  echo '=== Test 5: Check Dashboard (CPU should be > 0 now) ==='
  curl -sk https://localhost:8444/api/dashboard/overview \
    -H "Authorization: Bearer $TOKEN" -m 5 \
    | python3 -c 'import sys,json; d=json.load(sys.stdin); print(f"CPU: {d[\"cpu\"][\"used\"]}/{d[\"cpu\"][\"total\"]}, MEM: {d[\"mem\"][\"used\"]}/{d[\"mem\"][\"total\"]}GB")'

  echo ''
  echo '=== Test 6: VM Detail ==='
  curl -sk https://localhost:8444/api/vms/$VM_ID \
    -H "Authorization: Bearer $TOKEN" -m 5 | python3 -m json.tool

  echo ''
  echo '=== Test 7: Stop VM ==='
  curl -sk https://localhost:8444/api/vms/$VM_ID/action -X POST \
    -H "Authorization: Bearer $TOKEN" \
    -H 'Content-Type: application/json' \
    -d '{"action":"stop"}' -m 40 | python3 -m json.tool

  echo ''
  echo '=== Test 8: Delete VM ==='
  curl -sk https://localhost:8444/api/vms/$VM_ID -X DELETE \
    -H "Authorization: Bearer $TOKEN" -m 10 | python3 -m json.tool

  echo ''
  echo '=== Test 9: Check virsh cleanup ==='
  virsh list --all --uuid | grep "$VM_ID" && echo "VM still in virsh!" || echo "VM cleaned from virsh"
fi

echo ''
echo '=== Test 10: Cockpit Login ==='
CK_RESP=$(curl -sk https://localhost:9091/api/auth/login -X POST \
  -H 'Content-Type: application/json' \
  -d '{"username":"root","password":"root"}' -m 5)
echo "$CK_RESP" | python3 -c 'import sys,json; d=json.load(sys.stdin); print("Cockpit Login:", "OK" if d.get("token") else "FAILED")'

echo ''
echo '=== Test 11: Cockpit -> MC Link ==='
grep -o "8443\|8444" /opt/kvm-space/cockpit/web/index.html | sort -u

echo ''
echo '=== ALL TESTS DONE ==='
