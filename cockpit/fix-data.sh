#!/bin/bash
# Fix cockpit 9091 data to match real cockpit 9090 database
TOKEN=$(curl -sf http://localhost:9091/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"root","password":"unikylinsec"}' | python3 -c 'import sys,json; print(json.load(sys.stdin)["token"])')
AUTH="Authorization: Bearer $TOKEN"

echo "1. Fixing node data..."
# Delete existing wrong nodes
NODES=$(curl -sf http://localhost:9091/api/cluster/nodes -H "$AUTH")
echo "Current nodes: $NODES"

# Get existing node IDs and delete them
echo "$NODES" | python3 -c '
import sys, json
data = json.load(sys.stdin).get("data", [])
for n in data:
    print(n.get("id", ""))
' | while read id; do
  if [ -n "$id" ]; then
    echo "Deleting node $id"
    curl -sf -X DELETE "http://localhost:9091/api/cluster/nodes/$id" -H "$AUTH" > /dev/null 2>&1
  fi
done

echo "2. Adding correct node matching real system..."
# Real: id=1, name=node1, ip=10.126.33.238, role=CM_VDI, is_docker_node=1, docker_ip=10.126.33.194, docker_hostname=dockernode1
curl -sf -X POST http://localhost:9091/api/cluster/nodes \
  -H "$AUTH" -H 'Content-Type: application/json' \
  -d '{"name":"node1","ip":"10.126.33.238","role":"CM_VDI","is_docker_node":1,"docker_ip":"10.126.33.194","docker_hostname":"dockernode1","storage_ip":""}' 
echo ""

echo "3. Fixing deploy status..."
# Real: status=1 (not 0), is_branch=0, manager_storage_type=GlusterFS, mmm_vip=10.126.33.195
# Need to update deploy_status - check if there's an API for this or do it directly
# The deploy endpoint sets status=1, let's re-deploy with correct data
curl -sf -X POST http://localhost:9091/api/cluster/deploy \
  -H "$AUTH" -H 'Content-Type: application/json' \
  -d '{"type":1,"storage_mode":"GlusterFS","nodes":[{"name":"node1","ip":"10.126.33.238","role":"CM_VDI"}]}'
echo ""

echo "4. Fixing mmm_vip to match real system (10.126.33.195)..."
# This requires direct DB update - need to add an API or fix the deploy to accept mmm_vip

echo "5. Fixing NTP interval back to 5..."
curl -sf -X PUT http://localhost:9091/api/config/ntp \
  -H "$AUTH" -H 'Content-Type: application/json' \
  -d '{"server":"0","time_update_interval":5}'
echo ""

echo "6. Verify..."
echo "Nodes:"
curl -sf http://localhost:9091/api/cluster/nodes -H "$AUTH" | python3 -m json.tool
echo "Status:"
curl -sf http://localhost:9091/api/cluster/status -H "$AUTH" | python3 -m json.tool
echo "NTP:"
curl -sf http://localhost:9091/api/config/ntp -H "$AUTH" | python3 -m json.tool
