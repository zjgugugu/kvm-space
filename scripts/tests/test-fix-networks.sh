#!/bin/bash
# Fix network data with correct values from libvirt
TOKEN=$(curl -sk --max-time 10 -X POST https://localhost:8444/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"root","password":"root"}' | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])")

# Get network ID
NET_ID=$(curl -sk -H "Authorization: Bearer $TOKEN" https://localhost:8444/api/networks 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin)['data']; print(d[0]['id'] if d else '')" 2>/dev/null)

echo "Updating network $NET_ID with real libvirt data..."

# Update with real network data from `virsh net-dumpxml default`
curl -sk -X PUT -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -d '{"name":"default","type":"nat","bridge":"virbr0","subnet":"192.168.122.0/24","gateway":"192.168.122.1","netmask":"255.255.255.0","dhcp_enabled":1,"dhcp_start":"192.168.122.2","dhcp_end":"192.168.122.254","status":"active","description":"Default NAT network (virbr0)"}' \
  "https://localhost:8444/api/networks/$NET_ID" 2>&1
echo ""

# Also add the br0 bridge network (used by real KSVD VMs)
echo ""
echo "Adding br0 bridge network..."
curl -sk -X POST -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -d '{"name":"management","type":"bridge","bridge":"br0","subnet":"10.126.33.0/24","gateway":"10.126.33.254","netmask":"255.255.255.0","dhcp_enabled":0,"status":"active","description":"Management bridge network (br0)"}' \
  https://localhost:8444/api/networks 2>&1
echo ""

# Add ksvdinat0 bridge (used by KSVD real system VMs)
echo ""
echo "Adding ksvdinat0 bridge network..."
curl -sk -X POST -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -d '{"name":"ksvd-internal","type":"bridge","bridge":"ksvdinat0","subnet":"192.168.200.0/24","gateway":"192.168.200.1","netmask":"255.255.255.0","dhcp_enabled":1,"status":"active","description":"KSVD internal NAT bridge"}' \
  https://localhost:8444/api/networks 2>&1
echo ""

echo ""
echo "=== Verify ==="
curl -sk -H "Authorization: Bearer $TOKEN" https://localhost:8444/api/networks 2>/dev/null | python3 -m json.tool 2>/dev/null
