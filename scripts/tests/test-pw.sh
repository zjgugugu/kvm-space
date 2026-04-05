#!/bin/bash
TOKEN=$(curl -s -X POST http://localhost:8444/api/auth/login -H 'Content-Type: application/json' -d '{"username":"admin","password":"admin123"}' | python3 -c 'import sys,json; print(json.load(sys.stdin)["token"])')
echo "TOKEN_LEN=${#TOKEN}"
# Test password change
RESP=$(curl -s -w '|%{http_code}' -X PUT http://localhost:8444/api/auth/password -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' -d '{"old_password":"admin123","new_password":"admin123"}')
echo "PASSWORD_RESP=$RESP"
# Test current user
RESP2=$(curl -s -w '|%{http_code}' -H "Authorization: Bearer $TOKEN" http://localhost:8444/api/auth/me)
echo "ME_RESP=$RESP2"
