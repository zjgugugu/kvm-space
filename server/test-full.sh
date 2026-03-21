#!/bin/bash
# 全面 API 测试脚本
BASE=http://localhost:3000

echo "=== 1. 登录 ==="
LOGIN=$(curl -s -X POST $BASE/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}')
TOKEN=$(echo "$LOGIN" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
if [ -z "$TOKEN" ]; then
  echo "登录失败: $LOGIN"
  exit 1
fi
echo "Token: ${TOKEN:0:30}..."
AUTH="Authorization: Bearer $TOKEN"

echo ""
echo "=== 2. Dashboard Overview ==="
curl -s "$BASE/api/dashboard/overview" -H "$AUTH" | python3 -m json.tool 2>/dev/null | head -30
echo ""

echo ""
echo "=== 3. 主机列表 ==="
HOSTS=$(curl -s "$BASE/api/hosts" -H "$AUTH")
echo "$HOSTS" | python3 -c "import sys,json; d=json.load(sys.stdin); print(f'主机数: {d[\"total\"]}'); [print(f'  {h[\"name\"]:20s} {h[\"ip\"]:16s} {h[\"cpu_model\"]:30s} CPU:{h[\"cpu_total\"]:3d} MEM:{h[\"mem_total\"]}MB') for h in d['data']]"

echo ""
echo "=== 4. 主机统计 ==="
HOST_ID=$(echo "$HOSTS" | python3 -c "import sys,json; print(json.load(sys.stdin)['data'][0]['id'])")
curl -s "$BASE/api/hosts/$HOST_ID/stats" -H "$AUTH" | python3 -m json.tool 2>/dev/null

echo ""
echo "=== 5. 虚拟机列表 ==="
curl -s "$BASE/api/vms" -H "$AUTH" | python3 -c "import sys,json; d=json.load(sys.stdin); print(f'虚拟机数: {d[\"total\"]}')"

echo ""
echo "=== 6. 模板列表 ==="
curl -s "$BASE/api/templates" -H "$AUTH" | python3 -c "import sys,json; d=json.load(sys.stdin); print(f'模板数: {d[\"total\"]}')"

echo ""
echo "=== 7. 网络列表 ==="
curl -s "$BASE/api/networks" -H "$AUTH" | python3 -c "import sys,json; d=json.load(sys.stdin); print(f'网络数: {d[\"total\"]}')"

echo ""
echo "=== 8. 存储池列表 ==="
curl -s "$BASE/api/storage/pools" -H "$AUTH" | python3 -c "import sys,json; d=json.load(sys.stdin); print(f'存储池数: {d[\"total\"]}')"

echo ""
echo "=== 9. 用户列表 ==="
curl -s "$BASE/api/users" -H "$AUTH" | python3 -c "import sys,json; d=json.load(sys.stdin); [print(f'  {u[\"username\"]:15s} {u[\"role\"]:15s} {u[\"status\"]}') for u in d['data']]"

echo ""
echo "=== 10. 桌面规格 ==="
curl -s "$BASE/api/specs" -H "$AUTH" | python3 -c "import sys,json; d=json.load(sys.stdin); print(f'规格数: {d[\"total\"]}')"

echo ""
echo "=== 11. 发布规则 ==="
curl -s "$BASE/api/publish-rules" -H "$AUTH" | python3 -c "import sys,json; d=json.load(sys.stdin); print(f'规则数: {d[\"total\"]}')"

echo ""
echo "=== 12. 事件日志 ==="
curl -s "$BASE/api/events" -H "$AUTH" | python3 -c "import sys,json; d=json.load(sys.stdin); print(f'事件数: {d[\"total\"]}'); [print(f'  [{e[\"level\"]}] {e[\"action\"]}: {e[\"message\"]}') for e in d['data'][:5]]"

echo ""
echo "=== 13. 告警列表 ==="
curl -s "$BASE/api/alerts" -H "$AUTH" | python3 -c "import sys,json; d=json.load(sys.stdin); print(f'告警数: {d[\"total\"]}')"

echo ""
echo "=== 14. 系统配置 ==="
curl -s "$BASE/api/system/config" -H "$AUTH" | python3 -c "import sys,json; d=json.load(sys.stdin); [print(f'  {c[\"key\"]:25s} = {c[\"value\"]}') for c in d.get('data',d) if isinstance(c,dict)]" 2>/dev/null

echo ""
echo "=== 15. 快照策略 ==="
curl -s "$BASE/api/snapshot-policies" -H "$AUTH" | python3 -c "import sys,json; d=json.load(sys.stdin); print(f'策略数: {d.get(\"total\",0)}')"

echo ""
echo "=== 全面测试完成 ==="
