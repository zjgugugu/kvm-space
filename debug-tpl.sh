#!/bin/bash
TOKEN=$(curl -sf --max-time 5 http://localhost:8444/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"admin123"}' | python3 -c 'import sys,json; print(json.load(sys.stdin)["token"])')
AUTH="Authorization: Bearer $TOKEN"

echo "1. Create template..."
TPL=$(curl -sf --max-time 5 -X POST http://localhost:8444/api/templates \
  -H "$AUTH" -H 'Content-Type: application/json' \
  -d '{"name":"debug-tpl","os_type":"linux","cpu":2,"memory":2048,"disk":20}')
echo "Template: $TPL"
TID=$(echo "$TPL" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("id",""))')
echo "TID: $TID"

echo ""
echo "2. List versions..."
VERS=$(curl -sf --max-time 5 "http://localhost:8444/api/templates/$TID/versions" -H "$AUTH")
echo "Versions: $VERS"

echo ""
echo "3. Create version..."
VER=$(curl -v --max-time 5 -X POST "http://localhost:8444/api/templates/$TID/versions" \
  -H "$AUTH" -H 'Content-Type: application/json' \
  -d '{"description":"v1"}' 2>&1)
echo "Version: $VER"

echo ""
echo "4. Check kvm.log for errors..."
tail -10 /tmp/kvm.log
