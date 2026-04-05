#!/bin/bash
# Cockpit 9091 API 测试脚本
BASE="http://localhost:9091"
PASS=0
FAIL=0
TOTAL=0

check() {
  TOTAL=$((TOTAL + 1))
  local desc="$1"
  local expected="$2"
  local actual="$3"
  if echo "$actual" | grep -q "$expected"; then
    PASS=$((PASS + 1))
    echo "  [PASS] $desc"
  else
    FAIL=$((FAIL + 1))
    echo "  [FAIL] $desc (expected: $expected, got: $actual)"
  fi
}

echo "===== Cockpit 9091 API 测试 ====="
echo ""

# 1. 系统信息（无需认证）
echo "[1] 系统信息"
R=$(curl -s -m 10 "$BASE/api/info")
check "GET /api/info 返回hostname" "hostname" "$R"
check "GET /api/info 返回ip" "ip" "$R"
check "GET /api/info 返回version" "version" "$R"

# 2. 未认证请求应返回401
echo ""
echo "[2] 认证检查"
R=$(curl -s -m 10 -o /dev/null -w "%{http_code}" "$BASE/api/cluster/status")
check "GET /api/cluster/status 未认证 → 401" "401" "$R"

# 3. 登录
echo ""
echo "[3] 登录"
R=$(curl -s -m 10 -X POST "$BASE/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"root","password":"unikylinsec"}')
check "POST /api/auth/login 返回token" "token" "$R"
TOKEN=$(echo "$R" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
if [ -z "$TOKEN" ]; then
  echo "  [ERROR] 无法获取token，中止测试"
  echo ""
  echo "===== 结果: $PASS/$TOTAL PASS, $FAIL FAIL ====="
  exit 1
fi
echo "  Token: ${TOKEN:0:20}..."
AUTH="Authorization: Bearer $TOKEN"

# 4. 错误密码登录
R=$(curl -s -m 10 -o /dev/null -w "%{http_code}" -X POST "$BASE/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"root","password":"wrong"}')
check "POST /api/auth/login 错误密码 → 401" "401" "$R"

# 5. 集群状态
echo ""
echo "[4] 集群管理"
R=$(curl -s -m 10 -H "$AUTH" "$BASE/api/cluster/status")
check "GET /api/cluster/status 返回cluster_status" "cluster_status" "$R"
check "GET /api/cluster/status 有service_status" "service_status" "$R"

# 6. 节点列表
R=$(curl -s -m 10 -H "$AUTH" "$BASE/api/cluster/nodes")
check "GET /api/cluster/nodes 返回data" "data" "$R"

# 7. 添加节点
R=$(curl -s -m 10 -X POST -H "$AUTH" -H "Content-Type: application/json" \
  "$BASE/api/cluster/nodes" \
  -d '{"name":"node2","ip":"10.126.33.100","role":"VDI_Only"}')
check "POST /api/cluster/nodes 添加节点" "node2" "$R"

# 8. 部署
R=$(curl -s -m 10 -X POST -H "$AUTH" -H "Content-Type: application/json" \
  "$BASE/api/cluster/deploy" \
  -d '{"type":1,"storage_mode":"GlusterFS","nodes":[{"name":"node1","ip":"10.126.33.238","role":"CM_VDI"}]}')
check "POST /api/cluster/deploy" "success\|ok\|cluster_status" "$R"

# 9. 关机/重启
R=$(curl -s -m 10 -o /dev/null -w "%{http_code}" -X POST -H "$AUTH" "$BASE/api/cluster/shutdown")
check "POST /api/cluster/shutdown → 200" "200" "$R"
R=$(curl -s -m 10 -o /dev/null -w "%{http_code}" -X POST -H "$AUTH" "$BASE/api/cluster/reboot")
check "POST /api/cluster/reboot → 200" "200" "$R"

# 10. 高级配置
echo ""
echo "[5] 高级配置"
# NTP
R=$(curl -s -m 10 -H "$AUTH" "$BASE/api/config/ntp")
check "GET /api/config/ntp" "data" "$R"

R=$(curl -s -m 10 -X PUT -H "$AUTH" -H "Content-Type: application/json" \
  "$BASE/api/config/ntp" \
  -d '{"server":"ntp.aliyun.com","time_update_interval":10}')
check "PUT /api/config/ntp" "ok\|success\|server" "$R"

# NFS
R=$(curl -s -m 10 -H "$AUTH" "$BASE/api/config/nfs")
check "GET /api/config/nfs" "data" "$R"

R=$(curl -s -m 10 -X PUT -H "$AUTH" -H "Content-Type: application/json" \
  "$BASE/api/config/nfs" \
  -d '{"ip":"192.168.1.100","share_dir":"/data/nfs","version":"4"}')
check "PUT /api/config/nfs" "ok\|success\|ip" "$R"

# CIFS
R=$(curl -s -m 10 -H "$AUTH" "$BASE/api/config/cifs")
check "GET /api/config/cifs" "data" "$R"

R=$(curl -s -m 10 -X PUT -H "$AUTH" -H "Content-Type: application/json" \
  "$BASE/api/config/cifs" \
  -d '{"ip":"192.168.1.200","share_dir":"share","user_name":"admin","password":"pass","domain":"WORK","version":"2.0"}')
check "PUT /api/config/cifs" "ok\|success\|ip" "$R"

# Center cluster
R=$(curl -s -m 10 -H "$AUTH" "$BASE/api/config/center-cluster")
check "GET /api/config/center-cluster" "data" "$R"

R=$(curl -s -m 10 -X PUT -H "$AUTH" -H "Content-Type: application/json" \
  "$BASE/api/config/center-cluster" \
  -d '{"ip":"10.1.1.1","user_name":"admin","password":"123456","data_sync_time":"02:00"}')
check "PUT /api/config/center-cluster" "ok\|success\|ip" "$R"

# Network
R=$(curl -s -m 10 -H "$AUTH" "$BASE/api/config/network")
check "GET /api/config/network" "data\|hostname\|ip" "$R"

# Roles
R=$(curl -s -m 10 -X PUT -H "$AUTH" -H "Content-Type: application/json" \
  "$BASE/api/config/roles" \
  -d '{"updates":[{"id":1,"role":"CM_Only"}]}')
check "PUT /api/config/roles" "ok\|success\|updated" "$R"

# 11. 存储维护
echo ""
echo "[6] 存储维护"
# 脑裂恢复
R=$(curl -s -m 10 -X POST -H "$AUTH" "$BASE/api/maintain/recovery/scan")
check "POST /api/maintain/recovery/scan" "files\|success" "$R"

# 备份
R=$(curl -s -m 10 -X POST -H "$AUTH" -H "Content-Type: application/json" \
  "$BASE/api/maintain/backups" \
  -d '{"message":"test backup"}')
check "POST /api/maintain/backups 创建" "id\|success" "$R"

R=$(curl -s -m 10 -H "$AUTH" "$BASE/api/maintain/backups")
check "GET /api/maintain/backups 列表" "data" "$R"

# 日志
R=$(curl -s -m 10 -H "$AUTH" "$BASE/api/maintain/logs")
check "GET /api/maintain/logs" "data" "$R"

# 网络监测  
R=$(curl -s -m 10 -H "$AUTH" "$BASE/api/maintain/network-detect")
check "GET /api/maintain/network-detect" "data" "$R"

# 任务
R=$(curl -s -m 10 -H "$AUTH" "$BASE/api/maintain/tasks")
check "GET /api/maintain/tasks" "data" "$R"

# 12. 前端页面
echo ""
echo "[7] 前端页面"
R=$(curl -s -m 10 -o /dev/null -w "%{http_code}" "$BASE/")
check "GET / 返回200" "200" "$R"
R=$(curl -s -m 10 "$BASE/" | head -1)
check "GET / 返回HTML" "DOCTYPE\|html" "$R"

# 13. 删除节点
echo ""
echo "[8] 清理"
R=$(curl -s -m 10 -H "$AUTH" "$BASE/api/cluster/nodes")
NODE_IDS=$(echo "$R" | grep -o '"id":[0-9]*' | grep -o '[0-9]*' | tail -1)
if [ -n "$NODE_IDS" ]; then
  R=$(curl -s -m 10 -X DELETE -H "$AUTH" "$BASE/api/cluster/nodes/$NODE_IDS")
  check "DELETE /api/cluster/nodes/$NODE_IDS" "ok\|success\|deleted" "$R"
fi

echo ""
echo "====================================="
echo "  结果: $PASS/$TOTAL PASS, $FAIL FAIL"
echo "====================================="
