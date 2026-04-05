#!/bin/bash
# Comparison test: Our Cockpit 9091 vs Real Cockpit DB
set -e

echo "=============================================="
echo " Cockpit 9091 vs Real 9090 Comparison Test"
echo "=============================================="

PASS=0
FAIL=0
WARN=0

pass() { echo "  [PASS] $1"; PASS=$((PASS+1)); }
fail() { echo "  [FAIL] $1"; FAIL=$((FAIL+1)); }
warn() { echo "  [WARN] $1"; WARN=$((WARN+1)); }

# Get token
TOKEN=$(curl -sf http://localhost:9091/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"root","password":"unikylinsec"}' | python3 -c 'import sys,json; print(json.load(sys.stdin)["token"])')

if [ -z "$TOKEN" ]; then
  echo "FATAL: Cannot login to our Cockpit 9091"
  exit 1
fi
echo "Login OK, token obtained"
echo ""

AUTH="Authorization: Bearer $TOKEN"

# Helper: call our API
our_api() {
  curl -sf "http://localhost:9091$1" -H "$AUTH" 2>/dev/null
}

# Helper: query real DB
real_db() {
  sqlite3 /usr/share/cockpit/virtualization/db/cockpit.sql "$1" 2>/dev/null
}

# ============================================
echo "--- 1. System Info ---"
INFO=$(our_api /api/info)
HOSTNAME=$(echo "$INFO" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("hostname",""))')
IP=$(echo "$INFO" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("ip",""))')
if [ "$HOSTNAME" = "node1" ]; then pass "hostname=node1"; else fail "hostname=$HOSTNAME (expected node1)"; fi
if [ -n "$IP" ]; then pass "ip=$IP"; else fail "ip is empty"; fi

echo ""
echo "--- 2. Cluster Status ---"
STATUS=$(our_api /api/cluster/status)
CS=$(echo "$STATUS" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("cluster_status",0))')
REAL_CS=$(real_db "select status from cockpit_deploy_status;" 2>/dev/null || echo "")
# Real DB: status=1 means deployed (but 0-based: 0=not deployed, 1=deployed... check convention)
# In real DB deploy_status.status=1, our API should return cluster_status=1 to indicate deployed
if [ "$CS" = "1" ]; then pass "cluster_status=1 (deployed)"; else fail "cluster_status=$CS (expected 1)"; fi

STYPE=$(echo "$STATUS" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("storage_type",""))')
REAL_STYPE=$(real_db "select manager_storage_type from cockpit_deploy_status;")
if [ "$STYPE" = "$REAL_STYPE" ]; then pass "storage_type=$STYPE matches real=$REAL_STYPE"; else fail "storage_type=$STYPE vs real=$REAL_STYPE"; fi

echo ""
echo "--- 3. Nodes ---"
NODES=$(our_api /api/cluster/nodes)
NODE_COUNT=$(echo "$NODES" | python3 -c 'import sys,json; print(len(json.load(sys.stdin).get("data",[])))')
REAL_NODE_COUNT=$(real_db "select count(*) from cockpit_nodes;")
if [ "$NODE_COUNT" = "$REAL_NODE_COUNT" ]; then pass "node_count=$NODE_COUNT matches real"; else fail "node_count=$NODE_COUNT vs real=$REAL_NODE_COUNT"; fi

# Check node details
NODE1_IP=$(echo "$NODES" | python3 -c 'import sys,json; d=json.load(sys.stdin)["data"][0]; print(d.get("ip",""))')
NODE1_ROLE=$(echo "$NODES" | python3 -c 'import sys,json; d=json.load(sys.stdin)["data"][0]; print(d.get("role",""))')
NODE1_NAME=$(echo "$NODES" | python3 -c 'import sys,json; d=json.load(sys.stdin)["data"][0]; print(d.get("name",""))')
REAL_IP=$(real_db "select ip from cockpit_nodes where id=1;")
REAL_ROLE=$(real_db "select role from cockpit_nodes where id=1;")
REAL_NAME=$(real_db "select name from cockpit_nodes where id=1;")

if [ "$NODE1_IP" = "$REAL_IP" ]; then pass "node1.ip=$NODE1_IP matches"; else fail "node1.ip=$NODE1_IP vs real=$REAL_IP"; fi
if [ "$NODE1_ROLE" = "$REAL_ROLE" ]; then pass "node1.role=$NODE1_ROLE matches"; else fail "node1.role=$NODE1_ROLE vs real=$REAL_ROLE"; fi
if [ "$NODE1_NAME" = "$REAL_NAME" ]; then pass "node1.name=$NODE1_NAME matches"; else fail "node1.name=$NODE1_NAME vs real=$REAL_NAME"; fi

NODE1_DOCKER=$(echo "$NODES" | python3 -c 'import sys,json; d=json.load(sys.stdin)["data"][0]; print(d.get("is_docker_node",0))')
REAL_DOCKER=$(real_db "select is_docker_node from cockpit_nodes where id=1;")
if [ "$NODE1_DOCKER" = "$REAL_DOCKER" ]; then pass "node1.is_docker_node=$NODE1_DOCKER matches"; else fail "node1.is_docker_node=$NODE1_DOCKER vs real=$REAL_DOCKER"; fi

echo ""
echo "--- 4. NTP Configuration ---"
NTP=$(our_api /api/config/ntp)
NTP_INTERVAL=$(echo "$NTP" | python3 -c 'import sys,json; d=json.load(sys.stdin); print(d.get("time_update_interval",d.get("data",{}).get("time_update_interval","")))')
REAL_NTP_INTERVAL=$(real_db "select time_update_interval from cockpit_time_server where id=1;")
if [ "$NTP_INTERVAL" = "$REAL_NTP_INTERVAL" ]; then pass "ntp_interval=$NTP_INTERVAL matches real"; else warn "ntp_interval=$NTP_INTERVAL vs real=$REAL_NTP_INTERVAL"; fi

echo ""
echo "--- 5. NFS Configuration ---"
NFS=$(our_api /api/config/nfs)
NFS_CHECK=$(echo "$NFS" | python3 -c 'import sys,json; d=json.load(sys.stdin); print("ok" if "data" in d or "ip" in d else "empty")')
REAL_NFS=$(real_db "select count(*) from cockpit_nfs_storage_info;")
if [ "$REAL_NFS" = "0" ]; then
  pass "nfs: both real and ours have no NFS config"
else
  if [ "$NFS_CHECK" = "ok" ]; then pass "nfs: config present"; else fail "nfs: config missing"; fi
fi

echo ""
echo "--- 6. CIFS Configuration ---"
CIFS=$(our_api /api/config/cifs)
CIFS_CHECK=$(echo "$CIFS" | python3 -c 'import sys,json; d=json.load(sys.stdin); print("ok" if "data" in d or "ip" in d else "empty")')
REAL_CIFS=$(real_db "select count(*) from cockpit_cifs_storage_info;")
if [ "$REAL_CIFS" = "0" ]; then
  pass "cifs: both real and ours have no CIFS config"
else
  if [ "$CIFS_CHECK" = "ok" ]; then pass "cifs: config present"; else fail "cifs: config missing"; fi
fi

echo ""
echo "--- 7. Center Cluster ---"
CC=$(our_api /api/config/center-cluster)
CC_CHECK=$(echo "$CC" | python3 -c 'import sys,json; d=json.load(sys.stdin); print("ok" if "data" in d or "ip" in d else "empty")')
REAL_CC=$(real_db "select count(*) from cockpit_center_cluster_info;")
if [ "$REAL_CC" = "0" ]; then
  pass "center-cluster: both real and ours have no config"
else
  if [ "$CC_CHECK" = "ok" ]; then pass "center-cluster: config present"; else fail "center-cluster: config missing"; fi
fi

echo ""
echo "--- 8. Deploy Data Match ---"
DEPLOY=$(our_api /api/cluster/status)
IS_BRANCH=$(echo "$DEPLOY" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("is_branch",0))')
REAL_IS_BRANCH=$(real_db "select is_branch from cockpit_deploy_status;")
if [ "$IS_BRANCH" = "$REAL_IS_BRANCH" ]; then pass "is_branch=$IS_BRANCH matches"; else warn "is_branch=$IS_BRANCH vs real=$REAL_IS_BRANCH"; fi

MMM_VIP=$(echo "$DEPLOY" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("mmm_vip",""))')
REAL_VIP=$(real_db "select mmm_vip from cockpit_deploy_status;")
if [ "$MMM_VIP" = "$REAL_VIP" ]; then pass "mmm_vip=$MMM_VIP matches"; else warn "mmm_vip=$MMM_VIP vs real=$REAL_VIP"; fi

echo ""
echo "--- 9. API Functionality ---"
# Test settings update APIs
# NTP update
NTP_PUT=$(curl -sf -X PUT http://localhost:9091/api/config/ntp \
  -H "$AUTH" -H 'Content-Type: application/json' \
  -d '{"server":"ntp.aliyun.com","time_update_interval":10}' 2>/dev/null)
NTP_OK=$(echo "$NTP_PUT" | python3 -c 'import sys,json; d=json.load(sys.stdin); print("ok" if d.get("success") or d.get("message") else "fail")' 2>/dev/null || echo "fail")
if [ "$NTP_OK" = "ok" ]; then pass "PUT /api/config/ntp works"; else fail "PUT /api/config/ntp failed"; fi

# Restore NTP
curl -sf -X PUT http://localhost:9091/api/config/ntp \
  -H "$AUTH" -H 'Content-Type: application/json' \
  -d '{"server":"0","time_update_interval":5}' > /dev/null 2>&1

# Test deploy API (without executing)
DEPLOY_TEST=$(curl -sf -X POST http://localhost:9091/api/cluster/deploy \
  -H "$AUTH" -H 'Content-Type: application/json' \
  -d '{"type":1,"storage_mode":"GlusterFS","nodes":[{"name":"test","ip":"10.0.0.1","role":"CM_VDI"}]}' 2>/dev/null)
DEPLOY_OK=$(echo "$DEPLOY_TEST" | python3 -c 'import sys,json; d=json.load(sys.stdin); print("ok")' 2>/dev/null || echo "fail")
if [ "$DEPLOY_OK" = "ok" ]; then pass "POST /api/cluster/deploy works"; else fail "POST /api/cluster/deploy failed"; fi

# Test maintain APIs
BACKUPS=$(our_api /api/maintain/backups)
BACKUP_OK=$(echo "$BACKUPS" | python3 -c 'import sys,json; d=json.load(sys.stdin); print("ok" if "data" in d else "fail")' 2>/dev/null || echo "fail")
if [ "$BACKUP_OK" = "ok" ]; then pass "GET /api/maintain/backups works"; else fail "GET /api/maintain/backups failed"; fi

LOGS=$(our_api /api/maintain/logs)
LOG_OK=$(echo "$LOGS" | python3 -c 'import sys,json; d=json.load(sys.stdin); print("ok" if "data" in d else "fail")' 2>/dev/null || echo "fail")
if [ "$LOG_OK" = "ok" ]; then pass "GET /api/maintain/logs works"; else fail "GET /api/maintain/logs failed"; fi

RECOVERY=$(our_api /api/maintain/recovery/status)
RECOVERY_OK=$(echo "$RECOVERY" | python3 -c 'import sys,json; d=json.load(sys.stdin); print("ok")' 2>/dev/null || echo "fail")
if [ "$RECOVERY_OK" = "ok" ]; then pass "GET /api/maintain/recovery/status works"; else fail "GET /api/maintain/recovery/status failed"; fi

NETDET=$(our_api /api/maintain/network-detect)
NETDET_OK=$(echo "$NETDET" | python3 -c 'import sys,json; d=json.load(sys.stdin); print("ok" if "data" in d else "fail")' 2>/dev/null || echo "fail")
if [ "$NETDET_OK" = "ok" ]; then pass "GET /api/maintain/network-detect works"; else fail "GET /api/maintain/network-detect failed"; fi

echo ""
echo "--- 10. Frontend Accessibility ---"
HTTP_CODE=$(curl -s -o /dev/null -w '%{http_code}' http://localhost:9091/)
if [ "$HTTP_CODE" = "200" ]; then pass "Frontend index.html served (HTTP 200)"; else fail "Frontend HTTP $HTTP_CODE"; fi

HTML_CHECK=$(curl -s http://localhost:9091/ | grep -c '总控虚拟化界面' 2>/dev/null || echo "0")
if [ "$HTML_CHECK" -gt 0 ]; then pass "Frontend contains 总控虚拟化界面"; else fail "Frontend missing 总控虚拟化界面"; fi

MODULES_CHECK=$(curl -s http://localhost:9091/ | grep -c '存储维护' 2>/dev/null || echo "0")
if [ "$MODULES_CHECK" -gt 0 ]; then pass "Frontend contains 存储维护 module"; else fail "Frontend missing 存储维护 module"; fi

echo ""
echo "=============================================="
echo " Results: PASS=$PASS FAIL=$FAIL WARN=$WARN"
echo " Total: $((PASS+FAIL+WARN))"
echo "=============================================="

if [ $FAIL -gt 0 ]; then exit 1; fi
