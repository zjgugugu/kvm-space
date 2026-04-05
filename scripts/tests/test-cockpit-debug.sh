#!/bin/bash
TOKEN=$(curl -s http://localhost:9091/api/auth/login -X POST \
  -H 'Content-Type: application/json' \
  -d '{"username":"root","password":"root"}' -m 5 | python3 -c 'import sys,json; print(json.load(sys.stdin).get("token",""))' 2>/dev/null)

echo "=== /api/config (raw) ==="
curl -si http://localhost:9091/api/config \
  -H "Authorization: Bearer $TOKEN" -m 5
echo ''

echo "=== /api/maintain/services (raw) ==="
curl -si http://localhost:9091/api/maintain/services \
  -H "Authorization: Bearer $TOKEN" -m 5
echo ''

echo "=== /api/cluster/nodes (raw) ==="
curl -si http://localhost:9091/api/cluster/nodes \
  -H "Authorization: Bearer $TOKEN" -m 5
echo ''

echo "=== Check CDN access ==="
curl -sI https://unpkg.com/element-ui@2.15.14/lib/theme-chalk/index.css -m 5 2>&1 | head -5
echo ''

echo "=== cockpit log tail ==="
tail -20 /tmp/cockpit.log
