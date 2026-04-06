#!/bin/bash
# Test Cockpit 9091 vs Real 9090 comparison
set -e

echo "========================================="
echo "  Cockpit 9091 vs 9090 Comparison Test"
echo "========================================="

# --- Test 1: Our Cockpit 9091 Login ---
echo ""
echo "=== TEST 1: Our Cockpit 9091 Login ==="
TOKEN=$(curl -sk -X POST https://localhost:9091/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"root","password":"root"}' 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('token','FAIL'))" 2>/dev/null)

if [ "$TOKEN" = "FAIL" ] || [ -z "$TOKEN" ]; then
  echo "FAIL: Login failed"
  # Try to see raw response
  curl -sk -X POST https://localhost:9091/api/auth/login \
    -H 'Content-Type: application/json' \
    -d '{"username":"root","password":"root"}'
  echo ""
else
  echo "OK: Got token (${#TOKEN} chars)"
fi

# --- Test 2: Our Cockpit 9091 API endpoints ---
echo ""
echo "=== TEST 2: Our Cockpit 9091 API Endpoints ==="
for endpoint in auth/session cluster/status cluster/nodes config/system config/network maintain/status maintain/logs; do
  STATUS=$(curl -sk -o /dev/null -w "%{http_code}" -H "Authorization: Bearer $TOKEN" https://localhost:9091/api/$endpoint)
  BODY=$(curl -sk -H "Authorization: Bearer $TOKEN" https://localhost:9091/api/$endpoint 2>/dev/null | head -c 200)
  # Check if body is JSON
  IS_JSON=$(echo "$BODY" | python3 -c "import sys,json; json.load(sys.stdin); print('JSON')" 2>/dev/null || echo "NOT_JSON")
  echo "  $endpoint: HTTP $STATUS [$IS_JSON] ${BODY:0:100}"
done

# --- Test 3: Real Cockpit 9090 - Check what it serves ---
echo ""
echo "=== TEST 3: Real Cockpit 9090 Status ==="
# Real cockpit uses cookie-based auth
COOKIE_JAR="/tmp/cockpit-cookies.txt"
rm -f $COOKIE_JAR

# Try to get the main page
REAL_STATUS=$(curl -sk -o /dev/null -w "%{http_code}" https://localhost:9090/)
echo "  Main page: HTTP $REAL_STATUS"

# Try standard cockpit login
LOGIN_RESP=$(curl -sk -X POST https://localhost:9090/cockpit/login \
  -H 'Authorization: Basic cm9vdDp1bmlreWxpbnNlYw==' \
  -c $COOKIE_JAR -D - 2>/dev/null | head -20)
echo "  Login response headers:"
echo "$LOGIN_RESP" | grep -E "^HTTP|^Set-Cookie|^Content-Type" | head -5

# Check if we got a session cookie
if grep -q cockpit $COOKIE_JAR 2>/dev/null; then
  echo "  OK: Got session cookie"
  
  # Try cockpit API
  for path in cockpit/manifests.json cockpit/@localhost/system/index.html; do
    REAL_S=$(curl -sk -o /dev/null -w "%{http_code}" -b $COOKIE_JAR https://localhost:9090/$path)
    echo "  /$path: HTTP $REAL_S"
  done
else
  echo "  No session cookie obtained"
fi

# --- Test 4: Our Cockpit Frontend ---
echo ""
echo "=== TEST 4: Our Cockpit Frontend ==="
FRONT_STATUS=$(curl -sk -o /dev/null -w "%{http_code}" https://localhost:9091/)
FRONT_BODY=$(curl -sk https://localhost:9091/ 2>/dev/null | head -c 300)
echo "  Frontend: HTTP $FRONT_STATUS"
echo "  Title: $(echo "$FRONT_BODY" | grep -o '<title>[^<]*</title>')"
echo "  Has Vue: $(echo "$FRONT_BODY" | grep -c 'vue' || echo 0)"

# --- Test 5: Cockpit Cluster Data ---
echo ""
echo "=== TEST 5: Our Cockpit Cluster Data ==="
if [ -n "$TOKEN" ] && [ "$TOKEN" != "FAIL" ]; then
  echo "  Cluster Status:"
  curl -sk -H "Authorization: Bearer $TOKEN" https://localhost:9091/api/cluster/status 2>/dev/null | python3 -m json.tool 2>/dev/null | head -20
  
  echo "  Cluster Nodes:"
  curl -sk -H "Authorization: Bearer $TOKEN" https://localhost:9091/api/cluster/nodes 2>/dev/null | python3 -m json.tool 2>/dev/null | head -20
  
  echo "  System Config:"
  curl -sk -H "Authorization: Bearer $TOKEN" https://localhost:9091/api/config/system 2>/dev/null | python3 -m json.tool 2>/dev/null | head -20
  
  echo "  Maintain Status:"
  curl -sk -H "Authorization: Bearer $TOKEN" https://localhost:9091/api/maintain/status 2>/dev/null | python3 -m json.tool 2>/dev/null | head -20
fi

# --- Test 6: Real 9090 - Check available services ---
echo ""
echo "=== TEST 6: Real System Services ==="
systemctl is-active cockpit.socket cockpit.service KSVD.service docker libvirtd glusterd 2>/dev/null || true

echo ""
echo "=== TEST 7: Our Cockpit DB Tables ==="
ls -la /opt/kvm-space/cockpit/server/data/ 2>/dev/null
echo "Tables:"
/usr/local/bin/node14 -e "
const Database = require('/opt/kvm-space/cockpit/server/node_modules/sql.js');
const fs = require('fs');
const buf = fs.readFileSync('/opt/kvm-space/cockpit/server/data/cockpit.db');
const db = new Database(buf);
const tables = db.exec(\"SELECT name FROM sqlite_master WHERE type='table'\");
if(tables.length) tables[0].values.forEach(t => {
  const count = db.exec('SELECT COUNT(*) FROM ' + t[0]);
  console.log('  ' + t[0] + ': ' + (count.length ? count[0].values[0][0] : 0) + ' rows');
});
" 2>/dev/null || echo "  Failed to read cockpit DB"

echo ""
echo "========================================="
echo "  Cockpit Comparison Test Complete"
echo "========================================="
