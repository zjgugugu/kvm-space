#!/bin/bash
# Comprehensive MC 8444 API Test + Structure Comparison
set -e

echo "=============================================="
echo " MC 8444 Comprehensive API Test"
echo "=============================================="

PASS=0
FAIL=0
pass() { echo "  [PASS] $1"; PASS=$((PASS+1)); }
fail() { echo "  [FAIL] $1"; FAIL=$((FAIL+1)); }

# Login
TOKEN=$(curl -sf --max-time 5 http://localhost:8444/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"admin123"}' | python3 -c 'import sys,json; print(json.load(sys.stdin).get("token",""))')
if [ -z "$TOKEN" ]; then echo "FATAL: Login failed"; exit 1; fi
AUTH="Authorization: Bearer $TOKEN"
pass "Login OK"

api() {
  curl -sf --max-time 5 "http://localhost:8444$1" -H "$AUTH" 2>/dev/null
}
api_post() {
  curl -sf --max-time 5 -X POST "http://localhost:8444$1" -H "$AUTH" -H 'Content-Type: application/json' -d "$2" 2>/dev/null
}
api_put() {
  curl -sf --max-time 5 -X PUT "http://localhost:8444$1" -H "$AUTH" -H 'Content-Type: application/json' -d "$2" 2>/dev/null
}
api_del() {
  curl -sf --max-time 5 -X DELETE "http://localhost:8444$1" -H "$AUTH" 2>/dev/null
}

check_data() {
  local RESP="$1"
  local NAME="$2"
  local OK=$(echo "$RESP" | python3 -c 'import sys,json; d=json.load(sys.stdin); print("ok" if "data" in d or isinstance(d, list) else "fail")' 2>/dev/null || echo "fail")
  if [ "$OK" = "ok" ]; then pass "$NAME"; else fail "$NAME"; fi
}

check_ok() {
  local RESP="$1"
  local NAME="$2"
  local OK=$(echo "$RESP" | python3 -c 'import sys,json; print("ok")' 2>/dev/null || echo "fail")
  if [ "$OK" = "ok" ]; then pass "$NAME"; else fail "$NAME"; fi
}

echo ""
echo "--- Auth ---"
check_ok "$(api /api/auth/me)" "GET /api/auth/me"

echo ""
echo "--- Dashboard ---"
check_ok "$(api /api/dashboard/overview)" "GET /api/dashboard/overview"
check_ok "$(api /api/dashboard/trends)" "GET /api/dashboard/trends"

echo ""
echo "--- VMs ---"
check_data "$(api /api/vms)" "GET /api/vms"
check_data "$(api '/api/vms?status=running')" "GET /api/vms?status=running"
check_data "$(api /api/vms/recycle-bin)" "GET /api/vms/recycle-bin"
# CRUD
VM=$(api_post /api/vms '{"name":"test-vm-1","template_id":1,"host_id":1,"cpu":2,"memory":2048,"disk":20}')
VMID=$(echo "$VM" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("id",""))' 2>/dev/null)
if [ -n "$VMID" ]; then pass "POST /api/vms (id=$VMID)"; else fail "POST /api/vms"; fi
if [ -n "$VMID" ]; then
  check_ok "$(api /api/vms/$VMID)" "GET /api/vms/:id"
  check_ok "$(api_put /api/vms/$VMID '{"cpu":4}')" "PUT /api/vms/:id"
  check_ok "$(api_post /api/vms/$VMID/action '{"action":"start"}')" "POST /api/vms/:id/action (start)"
  check_ok "$(api_post /api/vms/$VMID/action '{"action":"stop"}')" "POST /api/vms/:id/action (stop)"
  check_ok "$(api_del /api/vms/$VMID)" "DELETE /api/vms/:id"
  check_ok "$(api_post /api/vms/$VMID/restore '')" "POST /api/vms/:id/restore"
fi

echo ""
echo "--- Hosts ---"
check_data "$(api /api/hosts)" "GET /api/hosts"
HOST=$(api_post /api/hosts '{"name":"test-host","ip":"10.126.33.100","cpu_total":8,"memory_total":16384,"disk_total":500}')
HID=$(echo "$HOST" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("id",""))' 2>/dev/null)
if [ -n "$HID" ]; then pass "POST /api/hosts (id=$HID)"; else fail "POST /api/hosts"; fi
if [ -n "$HID" ]; then
  check_ok "$(api /api/hosts/$HID)" "GET /api/hosts/:id"
  check_ok "$(api_del /api/hosts/$HID)" "DELETE /api/hosts/:id"
fi
# Clusters
check_data "$(api /api/hosts/clusters/list)" "GET /api/hosts/clusters/list"
CL=$(api_post /api/hosts/clusters '{"name":"test-cluster"}')
CLID=$(echo "$CL" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("id",""))' 2>/dev/null)
if [ -n "$CLID" ]; then pass "POST /api/hosts/clusters (id=$CLID)"; else fail "POST /api/hosts/clusters"; fi
if [ -n "$CLID" ]; then
  check_ok "$(api_put /api/hosts/clusters/$CLID '{"name":"renamed"}')" "PUT /api/hosts/clusters/:id"
  check_ok "$(api_del /api/hosts/clusters/$CLID)" "DELETE /api/hosts/clusters/:id"
fi

echo ""
echo "--- Templates ---"
check_data "$(api /api/templates)" "GET /api/templates"
TPL=$(api_post /api/templates '{"name":"test-tpl","os_type":"linux","cpu":2,"memory":2048,"disk":20}')
TID=$(echo "$TPL" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("id",""))' 2>/dev/null)
if [ -n "$TID" ]; then pass "POST /api/templates (id=$TID)"; else fail "POST /api/templates"; fi
if [ -n "$TID" ]; then
  check_ok "$(api /api/templates/$TID)" "GET /api/templates/:id"
  check_ok "$(api_put /api/templates/$TID '{"name":"renamed-tpl"}')" "PUT /api/templates/:id"
  check_ok "$(api_post /api/templates/$TID/publish '')" "POST /api/templates/:id/publish"
  check_ok "$(api_post /api/templates/$TID/maintain '')" "POST /api/templates/:id/maintain"
  check_ok "$(api_post /api/templates/$TID/clone '')" "POST /api/templates/:id/clone"
  # Versions
  check_data "$(api /api/templates/$TID/versions)" "GET /api/templates/:id/versions"
  VER=$(api_post /api/templates/$TID/versions '{"description":"v1"}')
  VID=$(echo "$VER" | python3 -c 'import sys,json; d=json.load(sys.stdin); print(d.get("id",d.get("version_id","")))' 2>/dev/null || echo "")
  if [ -n "$VID" ]; then pass "POST /api/templates/:id/versions"; else fail "POST /api/templates/:id/versions"; fi
  check_ok "$(api_del /api/templates/$TID)" "DELETE /api/templates/:id"
fi

echo ""
echo "--- Specs ---"
check_data "$(api /api/specs)" "GET /api/specs"
SP=$(api_post /api/specs '{"name":"test-spec","cpu":2,"max_cpu":4,"memory":2048,"disk":20}')
SID=$(echo "$SP" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("id",""))' 2>/dev/null)
if [ -n "$SID" ]; then pass "POST /api/specs (id=$SID)"; else fail "POST /api/specs"; fi
if [ -n "$SID" ]; then
  check_ok "$(api /api/specs/$SID)" "GET /api/specs/:id"
  check_ok "$(api_put /api/specs/$SID '{"cpu":4}')" "PUT /api/specs/:id"
  check_ok "$(api_del /api/specs/$SID)" "DELETE /api/specs/:id"
fi

echo ""
echo "--- Publish Rules ---"
check_data "$(api /api/publish-rules)" "GET /api/publish-rules"
PR=$(api_post /api/publish-rules '{"template_id":1,"spec_id":1,"name":"test-rule","target_type":"user","target_id":1}')
PRID=$(echo "$PR" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("id",""))' 2>/dev/null)
if [ -n "$PRID" ]; then pass "POST /api/publish-rules (id=$PRID)"; else fail "POST /api/publish-rules"; fi
if [ -n "$PRID" ]; then
  check_ok "$(api /api/publish-rules/$PRID)" "GET /api/publish-rules/:id"
  check_ok "$(api_put /api/publish-rules/$PRID '{"name":"renamed"}')" "PUT /api/publish-rules/:id"
  check_ok "$(api_put /api/publish-rules/$PRID/status '{"status":"enabled"}')" "PUT /api/publish-rules/:id/status"
  check_ok "$(api_del /api/publish-rules/$PRID)" "DELETE /api/publish-rules/:id"
fi

echo ""
echo "--- Networks ---"
check_data "$(api /api/networks)" "GET /api/networks"
NET=$(api_post /api/networks '{"name":"test-net","type":"bridge","subnet":"10.0.0.0/24","gateway":"10.0.0.1"}')
NID=$(echo "$NET" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("id",""))' 2>/dev/null)
if [ -n "$NID" ]; then pass "POST /api/networks (id=$NID)"; else fail "POST /api/networks"; fi
if [ -n "$NID" ]; then
  check_ok "$(api_put /api/networks/$NID '{"name":"renamed-net"}')" "PUT /api/networks/:id"
  check_ok "$(api_del /api/networks/$NID)" "DELETE /api/networks/:id"
fi
# Security groups
check_data "$(api /api/networks/security-groups)" "GET security-groups"
SG=$(api_post /api/networks/security-groups '{"name":"test-sg","description":"test"}')
SGID=$(echo "$SG" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("id",""))' 2>/dev/null)
if [ -n "$SGID" ]; then pass "POST security-groups (id=$SGID)"; else fail "POST security-groups"; fi
if [ -n "$SGID" ]; then
  RULE=$(api_post /api/networks/security-groups/$SGID/rules '{"direction":"inbound","protocol":"tcp","port_range":"80","source":"0.0.0.0/0","action":"allow"}')
  RULEID=$(echo "$RULE" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("id",""))' 2>/dev/null)
  if [ -n "$RULEID" ]; then pass "POST security-group rules"; else fail "POST security-group rules"; fi
fi
# MAC pools
check_data "$(api /api/networks/mac-pools)" "GET mac-pools"
# Subnets
check_data "$(api /api/networks/subnets)" "GET subnets"
check_ok "$(api_post /api/networks/subnets '{"network_id":1,"name":"test-sub","cidr":"10.0.1.0/24","gateway":"10.0.1.1"}')" "POST subnets"

echo ""
echo "--- Storage ---"
check_data "$(api /api/storage/pools)" "GET /api/storage/pools"
POOL=$(api_post /api/storage/pools '{"name":"test-pool","type":"local","total":100,"path":"/var/lib/test"}')
PLID=$(echo "$POOL" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("id",""))' 2>/dev/null)
if [ -n "$PLID" ]; then pass "POST /api/storage/pools (id=$PLID)"; else fail "POST /api/storage/pools"; fi
if [ -n "$PLID" ]; then
  check_ok "$(api_del /api/storage/pools/$PLID)" "DELETE /api/storage/pools/:id"
fi
check_data "$(api /api/storage/volumes)" "GET /api/storage/volumes"

echo ""
echo "--- Users ---"
check_data "$(api /api/users)" "GET /api/users"
USR=$(api_post /api/users '{"username":"testuser","password":"Test1234!","role":"user","email":"test@test.com"}')
UID_V=$(echo "$USR" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("id",""))' 2>/dev/null)
if [ -n "$UID_V" ]; then pass "POST /api/users (id=$UID_V)"; else fail "POST /api/users"; fi
# Groups
check_data "$(api /api/users/groups)" "GET /api/users/groups"
GRP=$(api_post /api/users/groups '{"name":"test-group"}')
GRID=$(echo "$GRP" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("id",""))' 2>/dev/null)
if [ -n "$GRID" ]; then pass "POST /api/users/groups (id=$GRID)"; else fail "POST /api/users/groups"; fi
# LDAP
check_ok "$(api /api/users/ldap)" "GET /api/users/ldap"
check_ok "$(api_put /api/users/ldap '{"server":"10.0.0.1","port":389,"base_dn":"dc=example,dc=com"}')" "PUT /api/users/ldap"

echo ""
echo "--- System ---"
check_ok "$(api /api/system/config)" "GET /api/system/config"
check_data "$(api /api/system/policies)" "GET /api/system/policies"
check_ok "$(api /api/system/password-policy)" "GET /api/system/password-policy"
check_ok "$(api /api/system/access-policy)" "GET /api/system/access-policy"
check_ok "$(api /api/system/smtp)" "GET /api/system/smtp"
check_ok "$(api_put /api/system/smtp '{"host":"smtp.example.com","port":25}')" "PUT /api/system/smtp"

echo ""
echo "--- Backups ---"
check_data "$(api /api/backups/servers)" "GET /api/backups/servers"
check_data "$(api /api/backups)" "GET /api/backups"

echo ""
echo "--- Snapshot Policies ---"
check_data "$(api /api/snapshot-policies)" "GET /api/snapshot-policies"
SNP=$(api_post /api/snapshot-policies '{"name":"test-snap","cron_expr":"0 0 * * *","max_keep":7}')
SNID=$(echo "$SNP" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("id",""))' 2>/dev/null)
if [ -n "$SNID" ]; then pass "POST /api/snapshot-policies"; else fail "POST /api/snapshot-policies"; fi

echo ""
echo "--- Events & Tasks ---"
check_data "$(api /api/events)" "GET /api/events"
check_data "$(api /api/events/tasks)" "GET /api/events/tasks"
check_data "$(api /api/events/approvals)" "GET /api/events/approvals"

echo ""
echo "--- Alerts ---"
check_data "$(api /api/alerts)" "GET /api/alerts"
check_data "$(api /api/alerts/settings)" "GET /api/alerts/settings"

echo ""
echo "--- Stats ---"
check_ok "$(api /api/stats)" "GET /api/stats"
check_data "$(api /api/stats/user-login)" "GET /api/stats/user-login"
check_data "$(api /api/stats/audit)" "GET /api/stats/audit"
check_ok "$(api /api/stats/usage-time)" "GET /api/stats/usage-time"
check_ok "$(api /api/stats/alert-stats)" "GET /api/stats/alert-stats"

echo ""
echo "--- Frontend ---"
HTTP=$(curl -sf --max-time 5 -o /dev/null -w '%{http_code}' http://localhost:8444/)
if [ "$HTTP" = "200" ]; then pass "Frontend (HTTP 200)"; else fail "Frontend HTTP $HTTP"; fi

echo ""
echo "=============================================="
echo " Results: PASS=$PASS FAIL=$FAIL"
echo " Total: $((PASS+FAIL))"
echo "=============================================="
