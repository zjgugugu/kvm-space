#!/bin/bash
# 全模块综合测试 v2 - 修正API路径
# 测试模块 4-10 + 安全组/用户组/任务/许可证

BASE="https://localhost:8444/api"
PASS=0
FAIL=0
TOTAL=0
RESULTS=""

# Login first
echo ">>> 登录..."
LOGIN_RESP=$(curl -sk -X POST -H "Content-Type: application/json" -d '{"username":"admin","password":"admin123"}' "$BASE/auth/login")
TOKEN=$(echo "$LOGIN_RESP" | python3 -c "import sys,json; print(json.load(sys.stdin).get('token',''))" 2>/dev/null)
if [ -z "$TOKEN" ]; then
  # Try root/root
  LOGIN_RESP=$(curl -sk -X POST -H "Content-Type: application/json" -d '{"username":"root","password":"root"}' "$BASE/auth/login")
  TOKEN=$(echo "$LOGIN_RESP" | python3 -c "import sys,json; print(json.load(sys.stdin).get('token',''))" 2>/dev/null)
fi
if [ -z "$TOKEN" ]; then
  echo "  ❌ 登录失败: $LOGIN_RESP"
  exit 1
fi
echo "  ✅ 登录成功"
CURL="curl -sk -H \"Authorization: Bearer $TOKEN\""

check() {
  local name="$1" url="$2" method="${3:-GET}" body="$4" expect="${5:-200}"
  TOTAL=$((TOTAL + 1))
  local resp code
  if [ "$method" = "GET" ]; then
    resp=$(curl -sk -H "Authorization: Bearer $TOKEN" -w "\n%{http_code}" "$BASE$url")
  elif [ "$method" = "POST" ]; then
    resp=$(curl -sk -H "Authorization: Bearer $TOKEN" -w "\n%{http_code}" -X POST -H "Content-Type: application/json" -d "$body" "$BASE$url")
  elif [ "$method" = "PUT" ]; then
    resp=$(curl -sk -H "Authorization: Bearer $TOKEN" -w "\n%{http_code}" -X PUT -H "Content-Type: application/json" -d "$body" "$BASE$url")
  elif [ "$method" = "DELETE" ]; then
    resp=$(curl -sk -H "Authorization: Bearer $TOKEN" -w "\n%{http_code}" -X DELETE "$BASE$url")
  fi
  code=$(echo "$resp" | tail -1)
  local rbody=$(echo "$resp" | sed '$d')
  if [ "$code" = "$expect" ]; then
    # Check it's JSON (not HTML)
    if echo "$rbody" | head -c 1 | grep -q '[{"\[]'; then
      PASS=$((PASS + 1))
      RESULTS="$RESULTS\n  ✅ $name (HTTP $code)"
    else
      FAIL=$((FAIL + 1))
      RESULTS="$RESULTS\n  ❌ $name - got HTML not JSON (HTTP $code)"
    fi
  else
    FAIL=$((FAIL + 1))
    RESULTS="$RESULTS\n  ❌ $name (HTTP $code, expected $expect)"
  fi
}

check_json_field() {
  local name="$1" url="$2" field="$3"
  TOTAL=$((TOTAL + 1))
  local resp=$(curl -sk -H "Authorization: Bearer $TOKEN" "$BASE$url")
  local val=$(echo "$resp" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('$field','__MISSING__'))" 2>/dev/null)
  if [ "$val" != "__MISSING__" ] && [ -n "$val" ]; then
    PASS=$((PASS + 1))
    RESULTS="$RESULTS\n  ✅ $name ($field=$val)"
  else
    FAIL=$((FAIL + 1))
    RESULTS="$RESULTS\n  ❌ $name - field '$field' missing"
  fi
}

check_list() {
  local name="$1" url="$2"
  TOTAL=$((TOTAL + 1))
  local resp=$(curl -sk -H "Authorization: Bearer $TOKEN" "$BASE$url")
  local total=$(echo "$resp" | python3 -c "
import sys,json
d=json.load(sys.stdin)
if isinstance(d, list):
    print(len(d))
elif isinstance(d, dict):
    print(d.get('total', len(d.get('data',[]))))
else:
    print(-1)
" 2>/dev/null)
  if [ $? -eq 0 ] && [ -n "$total" ]; then
    PASS=$((PASS + 1))
    RESULTS="$RESULTS\n  ✅ $name (total=$total)"
  else
    FAIL=$((FAIL + 1))
    RESULTS="$RESULTS\n  ❌ $name - JSON parse failed"
  fi
}

echo "========================================="
echo " 全模块综合测试 v2"
echo "========================================="
echo ""

# --- Module 4: Host Management ---
echo ">>> Module 4: 服务器管理"
check "Host List" "/hosts"
check_list "Host List Data" "/hosts"
# Get first host ID
HOST_ID=$(curl -sk -H "Authorization: Bearer $TOKEN" "$BASE/hosts" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['data'][0]['id'] if d.get('data') else '')" 2>/dev/null)
if [ -n "$HOST_ID" ]; then
  check "Host Detail" "/hosts/$HOST_ID"
  check "Host Stats" "/hosts/$HOST_ID/stats"
else
  TOTAL=$((TOTAL + 2)); FAIL=$((FAIL + 2))
  RESULTS="$RESULTS\n  ❌ Host Detail - no host found\n  ❌ Host Stats - no host found"
fi
echo -e "$RESULTS" | tail -n +2 | head -5
RESULTS=""

# --- Module 5: Network Management ---
echo ""
echo ">>> Module 5: 网络管理"
check_list "Network List" "/networks"
# Create network
NET_BODY='{"name":"test-net-v2","type":"bridge","bridge":"virbr99","subnet":"192.168.99.0/24","dhcp_start":"192.168.99.100","dhcp_end":"192.168.99.200"}'
check "Network Create" "/networks" "POST" "$NET_BODY"
NET_ID=$(curl -sk -H "Authorization: Bearer $TOKEN" "$BASE/networks" | python3 -c "import sys,json; nets=json.load(sys.stdin)['data']; print([n['id'] for n in nets if n['name']=='test-net-v2'][0] if any(n['name']=='test-net-v2' for n in nets) else '')" 2>/dev/null)
if [ -n "$NET_ID" ]; then
  check "Network Delete" "/networks/$NET_ID" "DELETE"
fi

# Security Groups (correct path: /networks/security-groups)
check_list "Security Group List" "/networks/security-groups"
SG_BODY='{"name":"test-sg-v2","description":"Test security group"}'
check "Security Group Create" "/networks/security-groups" "POST" "$SG_BODY"
SG_ID=$(curl -sk -H "Authorization: Bearer $TOKEN" "$BASE/networks/security-groups" | python3 -c "import sys,json; gs=json.load(sys.stdin)['data']; print([g['id'] for g in gs if g['name']=='test-sg-v2'][0] if any(g['name']=='test-sg-v2' for g in gs) else '')" 2>/dev/null)
if [ -n "$SG_ID" ]; then
  # Add rule
  RULE_BODY='{"direction":"ingress","protocol":"tcp","port_range":"80","source":"0.0.0.0/0","action":"accept"}'
  check "Security Group Add Rule" "/networks/security-groups/$SG_ID/rules" "POST" "$RULE_BODY"
  # Delete the security group
  check "Security Group Delete" "/networks/security-groups/$SG_ID" "DELETE"
fi
echo -e "$RESULTS" | tail -n +2 | head -10
RESULTS=""

# --- Module 6: Storage Management ---
echo ""
echo ">>> Module 6: 存储管理"
check_list "Storage Pool List" "/storage/pools"
POOL_ID=$(curl -sk -H "Authorization: Bearer $TOKEN" "$BASE/storage/pools" | python3 -c "import sys,json; ps=json.load(sys.stdin)['data']; print(ps[0]['id'] if ps else '')" 2>/dev/null)
if [ -n "$POOL_ID" ]; then
  check "Storage Pool Detail" "/storage/pools/$POOL_ID"
fi
echo -e "$RESULTS" | tail -n +2 | head -5
RESULTS=""

# --- Module 7: User Management ---
echo ""
echo ">>> Module 7: 用户管理"
check_list "User List" "/users"
# User groups (correct path: /users/groups)
check_list "User Group List" "/users/groups"
# Create user
USER_BODY='{"username":"testuser_v2","password":"Test1234!","role":"user","display_name":"测试用户V2"}'
check "User Create" "/users" "POST" "$USER_BODY"
USER_ID=$(curl -sk -H "Authorization: Bearer $TOKEN" "$BASE/users" | python3 -c "import sys,json; us=json.load(sys.stdin)['data']; print([u['id'] for u in us if u['username']=='testuser_v2'][0] if any(u['username']=='testuser_v2' for u in us) else '')" 2>/dev/null)
if [ -n "$USER_ID" ]; then
  check "User Detail" "/users/$USER_ID"
  check "User Update" "/users/$USER_ID" "PUT" '{"display_name":"测试用户V2-updated"}'
  check "User Delete" "/users/$USER_ID" "DELETE"
fi
# Create user group
UG_BODY='{"name":"test-group-v2","description":"Test group"}'
check "User Group Create" "/users/groups" "POST" "$UG_BODY"
UG_ID=$(curl -sk -H "Authorization: Bearer $TOKEN" "$BASE/users/groups" | python3 -c "import sys,json; gs=json.load(sys.stdin)['data']; print([g['id'] for g in gs if g['name']=='test-group-v2'][0] if any(g['name']=='test-group-v2' for g in gs) else '')" 2>/dev/null)
if [ -n "$UG_ID" ]; then
  check "User Group Delete" "/users/groups/$UG_ID" "DELETE"
fi
echo -e "$RESULTS" | tail -n +2 | head -10
RESULTS=""

# --- Module 8: Templates ---
echo ""
echo ">>> Module 8: 模板管理"
check_list "Template List" "/templates"
check "VM Specs" "/specs"
echo -e "$RESULTS" | tail -n +2 | head -5
RESULTS=""

# --- Module 9: Events & Tasks ---
echo ""
echo ">>> Module 9: 事件/任务"
check_list "Event List" "/events"
# Tasks (correct path: /events/tasks)
check_list "Task List" "/events/tasks"
echo -e "$RESULTS" | tail -n +2 | head -5
RESULTS=""

# --- Module 10: System Config ---
echo ""
echo ">>> Module 10: 系统配置"
check "System Config" "/system/config"
# License (uses /info endpoint)
check_json_field "License/Info" "/info" "version"
echo -e "$RESULTS" | tail -n +2 | head -5
RESULTS=""

# --- Module 3: VM Quick Check ---
echo ""
echo ">>> Module 3: 虚拟机 (quick)"
check_list "VM List" "/vms"
echo -e "$RESULTS" | tail -n +2 | head -5
RESULTS=""

# --- Extra: Other endpoints ---
echo ""
echo ">>> Extra Endpoints"
check_list "Desktop Pools" "/desktop-pools"
check_list "Recycle Bin" "/recycle-bin"
check_list "Clients" "/clients"
check_list "Backups" "/backups"
check_list "Alerts" "/alerts"
check "Publish Rules" "/publish-rules"
check "Scaling Strategies" "/scaling/strategies"
check "Dashboard Overview" "/dashboard/overview"
check "Dashboard Trends" "/dashboard/trends"
check "Dashboard User Stats" "/dashboard/user-stats"
echo -e "$RESULTS" | tail -n +2 | head -15
RESULTS=""

echo ""
echo "========================================="
echo " 结果: $PASS/$TOTAL 通过, $FAIL 失败"
echo "========================================="
