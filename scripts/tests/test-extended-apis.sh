#!/bin/bash
# 扩展API测试 - 覆盖所有子模块
BASE="https://localhost:8444/api"

# Login
TOKEN=$(curl -sk -X POST -H "Content-Type: application/json" -d '{"username":"admin","password":"admin123"}' "$BASE/auth/login" | python3 -c "import sys,json; print(json.load(sys.stdin).get('token',''))" 2>/dev/null)
if [ -z "$TOKEN" ]; then echo "Login failed"; exit 1; fi

PASS=0; FAIL=0; TOTAL=0
check_api() {
  local name="$1" url="$2"
  TOTAL=$((TOTAL + 1))
  local resp=$(curl -sk -H "Authorization: Bearer $TOKEN" -w "\n%{http_code}" "$BASE$url")
  local code=$(echo "$resp" | tail -1)
  local body=$(echo "$resp" | sed '$d')
  if [ "$code" = "200" ]; then
    # Check JSON format
    local has_data=$(echo "$body" | python3 -c "
import sys,json
d=json.load(sys.stdin)
if isinstance(d, dict) and 'data' in d:
    print('OK:' + str(len(d['data'])))
elif isinstance(d, dict):
    print('OK:obj')
elif isinstance(d, list):
    print('BARE:' + str(len(d)))
else:
    print('OTHER')
" 2>/dev/null)
    if echo "$has_data" | grep -q "^OK"; then
      PASS=$((PASS + 1))
      echo "  ✅ $name ($has_data)"
    elif echo "$has_data" | grep -q "^BARE"; then
      FAIL=$((FAIL + 1))
      echo "  ⚠️  $name - bare array ($has_data)"
    else
      FAIL=$((FAIL + 1))
      echo "  ❌ $name - unexpected format"
    fi
  else
    FAIL=$((FAIL + 1))
    echo "  ❌ $name (HTTP $code)"
  fi
}

echo "========================================="
echo " 扩展子模块API测试"
echo "========================================="

echo ""
echo ">>> Network Extra"
check_api "VLAN Pools" "/network-extra/vlan-pools"
check_api "Port Mirroring" "/network-extra/port-mirroring"
check_api "Config Rules" "/network-extra/config-rules"
check_api "Firewalls" "/network-extra/firewalls"
check_api "Port Groups" "/network-extra/port-groups"

echo ""
echo ">>> App Management"
check_api "App Layers" "/apps/layers"
check_api "Software Library" "/apps/software"
check_api "Software Publish" "/apps/software-publish"
check_api "Control Rules" "/apps/control-rules"
check_api "Virtual Groups" "/apps/virtual-groups"
check_api "Virtual Sessions" "/apps/virtual-sessions"

echo ""
echo ">>> System Extra"
check_api "Zombie Servers" "/system-extra/zombie-servers"
check_api "Boot Order" "/system-extra/boot-order"
check_api "Organizations" "/system-extra/organizations"
check_api "Affinity Groups" "/system-extra/affinity-groups"
check_api "Labels" "/system-extra/labels"
check_api "Detection" "/system-extra/detection"
check_api "Access Policies" "/system-extra/access-policies"
check_api "Roles" "/system-extra/roles"

echo ""
echo ">>> Scaling"
check_api "Scaling Strategies" "/scaling/strategies"
check_api "Scaling Groups" "/scaling/groups"
check_api "Load Balancers" "/scaling/load-balancers"
check_api "DRS Rules" "/scaling/drs"
check_api "DPM Policies" "/scaling/dpm"

echo ""
echo ">>> Other"
check_api "Terminal Bindings" "/terminal-bindings"
check_api "File Management" "/files"
check_api "Snapshot Policies" "/snapshot-policies"

echo ""
echo "========================================="
echo " 结果: $PASS/$TOTAL 通过, $FAIL 失败"
echo "========================================="
