#!/bin/bash
TOKEN=$(curl -sf --max-time 5 http://localhost:8444/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"admin123"}' | python3 -c 'import sys,json; print(json.load(sys.stdin)["token"])')
AUTH="Authorization: Bearer $TOKEN"

echo "Testing POST /api/users..."
RESULT=$(curl -sf --max-time 5 -X POST http://localhost:8444/api/users \
  -H "$AUTH" -H 'Content-Type: application/json' \
  -d '{"username":"testxyz","password":"Test1234!","role":"user"}' 2>&1)
echo "Result: $RESULT"

echo ""
echo "Testing GET /api/users/groups..."
RESULT2=$(curl -sf --max-time 5 http://localhost:8444/api/users/groups -H "$AUTH" 2>&1)
echo "Result: $RESULT2"

echo ""
echo "Testing GET /api/users/ldap..."
RESULT3=$(curl -sf --max-time 5 http://localhost:8444/api/users/ldap -H "$AUTH" 2>&1)
echo "Result: $RESULT3"

echo ""
echo "Testing rest of system APIs..."
for ENDPOINT in /api/system/config /api/system/policies /api/system/password-policy /api/system/access-policy /api/system/smtp /api/backups/servers /api/backups /api/snapshot-policies /api/events /api/events/tasks /api/events/approvals /api/alerts /api/alerts/settings /api/stats /api/stats/user-login; do
  RESP=$(curl -sf --max-time 5 "http://localhost:8444$ENDPOINT" -H "$AUTH" 2>&1 || echo "TIMEOUT/ERROR")
  OK=$(echo "$RESP" | python3 -c 'import sys,json; json.load(sys.stdin); print("OK")' 2>/dev/null || echo "FAIL")
  echo "  $ENDPOINT: $OK"
done

echo ""
echo "Frontend check..."
HTTP=$(curl -sf --max-time 5 -o /dev/null -w '%{http_code}' http://localhost:8444/)
echo "Frontend HTTP: $HTTP"
