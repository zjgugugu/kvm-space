#!/bin/bash
# MC 8444 Dashboard comparison test
# Compare our MC dashboard APIs with what the real system provides
set -e

echo "========================================="
echo "  MC 8444 vs 8443 Dashboard Comparison"
echo "========================================="

# --- Login to our MC 8444 ---
OUR_TOKEN=$(curl -sk -X POST https://localhost:8444/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"root","password":"root"}' 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin).get('token',''))" 2>/dev/null)

if [ -z "$OUR_TOKEN" ]; then
  echo "FAIL: Our MC 8444 login failed"
  exit 1
fi
echo "Our MC 8444 login: OK"

# --- Login to real MC 8443 ---
REAL_RESP=$(curl -sk -X POST https://localhost:8443/mc/login \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d 'username=mcadmin&password=987qwe654asd*' \
  -c /tmp/mc-cookies.txt -D /tmp/mc-headers.txt -L 2>/dev/null)

REAL_TOKEN=$(grep -i 'set-cookie' /tmp/mc-headers.txt 2>/dev/null | head -1 || echo "none")
echo "Real MC 8443 login cookie: $REAL_TOKEN"

# --- Our Dashboard APIs ---
echo ""
echo "=== OUR MC 8444 Dashboard APIs ==="
for endpoint in dashboard/overview dashboard/stats dashboard/summary dashboard/host-stats dashboard/vm-stats; do
  RESP=$(curl -sk -H "Authorization: Bearer $OUR_TOKEN" https://localhost:8444/api/$endpoint 2>/dev/null)
  IS_JSON=$(echo "$RESP" | python3 -c "import sys,json; json.load(sys.stdin); print('JSON')" 2>/dev/null || echo "NOT_JSON")
  echo "  $endpoint: [$IS_JSON] $(echo "$RESP" | head -c 200)"
done

echo ""
echo "=== OUR Dashboard Full Data ==="
echo "--- dashboard/overview ---"
curl -sk -H "Authorization: Bearer $OUR_TOKEN" https://localhost:8444/api/dashboard/overview 2>/dev/null | python3 -m json.tool 2>/dev/null
echo ""
echo "--- dashboard/stats ---"
curl -sk -H "Authorization: Bearer $OUR_TOKEN" https://localhost:8444/api/dashboard/stats 2>/dev/null | python3 -m json.tool 2>/dev/null

# --- Real MC Dashboard Pages ---
echo ""
echo "=== REAL MC 8443 Dashboard APIs ==="
# Try to access dashboard-like pages
for path in mc/api/dashboard mc/serverVirtual/serverVirtualMain mc/dashboard/index mc/api/v1/dashboard mc/cloud/summary; do
  STATUS=$(curl -sk -o /dev/null -w "%{http_code}" -b /tmp/mc-cookies.txt https://localhost:8443/$path)
  echo "  /$path: HTTP $STATUS"
done

# Try specific real MC API endpoints
echo ""
echo "=== REAL MC 8443 Known API Patterns ==="
for path in "mc/api/serverVirtual/getServerList" "mc/api/serverVirtual/getOverview" "mc/desktop/getDesktopStatus" "mc/api/host/list" "mc/api/vm/list"; do
  RESP=$(curl -sk -b /tmp/mc-cookies.txt https://localhost:8443/$path 2>/dev/null)
  STATUS=$(curl -sk -o /dev/null -w "%{http_code}" -b /tmp/mc-cookies.txt https://localhost:8443/$path 2>/dev/null)
  echo "  /$path: HTTP $STATUS → $(echo "$RESP" | head -c 150)"
done

# --- Check our host & VM data ---
echo ""
echo "=== OUR MC 8444 Hosts & VMs (for Dashboard) ==="
echo "--- hosts ---"
curl -sk -H "Authorization: Bearer $OUR_TOKEN" https://localhost:8444/api/hosts 2>/dev/null | python3 -m json.tool 2>/dev/null | head -30
echo ""
echo "--- vms ---"
curl -sk -H "Authorization: Bearer $OUR_TOKEN" https://localhost:8444/api/vms 2>/dev/null | python3 -m json.tool 2>/dev/null | head -30
echo ""
echo "--- events (recent) ---"
curl -sk -H "Authorization: Bearer $OUR_TOKEN" https://localhost:8444/api/events 2>/dev/null | python3 -m json.tool 2>/dev/null | head -20
echo ""
echo "--- alerts ---"
curl -sk -H "Authorization: Bearer $OUR_TOKEN" https://localhost:8444/api/alerts 2>/dev/null | python3 -m json.tool 2>/dev/null | head -20

echo ""
echo "========================================="
echo "  Dashboard Comparison Complete"
echo "========================================="
