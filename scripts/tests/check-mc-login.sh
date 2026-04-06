#!/bin/bash
# Get real MC login form and column definitions
echo "=== MC Login page form action ==="
curl -sk "https://localhost:8443/mc/" | grep -oP 'action="[^"]*"'

echo ""
echo "=== Trying AES-based login ==="
# Use the known AES-128-CBC encryption for login
MC_BASE="https://localhost:8443/mc"

# Try j_spring_security_check
CODE=$(curl -sk -c /tmp/mc_cookies.txt -o /dev/null -w "%{http_code}" \
  -X POST "$MC_BASE/j_spring_security_check" \
  -d "j_username=mcadmin&j_password=987qwe654asd*&language=zh")
echo "j_spring_security_check: $CODE"

# Try /mc/auth/login
CODE=$(curl -sk -c /tmp/mc_cookies.txt -o /dev/null -w "%{http_code}" \
  -X POST "$MC_BASE/auth/login" \
  -d "username=mcadmin&password=987qwe654asd*")
echo "auth/login: $CODE"

# Try /mc/api/login
CODE=$(curl -sk -c /tmp/mc_cookies.txt -o /dev/null -w "%{http_code}" \
  -X POST "$MC_BASE/api/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"mcadmin","password":"987qwe654asd*"}')
echo "api/login: $CODE"

echo ""
echo "=== Looking at MC login form ==="
curl -sk "$MC_BASE/" | grep -E 'form|action|submit|input|name=' | head -20

echo ""
echo "=== Already fetched MC pages ==="
ls /opt/kvm-space/docs/research/mc_pages/ | head -20
ls /opt/kvm-space/docs/research/mc_pages_refetch/ | head -20
