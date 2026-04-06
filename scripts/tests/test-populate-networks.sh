#!/bin/bash
# Populate network data from real libvirt
TOKEN=$(curl -sk --max-time 10 -X POST https://localhost:8444/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"root","password":"root"}' | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])")

echo "=== Real libvirt networks ==="
virsh net-list --all

echo ""
echo "=== Default network details ==="
virsh net-dumpxml default 2>&1 | head -30

echo ""
echo "=== Real bridges ==="
ip link show type bridge 2>/dev/null | head -20
brctl show 2>/dev/null | head -20

echo ""
echo "=== Create network in our DB ==="
# Get default network info
NET_XML=$(virsh net-dumpxml default 2>/dev/null)
if [ -n "$NET_XML" ]; then
  BRIDGE=$(echo "$NET_XML" | grep -o 'bridge name="[^"]*"' | head -1 | cut -d'"' -f2)
  SUBNET=$(echo "$NET_XML" | grep -o 'address="[^"]*"' | head -1 | cut -d'"' -f2)
  MASK=$(echo "$NET_XML" | grep -o 'netmask="[^"]*"' | head -1 | cut -d'"' -f2)
  DHCP_START=$(echo "$NET_XML" | grep -o 'start="[^"]*"' | head -1 | cut -d'"' -f2)
  DHCP_END=$(echo "$NET_XML" | grep -o 'end="[^"]*"' | head -1 | cut -d'"' -f2)
  echo "Bridge: $BRIDGE, Subnet: $SUBNET, Mask: $MASK, DHCP: $DHCP_START - $DHCP_END"
  
  # Create default network via API
  curl -sk -X POST -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
    -d "{\"name\":\"default\",\"type\":\"nat\",\"bridge\":\"$BRIDGE\",\"subnet\":\"$SUBNET\",\"netmask\":\"$MASK\",\"dhcp_start\":\"$DHCP_START\",\"dhcp_end\":\"$DHCP_END\",\"status\":\"active\"}" \
    https://localhost:8444/api/networks 2>&1
  echo ""
fi

# Check real bridges used by VMs
echo ""
echo "=== Real VM network interfaces ==="
for vmid in $(virsh list --all --name 2>/dev/null | head -5); do
  if [ -n "$vmid" ]; then
    echo "VM: $vmid"
    virsh domiflist "$vmid" 2>/dev/null
    echo ""
  fi
done

echo ""
echo "=== Verify network in API ==="
curl -sk -H "Authorization: Bearer $TOKEN" https://localhost:8444/api/networks 2>/dev/null | python3 -m json.tool 2>/dev/null
