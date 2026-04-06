#!/bin/bash
BASE="https://localhost:8444/api"
TOKEN=$(curl -sk -X POST -H "Content-Type: application/json" -d '{"username":"admin","password":"admin123"}' "$BASE/auth/login" | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])")
curl -sk -H "Authorization: Bearer $TOKEN" "$BASE/system-extra/zombie-servers" 2>&1
echo ""
