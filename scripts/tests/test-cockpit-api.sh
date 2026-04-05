#!/bin/bash
echo '=== Test Cockpit (9091) ==='

# Test login
echo 'Testing login root/root...'
RESP=$(curl -s http://localhost:9091/api/auth/login -X POST \
  -H 'Content-Type: application/json' \
  -d '{"username":"root","password":"root"}' -m 5)
echo "Login response: $RESP"

TOKEN=$(echo "$RESP" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("token",""))' 2>/dev/null)

if [ -z "$TOKEN" ]; then
  echo 'Login FAILED!'
  exit 1
fi
echo "Login OK: token=${TOKEN:0:30}..."

# Test info (no auth)
echo ''
echo '=== /api/info (no auth) ==='
curl -s http://localhost:9091/api/info -m 5 | python3 -m json.tool

# Test cluster status
echo ''
echo '=== /api/cluster/status ==='
curl -s http://localhost:9091/api/cluster/status \
  -H "Authorization: Bearer $TOKEN" -m 5 | python3 -m json.tool

# Test config
echo ''
echo '=== /api/config ==='
curl -s http://localhost:9091/api/config \
  -H "Authorization: Bearer $TOKEN" -m 5 | python3 -m json.tool

# Test maintain/services
echo ''
echo '=== /api/maintain/services ==='
curl -s http://localhost:9091/api/maintain/services \
  -H "Authorization: Bearer $TOKEN" -m 5 | python3 -m json.tool

# Test frontend
echo ''
echo '=== Frontend HTML ==='
curl -s http://localhost:9091/ -m 5 | head -5

echo ''
echo '=== All Tests Done ==='
