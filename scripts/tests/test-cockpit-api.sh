#!/bin/bash
# Cockpit API 综合测试 (33 endpoints)
BASE="https://localhost:9091"
PASS=0
FAIL=0
TOTAL=0

check() {
  TOTAL=$((TOTAL+1))
  local desc="$1" expect="$2" actual="$3"
  if [ "$actual" -eq "$expect" ] 2>/dev/null || [ "$actual" = "$expect" ]; then
    PASS=$((PASS+1))
    echo "  ✓ $desc"
  else
    FAIL=$((FAIL+1))
    echo "  ✗ $desc (expected=$expect actual=$actual)"
  fi
}

echo "=== Cockpit API Test ==="

# 1. Public endpoints
echo ""
echo "--- Public ---"
CODE=$(curl -sk -o /dev/null -w '%{http_code}' $BASE/api/info)
check "GET /api/info" 200 "$CODE"

CODE=$(curl -sk -o /dev/null -w '%{http_code}' $BASE/)
check "GET / (frontend)" 200 "$CODE"

# 2. Auth
echo ""
echo "--- Auth ---"
RESP=$(curl -sk -w '\n%{http_code}' $BASE/api/auth/login \
  -X POST -H 'Content-Type: application/json' \
  -d '{"username":"root","password":"root"}')
CODE=$(echo "$RESP" | tail -1)
BODY=$(echo "$RESP" | sed '$d')
check "POST /api/auth/login" 200 "$CODE"

TOKEN=$(echo "$BODY" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
if [ -z "$TOKEN" ]; then
  echo "  ✗ No token received, cannot continue"
  echo "  Response body: $BODY"
  echo ""
  echo "=== Result: $PASS/$TOTAL ==="
  exit 1
fi
echo "  Token: ${TOKEN:0:20}..."

AUTH="Authorization: Bearer $TOKEN"

CODE=$(curl -sk -o /dev/null -w '%{http_code}' -H "$AUTH" $BASE/api/auth/me)
check "GET /api/auth/me" 200 "$CODE"

# 3. Cluster
echo ""
echo "--- Cluster ---"
CODE=$(curl -sk -o /dev/null -w '%{http_code}' -H "$AUTH" $BASE/api/cluster/status)
check "GET /api/cluster/status" 200 "$CODE"

CODE=$(curl -sk -o /dev/null -w '%{http_code}' -H "$AUTH" $BASE/api/cluster/nodes)
check "GET /api/cluster/nodes" 200 "$CODE"

# Add node
RESP=$(curl -sk -w '\n%{http_code}' -H "$AUTH" -H 'Content-Type: application/json' \
  -X POST $BASE/api/cluster/nodes \
  -d '{"name":"test-node","ip":"192.168.1.100","role":"VDI"}')
CODE=$(echo "$RESP" | tail -1)
BODY=$(echo "$RESP" | sed '$d')
check "POST /api/cluster/nodes (add)" 200 "$CODE"

NODE_ID=$(echo "$BODY" | grep -o '"id":[0-9]*' | head -1 | cut -d: -f2)

if [ -n "$NODE_ID" ]; then
  CODE=$(curl -sk -o /dev/null -w '%{http_code}' -H "$AUTH" -H 'Content-Type: application/json' \
    -X PUT $BASE/api/cluster/nodes/$NODE_ID/role \
    -d '{"role":"CM_VDI"}')
  check "PUT /api/cluster/nodes/:id/role" 200 "$CODE"

  CODE=$(curl -sk -o /dev/null -w '%{http_code}' -H "$AUTH" \
    -X DELETE $BASE/api/cluster/nodes/$NODE_ID)
  check "DELETE /api/cluster/nodes/:id" 200 "$CODE"
else
  check "PUT /api/cluster/nodes/:id/role" 200 "SKIP"
  check "DELETE /api/cluster/nodes/:id" 200 "SKIP"
fi

CODE=$(curl -sk -o /dev/null -w '%{http_code}' -H "$AUTH" -H 'Content-Type: application/json' \
  -X POST $BASE/api/cluster/deploy \
  -d '{"type":1,"storage_mode":"GlusterFS","nodes":[{"name":"node1","ip":"10.126.33.238","role":"CM_VDI","docker_ip":"10.0.0.1"}]}')
check "POST /api/cluster/deploy" 200 "$CODE"

CODE=$(curl -sk -o /dev/null -w '%{http_code}' -H "$AUTH" -X POST $BASE/api/cluster/shutdown)
check "POST /api/cluster/shutdown" 200 "$CODE"

CODE=$(curl -sk -o /dev/null -w '%{http_code}' -H "$AUTH" -X POST $BASE/api/cluster/reboot)
check "POST /api/cluster/reboot" 200 "$CODE"

# 4. Config
echo ""
echo "--- Config ---"
CODE=$(curl -sk -o /dev/null -w '%{http_code}' -H "$AUTH" $BASE/api/config/ntp)
check "GET /api/config/ntp" 200 "$CODE"

CODE=$(curl -sk -o /dev/null -w '%{http_code}' -H "$AUTH" -H 'Content-Type: application/json' \
  -X PUT $BASE/api/config/ntp \
  -d '{"server":"ntp.aliyun.com","time_update_interval":10}')
check "PUT /api/config/ntp" 200 "$CODE"

CODE=$(curl -sk -o /dev/null -w '%{http_code}' -H "$AUTH" $BASE/api/config/nfs)
check "GET /api/config/nfs" 200 "$CODE"

CODE=$(curl -sk -o /dev/null -w '%{http_code}' -H "$AUTH" -H 'Content-Type: application/json' \
  -X PUT $BASE/api/config/nfs \
  -d '{"ip":"192.168.1.10","share_dir":"/data/nfs","version":"4"}')
check "PUT /api/config/nfs" 200 "$CODE"

CODE=$(curl -sk -o /dev/null -w '%{http_code}' -H "$AUTH" $BASE/api/config/cifs)
check "GET /api/config/cifs" 200 "$CODE"

CODE=$(curl -sk -o /dev/null -w '%{http_code}' -H "$AUTH" -H 'Content-Type: application/json' \
  -X PUT $BASE/api/config/cifs \
  -d '{"ip":"192.168.1.11","share_dir":"share","user_name":"admin","password":"pass123"}')
check "PUT /api/config/cifs" 200 "$CODE"

CODE=$(curl -sk -o /dev/null -w '%{http_code}' -H "$AUTH" $BASE/api/config/center-cluster)
check "GET /api/config/center-cluster" 200 "$CODE"

CODE=$(curl -sk -o /dev/null -w '%{http_code}' -H "$AUTH" -H 'Content-Type: application/json' \
  -X PUT $BASE/api/config/center-cluster \
  -d '{"ip":"10.126.33.200","user_name":"admin","password":"pass","data_sync_time":"02:00"}')
check "PUT /api/config/center-cluster" 200 "$CODE"

CODE=$(curl -sk -o /dev/null -w '%{http_code}' -H "$AUTH" -H 'Content-Type: application/json' \
  -X PUT $BASE/api/config/roles \
  -d '{"updates":[]}')
check "PUT /api/config/roles" 200 "$CODE"

CODE=$(curl -sk -o /dev/null -w '%{http_code}' -H "$AUTH" $BASE/api/config/network)
check "GET /api/config/network" 200 "$CODE"

CODE=$(curl -sk -o /dev/null -w '%{http_code}' -H "$AUTH" -H 'Content-Type: application/json' \
  -X PUT $BASE/api/config/virtual-storage -d '{}')
check "PUT /api/config/virtual-storage" 200 "$CODE"

# 5. Maintain
echo ""
echo "--- Maintain ---"
CODE=$(curl -sk -o /dev/null -w '%{http_code}' -H "$AUTH" $BASE/api/maintain/recovery/status)
check "GET /api/maintain/recovery/status" 200 "$CODE"

CODE=$(curl -sk -o /dev/null -w '%{http_code}' -H "$AUTH" -X POST $BASE/api/maintain/recovery/scan)
check "POST /api/maintain/recovery/scan" 200 "$CODE"

CODE=$(curl -sk -o /dev/null -w '%{http_code}' -H "$AUTH" -X POST $BASE/api/maintain/recovery/heal)
check "POST /api/maintain/recovery/heal" 200 "$CODE"

CODE=$(curl -sk -o /dev/null -w '%{http_code}' -H "$AUTH" $BASE/api/maintain/backups)
check "GET /api/maintain/backups" 200 "$CODE"

CODE=$(curl -sk -o /dev/null -w '%{http_code}' -H "$AUTH" -H 'Content-Type: application/json' \
  -X POST $BASE/api/maintain/backups -d '{}')
check "POST /api/maintain/backups" 200 "$CODE"

CODE=$(curl -sk -o /dev/null -w '%{http_code}' -H "$AUTH" $BASE/api/maintain/logs)
check "GET /api/maintain/logs" 200 "$CODE"

CODE=$(curl -sk -o /dev/null -w '%{http_code}' -H "$AUTH" $BASE/api/maintain/network-detect)
check "GET /api/maintain/network-detect" 200 "$CODE"

CODE=$(curl -sk -o /dev/null -w '%{http_code}' -H "$AUTH" -H 'Content-Type: application/json' \
  -X POST $BASE/api/maintain/network-detect \
  -d '{"target_ip":"127.0.0.1"}')
check "POST /api/maintain/network-detect" 200 "$CODE"

CODE=$(curl -sk -o /dev/null -w '%{http_code}' -H "$AUTH" $BASE/api/maintain/tasks)
check "GET /api/maintain/tasks" 200 "$CODE"

# 6. Auth guard test
echo ""
echo "--- Auth Guard ---"
CODE=$(curl -sk -o /dev/null -w '%{http_code}' $BASE/api/cluster/status)
check "No token → 401" 401 "$CODE"

CODE=$(curl -sk -o /dev/null -w '%{http_code}' -H 'Authorization: Bearer invalid' $BASE/api/cluster/status)
check "Bad token → 401" 401 "$CODE"

CODE=$(curl -sk -o /dev/null -w '%{http_code}' $BASE/api/auth/login \
  -X POST -H 'Content-Type: application/json' \
  -d '{"username":"root","password":"wrong"}')
check "Wrong password → 401" 401 "$CODE"

# Summary
echo ""
echo "================================"
echo "=== Result: $PASS/$TOTAL passed ==="
if [ $FAIL -gt 0 ]; then
  echo "=== FAILED: $FAIL ==="
fi
echo "================================"
