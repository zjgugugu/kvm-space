#!/bin/bash
# Comprehensive MC 8444 Module Test - All endpoints
set -e

TOKEN=$(curl -sk -X POST https://localhost:8444/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"root","password":"root"}' | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])")

echo "Login: OK"
PASS=0; FAIL=0; TOTAL=0

t() {
  local method=$1 ep=$2 data=$3
  TOTAL=$((TOTAL+1))
  if [ "$method" = "GET" ]; then
    RESP=$(curl -sk -H "Authorization: Bearer $TOKEN" "https://localhost:8444/api/$ep" 2>/dev/null)
  elif [ "$method" = "POST" ]; then
    RESP=$(curl -sk -X POST -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' -d "$data" "https://localhost:8444/api/$ep" 2>/dev/null)
  elif [ "$method" = "PUT" ]; then
    RESP=$(curl -sk -X PUT -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' -d "$data" "https://localhost:8444/api/$ep" 2>/dev/null)
  elif [ "$method" = "DELETE" ]; then
    RESP=$(curl -sk -X DELETE -H "Authorization: Bearer $TOKEN" "https://localhost:8444/api/$ep" 2>/dev/null)
  fi
  IS=$(echo "$RESP" | python3 -c "import sys,json; json.load(sys.stdin); print('Y')" 2>/dev/null || echo "N")
  if [ "$IS" = "Y" ]; then
    PASS=$((PASS+1))
    echo "  OK  $method $ep"
  else
    FAIL=$((FAIL+1))
    echo "  FAIL $method $ep → $(echo "$RESP" | head -c 80)"
  fi
}

echo ""
echo "=== 1. Dashboard (5) ==="
t GET dashboard/overview
t GET dashboard/trends
t GET dashboard/user-stats
t GET dashboard/user-ranking
t GET dashboard/recent-alerts

echo ""
echo "=== 2. VMs ==="
t GET vms
t GET "vms?status=running"
t GET "vms?status=stopped"

echo ""
echo "=== 3. Hosts ==="
t GET hosts
t GET "hosts/1"

echo ""
echo "=== 4. Templates ==="
t GET templates

echo ""
echo "=== 5. Networks ==="
t GET networks
t GET networks/vswitches
t GET networks/subnets
t GET networks/security-groups

echo ""
echo "=== 6. Storage ==="
t GET storage
t GET storage/pools
t GET storage/volumes

echo ""
echo "=== 7. Users ==="
t GET users

echo ""
echo "=== 8. Events ==="
t GET events

echo ""
echo "=== 9. Alerts ==="
t GET alerts

echo ""
echo "=== 10. Specs ==="
t GET specs

echo ""
echo "=== 11. Publish Rules ==="
t GET publish-rules

echo ""
echo "=== 12. Backups ==="
t GET backups

echo ""
echo "=== 13. System ==="
t GET system/config
t GET system/license

echo ""
echo "=== 14. Stats ==="
t GET stats/overview
t GET stats/cpu
t GET stats/memory
t GET stats/storage

echo ""
echo "=== 15. Snapshot Policies ==="
t GET snapshot-policies

echo ""
echo "=== 16. Desktop Pools ==="
t GET desktop-pools

echo ""
echo "=== 17. App Management ==="
t GET apps/software-library

echo ""
echo "=== 18. Clients ==="
t GET clients

echo ""
echo "=== 19. Scaling ==="
t GET scaling

echo ""
echo "=== 20. Recycle Bin ==="
t GET recycle-bin

echo ""
echo "=== 21. File Manage ==="
t GET files

echo ""
echo "=== 22. Network Extra ==="
t GET network-extra/mac-pool
t GET network-extra/vswitches

echo ""
echo "=== 23. System Extra ==="
t GET system-extra/zombie-servers
t GET system-extra/one-click-detection

echo ""
echo "=== 24. Terminal Bindings ==="
t GET terminal-bindings

echo ""
echo "========================================="
echo "  TOTAL: $PASS passed, $FAIL failed (of $TOTAL)"
echo "========================================="
