#!/bin/bash
# Quick test: all 5 MC dashboard endpoints
TOKEN=$(curl -sk -X POST https://localhost:8444/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"root","password":"root"}' | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])")

PASS=0; FAIL=0
for ep in dashboard/overview dashboard/trends dashboard/user-stats dashboard/user-ranking dashboard/recent-alerts; do
  RESP=$(curl -sk -H "Authorization: Bearer $TOKEN" "https://localhost:8444/api/$ep" 2>/dev/null)
  IS=$(echo "$RESP" | python3 -c "import sys,json; json.load(sys.stdin); print('JSON')" 2>/dev/null || echo "NOT_JSON")
  if [ "$IS" = "JSON" ]; then
    PASS=$((PASS+1))
    echo "  OK  $ep → $(echo "$RESP" | head -c 120)"
  else
    FAIL=$((FAIL+1))
    echo "  FAIL $ep → $(echo "$RESP" | head -c 120)"
  fi
done
echo ""
echo "Dashboard: $PASS passed, $FAIL failed"
