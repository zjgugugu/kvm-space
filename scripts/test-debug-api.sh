#!/bin/bash
BASE="https://localhost:8444"
TOKEN=$(curl -sk -X POST $BASE/api/auth/login -H "Content-Type: application/json" -d '{"username":"root","password":"root"}' | python -c "import sys,json;print json.loads(sys.stdin.read())['token']" 2>/dev/null)

echo "=== recycle-bin ==="
curl -sk "$BASE/api/recycle-bin" -H "Authorization: Bearer $TOKEN" 2>/dev/null | head -c 400
echo

echo "=== apps/software ==="
curl -sk "$BASE/api/apps/software" -H "Authorization: Bearer $TOKEN" 2>/dev/null | head -c 200
echo

echo "=== apps/layers ==="
curl -sk "$BASE/api/apps/layers" -H "Authorization: Bearer $TOKEN" 2>/dev/null | head -c 200
echo

echo "=== apps/software-library ==="
curl -sk "$BASE/api/apps/software-library" -H "Authorization: Bearer $TOKEN" 2>/dev/null | head -c 200
echo

echo "=== networks/subnets ==="
curl -sk "$BASE/api/networks/subnets" -H "Authorization: Bearer $TOKEN" 2>/dev/null | head -c 200
echo
