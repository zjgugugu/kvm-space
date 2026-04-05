#!/bin/bash
# 测试我们的KVM Cloud系统的所有API端点
# 与真实MC测试一一对应
BASE="http://localhost:8444"
OUT="/tmp/our_api_test.txt"
rm -f $OUT

log() { echo "$1" >> $OUT; }
PASS=0; FAIL=0; TOTAL=0; TOKEN=""

# 登录获取token
login_resp=$(curl -s -X POST "$BASE/api/auth/login" -H "Content-Type: application/json" -d '{"username":"admin","password":"admin123"}' 2>/dev/null)
TOKEN=$(echo "$login_resp" | python3 -c "import sys,json;print(json.load(sys.stdin).get('token',''))" 2>/dev/null)
log "LOGIN: token=${TOKEN:0:20}..."

if [ -z "$TOKEN" ]; then
    log "LOGIN FAILED: $login_resp"
    echo "LOGIN FAILED"
    exit 1
fi

AUTH="Authorization: Bearer $TOKEN"

t() {
    local NAME="$1" METHOD="$2" URL="$3" DATA="$4"
    TOTAL=$((TOTAL+1))
    local RESP
    if [ "$METHOD" = "GET" ]; then
        RESP=$(curl -s -H "$AUTH" -w "|%{http_code}|%{size_download}" "$BASE$URL" 2>/dev/null)
    elif [ "$METHOD" = "POST" ]; then
        RESP=$(curl -s -X POST -H "$AUTH" -H "Content-Type: application/json" -d "$DATA" -w "|%{http_code}|%{size_download}" "$BASE$URL" 2>/dev/null)
    elif [ "$METHOD" = "PUT" ]; then
        RESP=$(curl -s -X PUT -H "$AUTH" -H "Content-Type: application/json" -d "$DATA" -w "|%{http_code}|%{size_download}" "$BASE$URL" 2>/dev/null)
    elif [ "$METHOD" = "DELETE" ]; then
        RESP=$(curl -s -X DELETE -H "$AUTH" -w "|%{http_code}|%{size_download}" "$BASE$URL" 2>/dev/null)
    fi

    local CODE=$(echo "$RESP" | grep -oP '\|(\d+)\|\d+$' | cut -d'|' -f2)
    local SIZE=$(echo "$RESP" | grep -oP '\|\d+\|(\d+)$' | cut -d'|' -f2)
    local BODY=$(echo "$RESP" | sed 's/|[0-9]*|[0-9]*$//' | head -c 300)

    if [ "$CODE" = "200" ] && [ "${SIZE:-0}" -gt 2 ] 2>/dev/null; then
        PASS=$((PASS+1))
        log "PASS|$NAME|$CODE|$SIZE|$BODY"
    else
        FAIL=$((FAIL+1))
        log "FAIL|$NAME|$CODE|$SIZE|$BODY"
    fi
}

log ""
log "=== 一、认证 Auth ==="
t "登录" "POST" "/api/auth/login" '{"username":"admin","password":"admin123"}'
t "当前用户" "GET" "/api/auth/me"
t "修改密码" "PUT" "/api/auth/password" '{"old_password":"admin123","new_password":"admin123"}'

log ""
log "=== 二、仪表板 Dashboard ==="
t "总览统计" "GET" "/api/dashboard/overview"
t "趋势数据" "GET" "/api/dashboard/trends"
t "用户统计" "GET" "/api/dashboard/user-stats"
t "用户排名" "GET" "/api/dashboard/user-ranking"
t "最近告警" "GET" "/api/dashboard/recent-alerts"

log ""
log "=== 三、黄金镜像/模板 ==="
t "模板列表" "GET" "/api/templates"
t "创建模板" "POST" "/api/templates" '{"name":"测试模板","os_type":"linux","os_version":"KylinV10","arch":"aarch64","cpu":2,"memory":2048,"disk":40,"description":"自动测试创建"}'
# 获取创建的模板ID
TMPL_ID=$(curl -s -H "$AUTH" "$BASE/api/templates" 2>/dev/null | python3 -c "import sys,json;ts=json.load(sys.stdin);print(ts[0]['id'] if ts else '')" 2>/dev/null)
if [ -n "$TMPL_ID" ]; then
    t "模板详情" "GET" "/api/templates/$TMPL_ID"
    t "编辑模板" "PUT" "/api/templates/$TMPL_ID" '{"name":"测试模板-已编辑","description":"编辑测试"}'
    t "发布模板" "POST" "/api/templates/$TMPL_ID/publish" ''
    t "维护模板" "POST" "/api/templates/$TMPL_ID/maintain" ''
    t "克隆模板" "POST" "/api/templates/$TMPL_ID/clone" '{"name":"克隆模板"}'
    t "模板版本列表" "GET" "/api/templates/$TMPL_ID/versions"
    t "创建模板版本" "POST" "/api/templates/$TMPL_ID/versions" '{"description":"测试版本"}'
fi

log ""
log "=== 四、桌面规格 Specs ==="
t "规格列表" "GET" "/api/specs"
t "创建规格" "POST" "/api/specs" '{"name":"测试规格-办公","cpu":2,"max_cpu":4,"memory":2048,"max_memory":4096,"system_disk":40,"protocol":"UDAP"}'
SPEC_ID=$(curl -s -H "$AUTH" "$BASE/api/specs" 2>/dev/null | python3 -c "import sys,json;ss=json.load(sys.stdin);print(ss[0]['id'] if ss else '')" 2>/dev/null)
if [ -n "$SPEC_ID" ]; then
    t "规格详情" "GET" "/api/specs/$SPEC_ID"
    t "编辑规格" "PUT" "/api/specs/$SPEC_ID" '{"name":"测试规格-办公-已改","cpu":4}'
fi

log ""
log "=== 五、发布规则 ==="
t "规则列表" "GET" "/api/publish-rules"
if [ -n "$TMPL_ID" ] && [ -n "$SPEC_ID" ]; then
    t "创建发布规则" "POST" "/api/publish-rules" "{\"name\":\"测试规则\",\"template_id\":\"$TMPL_ID\",\"spec_id\":\"$SPEC_ID\",\"target_type\":\"user\",\"desktop_type\":\"dynamic\"}"
fi
RULE_ID=$(curl -s -H "$AUTH" "$BASE/api/publish-rules" 2>/dev/null | python3 -c "import sys,json;rs=json.load(sys.stdin);print(rs[0]['id'] if rs else '')" 2>/dev/null)
if [ -n "$RULE_ID" ]; then
    t "规则详情" "GET" "/api/publish-rules/$RULE_ID"
    t "编辑规则" "PUT" "/api/publish-rules/$RULE_ID" '{"name":"测试规则-已改"}'
    t "切换规则状态" "PUT" "/api/publish-rules/$RULE_ID/status" '{"status":"inactive"}'
fi

log ""
log "=== 六、用户管理 ==="
t "用户列表" "GET" "/api/users"
t "创建用户" "POST" "/api/users" '{"username":"testuser","password":"Test@1234","display_name":"测试用户","role":"user","email":"test@test.com"}'
USER_ID=$(curl -s -H "$AUTH" "$BASE/api/users" 2>/dev/null | python3 -c "import sys,json;us=json.load(sys.stdin);print(next((u['id'] for u in us if u['username']=='testuser'),''))" 2>/dev/null)
if [ -n "$USER_ID" ]; then
    t "编辑用户" "PUT" "/api/users/$USER_ID" '{"display_name":"测试用户-已改","phone":"13800138000"}'
    t "重置密码" "PUT" "/api/users/$USER_ID/password" '{"password":"NewPass@123"}'
    t "禁用用户" "PUT" "/api/users/$USER_ID/status" '{"status":"disabled"}'
    t "启用用户" "PUT" "/api/users/$USER_ID/status" '{"status":"active"}'
fi
t "用户组列表" "GET" "/api/users/groups"
t "创建用户组" "POST" "/api/users/groups" '{"name":"测试组","description":"自动测试"}'
GRP_ID=$(curl -s -H "$AUTH" "$BASE/api/users/groups" 2>/dev/null | python3 -c "import sys,json;gs=json.load(sys.stdin);print(gs[0]['id'] if gs else '')" 2>/dev/null)
if [ -n "$GRP_ID" ]; then
    t "编辑用户组" "PUT" "/api/users/groups/$GRP_ID" '{"name":"测试组-已改"}'
fi
t "LDAP配置" "GET" "/api/users/ldap"
t "配置LDAP" "PUT" "/api/users/ldap" '{"server":"ldap://10.0.0.1","base_dn":"dc=example,dc=com","bind_dn":"cn=admin","bind_password":"pass"}'
t "测试LDAP" "POST" "/api/users/ldap/test" ''
t "同步LDAP" "POST" "/api/users/ldap/sync" ''

log ""
log "=== 七、虚拟机管理 ==="
t "VM列表" "GET" "/api/vms"
t "创建VM" "POST" "/api/vms" "{\"name\":\"test-vm-1\",\"template_id\":\"${TMPL_ID}\",\"cpu\":2,\"memory\":2048,\"disk\":40,\"os_type\":\"linux\"}"
VM_ID=$(curl -s -H "$AUTH" "$BASE/api/vms" 2>/dev/null | python3 -c "import sys,json;vs=json.load(sys.stdin);print(vs[0]['id'] if isinstance(vs,list) and vs else '')" 2>/dev/null)
if [ -n "$VM_ID" ]; then
    t "VM详情" "GET" "/api/vms/$VM_ID"
    t "编辑VM" "PUT" "/api/vms/$VM_ID" '{"cpu":4,"memory":4096}'
    t "启动VM" "POST" "/api/vms/$VM_ID/action" '{"action":"start"}'
    t "挂起VM" "POST" "/api/vms/$VM_ID/action" '{"action":"suspend"}'
    t "恢复VM" "POST" "/api/vms/$VM_ID/action" '{"action":"resume"}'
    t "重启VM" "POST" "/api/vms/$VM_ID/action" '{"action":"reboot"}'
    t "关机VM" "POST" "/api/vms/$VM_ID/action" '{"action":"stop"}'
    t "强制关机" "POST" "/api/vms/$VM_ID/action" '{"action":"force-stop"}'
    t "还原模板" "POST" "/api/vms/$VM_ID/action" '{"action":"restore-template"}'
    t "VM统计" "GET" "/api/vms/$VM_ID/stats"
    t "创建快照" "POST" "/api/vms/$VM_ID/snapshots" '{"name":"test-snap","description":"自动测试快照"}'
    t "快照列表" "GET" "/api/vms/$VM_ID/snapshots"
    SNAP_ID=$(curl -s -H "$AUTH" "$BASE/api/vms/$VM_ID/snapshots" 2>/dev/null | python3 -c "import sys,json;ss=json.load(sys.stdin);print(ss[0]['id'] if isinstance(ss,list) and ss else '')" 2>/dev/null)
    if [ -n "$SNAP_ID" ]; then
        t "编辑快照" "PUT" "/api/vms/$VM_ID/snapshots/$SNAP_ID" '{"name":"snap-edited"}'
        t "恢复快照" "POST" "/api/vms/$VM_ID/snapshots/$SNAP_ID/revert" ''
    fi
    t "添加磁盘" "POST" "/api/vms/$VM_ID/disks" '{"size":20,"type":"data","bus":"virtio"}'
    t "添加网卡" "POST" "/api/vms/$VM_ID/nics" '{"model":"virtio"}'
    t "克隆VM" "POST" "/api/vms/$VM_ID/clone" '{"name":"test-vm-clone"}'
    t "迁移VM" "POST" "/api/vms/$VM_ID/migrate" '{"target_host_id":"host-1"}'
fi
t "回收站" "GET" "/api/vms/recycle-bin"

log ""
log "=== 八、主机管理 ==="
t "集群列表" "GET" "/api/hosts/clusters/list"
t "创建集群" "POST" "/api/hosts/clusters" '{"name":"测试集群","description":"自动测试"}'
t "主机列表" "GET" "/api/hosts"
HOST_ID=$(curl -s -H "$AUTH" "$BASE/api/hosts" 2>/dev/null | python3 -c "import sys,json;hs=json.load(sys.stdin);print(hs[0]['id'] if isinstance(hs,list) and hs else '')" 2>/dev/null)
if [ -n "$HOST_ID" ]; then
    t "主机详情" "GET" "/api/hosts/$HOST_ID"
    t "主机统计" "GET" "/api/hosts/$HOST_ID/stats"
    t "编辑主机" "PUT" "/api/hosts/$HOST_ID" '{"name":"node1-edited"}'
fi

log ""
log "=== 九、网络管理 ==="
t "网络列表" "GET" "/api/networks"
t "创建网络" "POST" "/api/networks" '{"name":"test-net","type":"bridge","bridge":"br-test","vlan":100}'
t "安全组列表" "GET" "/api/networks/security-groups"
t "创建安全组" "POST" "/api/networks/security-groups" '{"name":"test-sg","description":"测试安全组"}'
SG_ID=$(curl -s -H "$AUTH" "$BASE/api/networks/security-groups" 2>/dev/null | python3 -c "import sys,json;sgs=json.load(sys.stdin);print(sgs[0]['id'] if isinstance(sgs,list) and sgs else '')" 2>/dev/null)
if [ -n "$SG_ID" ]; then
    t "安全组详情" "GET" "/api/networks/security-groups/$SG_ID"
    t "添加安全规则" "POST" "/api/networks/security-groups/$SG_ID/rules" '{"direction":"inbound","protocol":"tcp","port_range":"80","source":"0.0.0.0/0","action":"accept"}'
fi
t "MAC池列表" "GET" "/api/networks/mac-pools"
t "创建MAC池" "POST" "/api/networks/mac-pools" '{"name":"test-mac-pool","prefix":"52:54:00","range_start":"00:00:01","range_end":"FF:FF:FF"}'
t "子网列表" "GET" "/api/networks/subnets"

log ""
log "=== 十、存储管理 ==="
t "存储池列表" "GET" "/api/storage/pools"
t "创建存储池" "POST" "/api/storage/pools" '{"name":"test-pool","type":"local","path":"/data/test","total":100}'
POOL_ID=$(curl -s -H "$AUTH" "$BASE/api/storage/pools" 2>/dev/null | python3 -c "import sys,json;ps=json.load(sys.stdin);print(ps[0]['id'] if isinstance(ps,list) and ps else '')" 2>/dev/null)
if [ -n "$POOL_ID" ]; then
    t "存储池详情" "GET" "/api/storage/pools/$POOL_ID"
    t "编辑存储池" "PUT" "/api/storage/pools/$POOL_ID" '{"name":"test-pool-edited"}'
    t "扩容存储池" "POST" "/api/storage/pools/$POOL_ID/expand" '{"additional":50}'
fi
t "卷列表" "GET" "/api/storage/volumes"
t "创建卷" "POST" "/api/storage/volumes" "{\"name\":\"test-vol\",\"pool_id\":\"$POOL_ID\",\"size\":20}"
t "存储告警" "GET" "/api/storage/alerts"
t "存储健康检查" "POST" "/api/storage/health-check" ''

log ""
log "=== 十一、备份管理 ==="
t "备份服务器列表" "GET" "/api/backups/servers"
t "创建备份服务器" "POST" "/api/backups/servers" '{"name":"test-bak-svr","address":"10.0.0.100","port":22,"protocol":"ssh","username":"root"}'
t "备份列表" "GET" "/api/backups"

log ""
log "=== 十二、快照策略 ==="
t "快照策略列表" "GET" "/api/snapshot-policies"
t "创建快照策略" "POST" "/api/snapshot-policies" '{"name":"每日自动快照","cron_expr":"0 2 * * *","max_keep":5,"cpu_limit":50}'

log ""
log "=== 十三、事件日志 ==="
t "事件列表" "GET" "/api/events"
t "任务列表" "GET" "/api/events/tasks"
t "审批列表" "GET" "/api/events/approvals"

log ""
log "=== 十四、告警 ==="
t "告警列表" "GET" "/api/alerts"
t "告警设置" "GET" "/api/alerts/settings"

log ""
log "=== 十五、系统设置 ==="
t "系统配置" "GET" "/api/system/config"
t "全局策略" "GET" "/api/system/policies"
t "密码策略" "GET" "/api/system/password-policy"
t "访问策略" "GET" "/api/system/access-policy"
t "SMTP设置" "GET" "/api/system/smtp"
t "通知配置" "GET" "/api/system/notify-config"
t "更新全局策略" "PUT" "/api/system/policies" '{"ksm_enabled":"true","ha_enabled":"true"}'
t "更新密码策略" "PUT" "/api/system/password-policy" '{"min_length":"8","complexity":"high"}'
t "更新SMTP" "PUT" "/api/system/smtp" '{"server":"smtp.test.com","port":"25","from":"admin@test.com"}'
t "测试SMTP" "POST" "/api/system/smtp/test" '{"to":"test@test.com"}'

log ""
log "=== 十六、统计报表 ==="
t "平台总览" "GET" "/api/stats"
t "登录统计" "GET" "/api/stats/user-login"
t "审计日志" "GET" "/api/stats/audit"
t "使用时长" "GET" "/api/stats/usage-time"
t "告警统计" "GET" "/api/stats/alert-stats"

log ""
log "=== 十七、系统信息 ==="
t "系统信息" "GET" "/api/info"

log ""
log "=== 十八、前端页面 ==="
t "首页HTML" "GET" "/"
t "favicon" "GET" "/favicon.ico"

# 清理测试数据
log ""
log "=== 清理测试数据 ==="
if [ -n "$USER_ID" ]; then
    t "删除测试用户" "DELETE" "/api/users/$USER_ID"
fi

log ""
log "=== 测试汇总 ==="
log "通过: $PASS / 失败: $FAIL / 总计: $TOTAL"
log "完成: $(date)"

echo "Done! PASS=$PASS FAIL=$FAIL TOTAL=$TOTAL"
cat $OUT | grep "^PASS\|^FAIL" | cut -d'|' -f1 | sort | uniq -c
