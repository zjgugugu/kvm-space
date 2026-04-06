#!/bin/bash
BASE="https://localhost:8444"
TOKEN=$(curl -sk -X POST "$BASE/api/auth/login" -H "Content-Type: application/json" -d '{"username":"admin","password":"admin123"}' | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
[ -z "$TOKEN" ] && echo "LOGIN FAILED" && exit 1
echo "Login OK"
PASS=0; FAIL=0
test_api() {
  CODE=$(curl -sk -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $TOKEN" "$BASE$1")
  if [ "$CODE" = "200" ]; then PASS=$((PASS+1)); echo "PASS $1"
  else FAIL=$((FAIL+1)); echo "FAIL $1 ($CODE)"; fi
}
for ep in /api/dashboard/overview /api/dashboard/trends /api/dashboard/user-stats /api/dashboard/user-ranking /api/dashboard/recent-alerts /api/vms /api/hosts /api/users /api/networks /api/templates /api/events /api/storage/pools /api/alerts /api/alerts/settings /api/backups /api/backups/servers /api/snapshot-policies /api/specs /api/publish-rules /api/desktop-pools /api/clients /api/recycle-bin /api/files /api/tasks /api/system/config /api/system/policies /api/stats /api/stats/user-login /api/stats/audit /api/stats/usage-time /api/stats/alert-stats /api/maintenance/system-info /api/maintenance/services /api/network-extra/port-groups /api/network-extra/subnets /api/system-extra/ha /api/system-extra/drs /api/scaling/groups /api/scaling/strategies /api/terminal-bindings /api/info; do
  test_api "$ep"
done
echo ""; echo "RESULT: $PASS pass, $FAIL fail"