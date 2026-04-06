#!/bin/bash
# Comprehensive Cockpit 9091 API test with correct endpoints
set -e

echo "========================================="
echo "  Cockpit 9091 Full API Test"
echo "========================================="

# Login
TOKEN=$(curl -sk -X POST https://localhost:9091/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"root","password":"root"}' 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('token',''))" 2>/dev/null)

if [ -z "$TOKEN" ]; then
  echo "FATAL: Login failed"
  exit 1
fi
echo "Login: OK (token ${#TOKEN} chars)"

PASS=0
FAIL=0
TOTAL=0

test_api() {
  local method=$1
  local endpoint=$2
  local data=$3
  TOTAL=$((TOTAL+1))
  
  if [ "$method" = "GET" ]; then
    RESP=$(curl -sk -H "Authorization: Bearer $TOKEN" https://localhost:9091/api/$endpoint 2>/dev/null)
  elif [ "$method" = "POST" ]; then
    RESP=$(curl -sk -X POST -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' -d "$data" https://localhost:9091/api/$endpoint 2>/dev/null)
  elif [ "$method" = "PUT" ]; then
    RESP=$(curl -sk -X PUT -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' -d "$data" https://localhost:9091/api/$endpoint 2>/dev/null)
  fi

  # Check if JSON
  IS_JSON=$(echo "$RESP" | python3 -c "import sys,json; json.load(sys.stdin); print('Y')" 2>/dev/null || echo "N")
  
  if [ "$IS_JSON" = "Y" ]; then
    PASS=$((PASS+1))
    BRIEF=$(echo "$RESP" | head -c 120)
    echo "  OK  $method $endpoint → $BRIEF"
  else
    FAIL=$((FAIL+1))
    echo "  FAIL $method $endpoint → $(echo "$RESP" | head -c 80)"
  fi
}

echo ""
echo "--- Auth Routes ---"
test_api GET auth/me
test_api GET info

echo ""
echo "--- Cluster Routes ---"
test_api GET cluster/status
test_api GET cluster/nodes

echo ""
echo "--- Config Routes ---"
test_api GET config/ntp
test_api GET config/nfs
test_api GET config/cifs
test_api GET config/center-cluster
test_api GET config/network

echo ""
echo "--- Maintain Routes ---"
test_api GET maintain/recovery/status
test_api GET maintain/backups
test_api GET maintain/logs
test_api GET maintain/network-detect
test_api GET maintain/tasks

echo ""
echo "========================================="
echo "  Results: $PASS passed, $FAIL failed (total $TOTAL)"
echo "========================================="

echo ""
echo "--- Detailed Data Check ---"
echo "Cluster Status (full):"
curl -sk -H "Authorization: Bearer $TOKEN" https://localhost:9091/api/cluster/status 2>/dev/null | python3 -m json.tool 2>/dev/null | head -40
echo ""
echo "Cluster Nodes (full):"
curl -sk -H "Authorization: Bearer $TOKEN" https://localhost:9091/api/cluster/nodes 2>/dev/null | python3 -m json.tool 2>/dev/null
echo ""
echo "Network Config:"
curl -sk -H "Authorization: Bearer $TOKEN" https://localhost:9091/api/config/network 2>/dev/null | python3 -m json.tool 2>/dev/null
echo ""
echo "System Info (no auth):"
curl -sk https://localhost:9091/api/info 2>/dev/null | python3 -m json.tool 2>/dev/null

echo ""
echo "--- Real 9090 Cockpit Login Test ---"
# The real cockpit uses Basic auth header
REAL_RESP=$(curl -sk -X POST https://localhost:9090/cockpit/login \
  -H 'Authorization: Basic cm9vdDp1bmlreWxpbnNlYw==' \
  -c /tmp/ck-cookies.txt -D /tmp/ck-headers.txt 2>/dev/null)
echo "Real 9090 login response (headers):"
cat /tmp/ck-headers.txt 2>/dev/null | head -10
echo "Real 9090 login body:"
echo "$REAL_RESP" | head -c 300
echo ""

# If logged in, try to fetch system info
if grep -q cockpit /tmp/ck-cookies.txt 2>/dev/null; then
  echo ""
  echo "Real 9090 manifests:"
  curl -sk -b /tmp/ck-cookies.txt https://localhost:9090/cockpit/manifests.json 2>/dev/null | python3 -m json.tool 2>/dev/null | head -30
fi
