#!/bin/bash
# Test all MC API endpoints
BASE="https://localhost:8444"
TOKEN=$(curl -sk -X POST $BASE/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"root","password":"root"}' | \
  python -c "import sys,json;print json.loads(sys.stdin.read())['token']" 2>/dev/null)

echo "TOKEN_LEN=${#TOKEN}"

for ep in dashboard/overview vms hosts templates storage networks events alerts users system/config stats/user-login publish-rules specs desktop-pools backups snapshot-policies clients recycle-bin files; do
  RESP=$(curl -sk "$BASE/api/$ep" -H "Authorization: Bearer $TOKEN" 2>/dev/null)
  echo "=== $ep === $(echo "$RESP" | head -c 300)"
done
