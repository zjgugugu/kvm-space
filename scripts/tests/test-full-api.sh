#!/bin/bash
BASE="https://localhost:8444/api"
TOKEN=$(curl -sk "$BASE/auth/login" -X POST -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}' | python3 -c "import sys,json;print(json.load(sys.stdin)['token'])")

echo "=== Maintenance System Info ==="
curl -sk -H "Authorization: Bearer $TOKEN" "$BASE/maintenance/system-info" | python3 -m json.tool

echo ""
echo "=== Maintenance Services ==="  
curl -sk -H "Authorization: Bearer $TOKEN" "$BASE/maintenance/services" | python3 -m json.tool

echo ""
echo "=== System Policies ==="
curl -sk -H "Authorization: Bearer $TOKEN" "$BASE/system/policies" | python3 -c "
import sys,json
d=json.load(sys.stdin)
print('type:', type(d).__name__)
if isinstance(d, dict) and 'data' in d:
    print('data length:', len(d['data']))
    for item in d['data'][:3]:
        print(' ', item)
"

echo ""
echo "=== Stats User Login ==="
curl -sk -H "Authorization: Bearer $TOKEN" "$BASE/stats/user-login" | python3 -c "
import sys,json
d=json.load(sys.stdin)
print('type:', type(d).__name__)
if isinstance(d, dict) and 'data' in d:
    print('data length:', len(d['data']))
"

echo ""
echo "=== API Module Tests ==="
PASS=0; FAIL=0
test_api() {
  local desc="$1" url="$2" expect="$3"
  CODE=$(curl -sk -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $TOKEN" "$BASE$url")
  if [ "$CODE" = "$expect" ]; then
    PASS=$((PASS+1))
    echo "  PASS: $desc ($CODE)"
  else
    FAIL=$((FAIL+1))
    echo "  FAIL: $desc (expected $expect, got $CODE)"
  fi
}

test_api "Dashboard overview" "/dashboard/overview" "200"
test_api "VMs list" "/vms" "200"
test_api "Hosts list" "/hosts" "200"
test_api "Users list" "/users" "200"
test_api "Templates list" "/templates" "200"
test_api "Networks list" "/networks" "200"
test_api "Storage pools" "/storage/pools" "200"
test_api "Events" "/events" "200"
test_api "Specs" "/specs" "200"
test_api "Publish rules" "/publish-rules" "200"
test_api "Backups" "/backups" "200"
test_api "Alerts" "/alerts" "200"
test_api "System config" "/system/config" "200"
test_api "System policies" "/system/policies" "200"
test_api "Stats" "/stats" "200"
test_api "Stats user-login" "/stats/user-login" "200"
test_api "Stats audit" "/stats/audit" "200"
test_api "Stats usage-time" "/stats/usage-time" "200"
test_api "Stats alert-stats" "/stats/alert-stats" "200"
test_api "Desktop pools" "/desktop-pools" "200"
test_api "Clients" "/clients" "200"
test_api "Recycle bin" "/recycle-bin" "200"
test_api "Files" "/files" "200"
test_api "Scaling strategies" "/scaling/strategies" "200"
test_api "Terminal bindings" "/terminal-bindings" "200"
test_api "Network extra port-groups" "/network-extra/port-groups" "200"
test_api "System extra zombie-servers" "/system-extra/zombie-servers" "200"
test_api "Maintenance system-info" "/maintenance/system-info" "200"
test_api "Maintenance services" "/maintenance/services" "200"
test_api "Snapshot policies" "/snapshot-policies" "200"
test_api "Alert settings" "/alerts/settings" "200"
test_api "App layers" "/apps/layers" "200"
test_api "Password policy" "/system/password-policy" "200"
test_api "Access policy" "/system/access-policy" "200"
test_api "SMTP config" "/system/smtp" "200"
test_api "Reports overview" "/stats" "200"
test_api "System info" "/info" "200"

echo ""
echo "=== RESULTS: $PASS pass, $FAIL fail ==="
