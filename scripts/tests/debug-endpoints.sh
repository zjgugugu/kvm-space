#!/bin/bash
BASE="https://localhost:8444/api"
TOKEN=$(curl -sk -X POST -H "Content-Type: application/json" -d '{"username":"admin","password":"admin123"}' "$BASE/auth/login" | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])")
AUTH="Authorization: Bearer $TOKEN"

echo "=== User Detail ==="
# Get a user ID
UID2=$(curl -sk -H "$AUTH" "$BASE/users" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['data'][-1]['id'])" 2>/dev/null)
echo "User ID: $UID2"
curl -sk -H "$AUTH" "$BASE/users/$UID2" | head -c 300
echo ""

echo "=== Dashboard Server ==="
curl -sk -H "$AUTH" "$BASE/dashboard/server" | head -c 300
echo ""

echo "=== Dashboard VM ==="
curl -sk -H "$AUTH" "$BASE/dashboard/vm" | head -c 300
echo ""

echo "=== Dashboard Trend ==="
curl -sk -H "$AUTH" "$BASE/dashboard/trend" | head -c 300
echo ""

echo "=== Scaling ==="
curl -sk -H "$AUTH" "$BASE/scaling" | head -c 300
echo ""

echo "=== Desktop Pools ==="
curl -sk -H "$AUTH" "$BASE/desktop-pools" | head -c 300
echo ""

echo "=== Recycle Bin ==="
curl -sk -H "$AUTH" "$BASE/recycle-bin" | head -c 300
echo ""

echo "=== Clients ==="
curl -sk -H "$AUTH" "$BASE/clients" | head -c 300
echo ""
