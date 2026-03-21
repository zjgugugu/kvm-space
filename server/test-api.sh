#!/bin/bash
# 快速API测试脚本
BASE=http://localhost:3000

echo "=== 1. 登录 ==="
LOGIN=$(curl -s -X POST $BASE/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}')
echo "$LOGIN" | head -c 200
echo

TOKEN=$(echo "$LOGIN" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
echo "Token: ${TOKEN:0:30}..."

if [ -z "$TOKEN" ]; then
  echo "登录失败，退出"
  exit 1
fi

echo ""
echo "=== 2. 服务信息 ==="
curl -s $BASE/api/info
echo ""

echo ""
echo "=== 3. Dashboard ==="
curl -s $BASE/api/dashboard -H "Authorization: Bearer $TOKEN" | head -c 300
echo ""

echo ""
echo "=== 4. 主机列表 ==="
curl -s $BASE/api/hosts -H "Authorization: Bearer $TOKEN" | head -c 300
echo ""

echo ""
echo "=== 5. 虚拟机列表 ==="
curl -s $BASE/api/vms -H "Authorization: Bearer $TOKEN" | head -c 300
echo ""

echo ""
echo "=== 6. 模板列表 ==="
curl -s $BASE/api/templates -H "Authorization: Bearer $TOKEN" | head -c 200
echo ""

echo ""
echo "=== 测试完成 ==="
