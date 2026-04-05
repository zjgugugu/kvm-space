#!/bin/bash
# Comprehensive API test for KVM Cloud
BASE="http://localhost:8444"
PASS=0
FAIL=0
TOTAL=0

test_api() {
  local method=$1
  local path=$2
  local data=$3
  local desc=$4
  TOTAL=$((TOTAL+1))
  
  if [ "$method" = "GET" ]; then
    CODE=$(curl -s -o /dev/null -w "%{http_code}" "$BASE$path" -H "Authorization: Bearer $TOKEN")
  elif [ "$method" = "POST" ]; then
    CODE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE$path" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d "$data")
  elif [ "$method" = "PUT" ]; then
    CODE=$(curl -s -o /dev/null -w "%{http_code}" -X PUT "$BASE$path" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d "$data")
  elif [ "$method" = "DELETE" ]; then
    CODE=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE "$BASE$path" -H "Authorization: Bearer $TOKEN")
  fi
  
  if [ "$CODE" = "200" ] || [ "$CODE" = "201" ]; then
    PASS=$((PASS+1))
    echo "  [PASS] $method $path - $desc ($CODE)"
  else
    FAIL=$((FAIL+1))
    echo "  [FAIL] $method $path - $desc ($CODE)"
  fi
}

echo "========================================="
echo "  KVM Cloud API Comprehensive Test"
echo "========================================="

# Login
echo ""
echo "--- AUTH ---"
RESP=$(curl -s -X POST "$BASE/api/auth/login" -H "Content-Type: application/json" -d '{"username":"admin","password":"admin123"}')
TOKEN=$(echo $RESP | python -c "import sys,json; print(json.load(sys.stdin)['token'])" 2>/dev/null)
if [ -n "$TOKEN" ]; then
  echo "  [PASS] Login successful"
  PASS=$((PASS+1))
else
  echo "  [FAIL] Login failed"
  FAIL=$((FAIL+1))
fi
TOTAL=$((TOTAL+1))

test_api GET "/api/auth/me" "" "Get current user"
test_api PUT "/api/auth/password" '{"old_password":"admin123","new_password":"admin123"}' "Change password"

# Dashboard
echo ""
echo "--- DASHBOARD ---"
test_api GET "/api/dashboard/overview" "" "Dashboard overview"
test_api GET "/api/dashboard/trends" "" "Dashboard trends"
test_api GET "/api/dashboard/user-stats" "" "User statistics"
test_api GET "/api/dashboard/user-ranking" "" "User ranking"
test_api GET "/api/dashboard/recent-alerts" "" "Recent alerts"

# VMs
echo ""
echo "--- VMS ---"
test_api GET "/api/vms" "" "List VMs"
test_api GET "/api/vms/recycle-bin" "" "Recycle bin"

# Create a VM
VM_RESP=$(curl -s -X POST "$BASE/api/vms" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d '{"name":"test-vm-01","cpu":2,"memory":2048,"disk":40,"os_type":"linux","owner":"testuser"}')
VM_ID=$(echo $VM_RESP | python -c "import sys,json; print(json.load(sys.stdin).get('id',''))" 2>/dev/null)
if [ -n "$VM_ID" ] && [ "$VM_ID" != "" ]; then
  echo "  [PASS] POST /api/vms - Create VM (id=$VM_ID)"
  PASS=$((PASS+1))
else
  echo "  [FAIL] POST /api/vms - Create VM"
  FAIL=$((FAIL+1))
  VM_ID="nonexistent"
fi
TOTAL=$((TOTAL+1))

test_api GET "/api/vms/$VM_ID" "" "Get VM detail"
test_api PUT "/api/vms/$VM_ID" '{"cpu":4,"memory":4096}' "Edit VM"
test_api GET "/api/vms/$VM_ID/stats" "" "VM stats"

# VM Snapshots
SNAP_RESP=$(curl -s -X POST "$BASE/api/vms/$VM_ID/snapshots" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d '{"name":"test-snapshot"}')
SNAP_ID=$(echo $SNAP_RESP | python -c "import sys,json; print(json.load(sys.stdin).get('id',''))" 2>/dev/null)
if [ -n "$SNAP_ID" ]; then
  echo "  [PASS] POST /api/vms/$VM_ID/snapshots - Create snapshot"
  PASS=$((PASS+1))
else
  echo "  [FAIL] POST /api/vms/$VM_ID/snapshots - Create snapshot"
  FAIL=$((FAIL+1))
fi
TOTAL=$((TOTAL+1))

test_api GET "/api/vms/$VM_ID/snapshots" "" "List snapshots"

# VM Disks & NICs
test_api POST "/api/vms/$VM_ID/disks" '{"size":20,"type":"data"}' "Add disk"
test_api POST "/api/vms/$VM_ID/nics" '{"network_id":"test"}' "Add NIC"

# Hosts
echo ""
echo "--- HOSTS ---"
test_api GET "/api/hosts" "" "List hosts"
HOST_RESP=$(curl -s "$BASE/api/hosts" -H "Authorization: Bearer $TOKEN")
HOST_ID=$(echo $HOST_RESP | python -c "import sys,json; d=json.load(sys.stdin); print(d['data'][0]['id'] if d.get('data') else '')" 2>/dev/null)
if [ -n "$HOST_ID" ]; then
  test_api GET "/api/hosts/$HOST_ID" "" "Get host detail"
  test_api GET "/api/hosts/$HOST_ID/stats" "" "Host stats"
fi
test_api GET "/api/hosts/clusters/list" "" "List clusters"
test_api POST "/api/hosts/clusters" '{"name":"test-cluster"}' "Create cluster"

# Templates
echo ""
echo "--- TEMPLATES ---"
test_api GET "/api/templates" "" "List templates"
TPL_RESP=$(curl -s -X POST "$BASE/api/templates" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d '{"name":"test-template","os_type":"linux","os_version":"CentOS 8"}')
TPL_ID=$(echo $TPL_RESP | python -c "import sys,json; print(json.load(sys.stdin).get('id',''))" 2>/dev/null)
if [ -n "$TPL_ID" ]; then
  echo "  [PASS] POST /api/templates - Create template"
  PASS=$((PASS+1))
  test_api GET "/api/templates/$TPL_ID" "" "Get template detail"
  test_api PUT "/api/templates/$TPL_ID" '{"title":"Test Template"}' "Edit template"
  test_api POST "/api/templates/$TPL_ID/publish" '' "Publish template"
  test_api POST "/api/templates/$TPL_ID/maintain" '' "Maintain template"
  test_api GET "/api/templates/$TPL_ID/versions" "" "List versions"
else
  echo "  [FAIL] POST /api/templates - Create template"
  FAIL=$((FAIL+1))
fi
TOTAL=$((TOTAL+1))

# Networks
echo ""
echo "--- NETWORKS ---"
test_api GET "/api/networks" "" "List networks"
test_api POST "/api/networks" '{"name":"test-net","type":"bridge","bridge":"br-test"}' "Create network"
test_api GET "/api/networks/security-groups" "" "List security groups"
test_api POST "/api/networks/security-groups" '{"name":"test-sg"}' "Create security group"
test_api GET "/api/networks/mac-pools" "" "List MAC pools"
test_api GET "/api/networks/subnets" "" "List subnets"

# Storage
echo ""
echo "--- STORAGE ---"
test_api GET "/api/storage/pools" "" "List storage pools"
test_api POST "/api/storage/pools" '{"name":"test-pool","type":"local","total":100,"path":"/tmp/test-pool"}' "Create storage pool"
test_api GET "/api/storage/volumes" "" "List volumes"
test_api GET "/api/storage/alerts" "" "Storage alerts"
test_api POST "/api/storage/health-check" '' "Health check"

# Users
echo ""
echo "--- USERS ---"
test_api GET "/api/users" "" "List users"
test_api POST "/api/users" '{"username":"testuser1","password":"Test@1234","role":"user","display_name":"测试用户"}' "Create user"
test_api GET "/api/users/groups" "" "List user groups"
test_api POST "/api/users/groups" '{"name":"测试部门"}' "Create user group"
test_api GET "/api/users/ldap" "" "Get LDAP config"

# Specs
echo ""
echo "--- SPECS ---"
test_api GET "/api/specs" "" "List desktop specs"
test_api POST "/api/specs" '{"name":"test-spec","cpu":2,"memory":4096,"system_disk":40}' "Create spec"

# Publish Rules
echo ""
echo "--- PUBLISH RULES ---"
test_api GET "/api/publish-rules" "" "List publish rules"

# Events
echo ""
echo "--- EVENTS ---"
test_api GET "/api/events" "" "List events"
test_api GET "/api/events/tasks" "" "List tasks"
test_api GET "/api/events/approvals" "" "List approvals"

# Alerts
echo ""
echo "--- ALERTS ---"
test_api GET "/api/alerts" "" "List alerts"
test_api GET "/api/alerts/settings" "" "List alert settings"

# System
echo ""
echo "--- SYSTEM ---"
test_api GET "/api/system/config" "" "System config"
test_api GET "/api/system/policies" "" "Global policies"
test_api GET "/api/system/password-policy" "" "Password policy"
test_api GET "/api/system/access-policy" "" "Access policy"
test_api GET "/api/system/smtp" "" "SMTP config"

# Stats
echo ""
echo "--- STATS ---"
test_api GET "/api/stats" "" "Platform stats"
test_api GET "/api/stats/user-login" "" "User login stats"
test_api GET "/api/stats/audit" "" "Audit logs"
test_api GET "/api/stats/usage-time" "" "Usage time"
test_api GET "/api/stats/alert-stats" "" "Alert stats"

# Backups
echo ""
echo "--- BACKUPS ---"
test_api GET "/api/backups" "" "List backups"
test_api GET "/api/backups/servers" "" "List backup servers"

# Snapshot Policies
echo ""
echo "--- SNAPSHOT POLICIES ---"
test_api GET "/api/snapshot-policies" "" "List snapshot policies"

# Cleanup: Delete test VM
if [ "$VM_ID" != "nonexistent" ]; then
  test_api DELETE "/api/vms/$VM_ID" "" "Delete VM (soft)"
fi

# Frontend
echo ""
echo "--- FRONTEND ---"
FCODE=$(curl -s -o /dev/null -w "%{http_code}" "$BASE/")
TOTAL=$((TOTAL+1))
if [ "$FCODE" = "200" ]; then
  echo "  [PASS] GET / - Frontend served ($FCODE)"
  PASS=$((PASS+1))
else
  echo "  [FAIL] GET / - Frontend ($FCODE)"
  FAIL=$((FAIL+1))
fi

JSCODE=$(curl -s -o /dev/null -w "%{http_code}" "$BASE/assets/index-D5fw03LZ.js")
TOTAL=$((TOTAL+1))
if [ "$JSCODE" = "200" ]; then
  echo "  [PASS] GET /assets/index-*.js - JS bundle ($JSCODE)"
  PASS=$((PASS+1))
else
  echo "  [FAIL] GET /assets/index-*.js - JS bundle ($JSCODE)"
  FAIL=$((FAIL+1))
fi

echo ""
echo "========================================="
echo "  RESULTS: $PASS/$TOTAL passed, $FAIL failed"
echo "========================================="
