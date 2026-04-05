#!/bin/bash
# 基于正确的Grails controller/action结构测试所有MC API
COOKIE_FILE="/tmp/mc_v2_session.txt"
BASE="https://localhost:8443/mc"
OUT="/tmp/mc_api_test_v2.txt"
rm -f $COOKIE_FILE $OUT

encrypt() {
    local KEY_HEX=$(echo -n 'ksvdqwerty147258' | xxd -p)
    local IV_HEX=$(echo -n 'ksvdqwerty147258' | xxd -p)
    echo -n "$1" | openssl enc -aes-128-cbc -K $KEY_HEX -iv $IV_HEX -base64 2>/dev/null | tr -d '\n'
}

log() { echo "$1" >> $OUT; }
PASS=0; FAIL=0; TOTAL=0

# 通用测试函数
t() {
    local NAME="$1" URL="$2" METHOD="${3:-GET}" DATA="$4"
    TOTAL=$((TOTAL+1))
    local OPTS="-sk -b $COOKIE_FILE -c $COOKIE_FILE -H X-Requested-With:XMLHttpRequest -w |%{http_code}|%{size_download}"
    local RESP
    if [ "$METHOD" = "POST" ]; then
        RESP=$(curl $OPTS -d "$DATA" "$BASE/$URL" 2>/dev/null)
    else
        RESP=$(curl $OPTS "$BASE/$URL" 2>/dev/null)
    fi
    local CODE=$(echo "$RESP" | grep -oP '\|(\d+)\|\d+$' | cut -d'|' -f2)
    local SIZE=$(echo "$RESP" | grep -oP '\|\d+\|(\d+)$' | cut -d'|' -f2)
    local BODY=$(echo "$RESP" | sed 's/|[0-9]*|[0-9]*$//' | head -c 300)
    # 判断是否是JSON
    local IS_JSON="N"
    echo "$BODY" | python3 -c "import sys,json;json.load(sys.stdin)" 2>/dev/null && IS_JSON="Y"
    
    if [ "$CODE" = "200" ] && [ "${SIZE:-0}" -gt 5 ] 2>/dev/null; then
        PASS=$((PASS+1))
        log "PASS|$NAME|$CODE|$SIZE|JSON:$IS_JSON|$BODY"
    else
        FAIL=$((FAIL+1))
        log "FAIL|$NAME|$CODE|$SIZE|JSON:$IS_JSON|$BODY"
    fi
}

# LOGIN
ENC_USER=$(encrypt "mcadmin")
ENC_PASS=$(encrypt '987qwe654asd*')
curl -sk -c $COOKIE_FILE "$BASE/" > /dev/null 2>&1
LR=$(curl -sk -b $COOKIE_FILE -c $COOKIE_FILE --data-urlencode "username=$ENC_USER" --data-urlencode "password=$ENC_PASS" -H "X-Requested-With: XMLHttpRequest" "$BASE/user/loginCheck" 2>/dev/null)
FLAG=$(echo "$LR" | python3 -c "import sys,json;print(json.load(sys.stdin).get('flag',''))" 2>/dev/null)
log "LOGIN: flag=$FLAG resp=$LR"
curl -sk -b $COOKIE_FILE -c $COOKIE_FILE -d "flag=${FLAG:-2}&username=mcadmin" -H "X-Requested-With: XMLHttpRequest" "$BASE/user/successSession" > /dev/null 2>&1
curl -sk -b $COOKIE_FILE -c $COOKIE_FILE -d "id=0" -H "X-Requested-With: XMLHttpRequest" "$BASE/user/setOrgUser" > /dev/null 2>&1

# 验证登录
DC=$(curl -sk -b $COOKIE_FILE -o /dev/null -w '%{http_code}' "$BASE/monitoring/dashboard" 2>/dev/null)
log "VERIFY: dashboard=$DC"
if [ "$DC" != "200" ]; then
    log "LOGIN FAILED - retrying with flag=2"
    curl -sk -c $COOKIE_FILE "$BASE/" > /dev/null 2>&1
    LR=$(curl -sk -b $COOKIE_FILE -c $COOKIE_FILE --data-urlencode "username=$ENC_USER" --data-urlencode "password=$ENC_PASS" -H "X-Requested-With: XMLHttpRequest" "$BASE/user/loginCheck" 2>/dev/null)
    curl -sk -b $COOKIE_FILE -c $COOKIE_FILE -d "flag=2&username=mcadmin" -H "X-Requested-With: XMLHttpRequest" "$BASE/user/successSession" > /dev/null 2>&1
    curl -sk -b $COOKIE_FILE -c $COOKIE_FILE -d "id=0" -H "X-Requested-With: XMLHttpRequest" "$BASE/user/setOrgUser" > /dev/null 2>&1
fi

log ""
log "=== 一、仪表板 Dashboard ==="
t "仪表板页面" "monitoring/dashboard"
t "图表页面" "monitoring/charts"
t "会话列表" "monitoring/sessions"
t "服务器列表" "monitoring/servers"
t "告警事件" "monitoring/alarmEvents"
t "告警设置" "monitoring/alarmSettings"
t "服务器事件" "monitoring/serverEvents"
t "审核事件" "monitoring/auditEvents"
t "会话事件" "monitoring/sessionEvents"
t "虚拟化事件" "monitoring/serverVirtualEvents"
t "VDE事件" "monitoring/vdeEvents"
t "终端审核" "monitoring/clientAuditEvents"
t "MAC地址" "monitoring/macAddresses"
t "共享存储状态" "monitoring/sharedStorageStatus"
t "虚拟存储状态" "monitoring/virtualStorageStatus"
t "新监控" "monitoringNew/monitoringNew"

log ""
log "=== 二、桌面发布-黄金镜像 ==="
t "镜像列表" "image/list"
t "应用分层列表" "image/listAppLayers"
t "镜像操作列表" "image/listImageOps"
t "镜像版本管理" "image/listImageVerManage"

log ""
log "=== 三、桌面发布-桌面规格 ==="
t "规格列表" "policy/list"
t "分支集群" "policy/listBranchClusters"

log ""
log "=== 四、桌面发布-发布规则/桌面池 ==="
t "发布规则编辑列表" "userSelect/editList"
t "桌面池列表" "desktopPool/list"

log ""
log "=== 五、应用管控 ==="
t "内置规则" "imageApp/builtinRule"
t "自定义应用" "imageApp/customApp"
t "应用库" "imageApp/listAppLib"
t "一体机应用" "imageApp/listMachineApp"

log ""
log "=== 六、虚拟应用 ==="
t "虚拟应用组" "virtualApp/virtualAppGroups"
t "应用会话" "virtualApp/appSessions"

log ""
log "=== 七、用户管理 ==="
t "用户列表" "user/listKsvdUsers"
t "用户组列表" "user/listKsvdGroups"
t "角色列表" "user/listRoles"
t "终端用户绑定" "user/terminalAndUser"
t "LDAP服务列表" "auth/listAuthProviders"

log ""
log "=== 八、虚拟机/会话 ==="
t "会话管理" "VM/sessions"
t "桌面虚拟机" "VM/desktopVms"
t "快照列表" "VM/snapshotList"
t "快照策略" "VM/snapStrategy"
t "备份列表" "VM/backups"

log ""
log "=== 九、云服务器 ==="
t "云服务器列表" "serverVirtualization/index"

log ""
log "=== 十、主机管理 ==="
t "主机列表" "host/list" "GET" ""
# 真正的host listing在servers controller
t "服务器列表页" "servers/listServer"
t "集群主节点" "servers/clusterMasters"

log ""
log "=== 十一、网络 ==="
t "网络列表" "network/list"
t "虚拟交换机" "network/configuration"
t "安全组" "network/securityGroup"
t "MAC池" "MACAddressPool/list"
t "子网" "network/subNet"
t "VLAN池" "network/vlanPool"
t "端口镜像" "network/portMirroring"
t "端口组" "network/portGroup"
t "网络规则" "network/networkConfigure"

log ""
log "=== 十二、存储 ==="
t "存储列表" "storage/dataStore"
t "新存储" "storageNew/storageNew"
t "虚拟存储设置" "storage/virtualStorageSettings"

log ""
log "=== 十三、备份 ==="
t "备份服务器" "backup/backupServer"

log ""
log "=== 十四、日志告警统计 ==="
t "登录统计" "statistics/userLoginInfo"
t "在线用户统计" "statistics/onlineUserNumberInfo"
t "操作事件统计" "statistics/operationEventInfo"
t "操作用户统计" "statistics/operationUserInfo"
t "未使用VM统计" "statistics/unusedVMInfo"
t "使用时长统计" "statistics/usageTimeInfo"
t "用户故障统计" "statistics/userFaultInfo"
t "故障类型统计" "statistics/faultTypeInfo"
t "服务器告警统计" "statistics/serverAlarmInfo"
t "告警统计" "statistics/alarmStatisticsInfo"
t "终端状态" "statistics/clientStateInfo"
t "云服务器资源" "statistics/serverVirtualResource"
t "云服务器TOP" "statistics/serverVirtualTop"
t "数据拷贝审计" "statistics/dataCopyAudit"
t "VM告警" "statistics/vmAlarmInfo"
t "VM恢复" "statistics/vmRecoverInfo"
t "VM状态" "statistics/vmStatusInfo"
t "USB使用" "statistics/userUsbInfo"
t "在线终端" "statistics/onlineClientInfo"

log ""
log "=== 十五、系统管理 ==="
t "关于页" "app/about"
t "审批中心" "app/approvalCenter"
t "任务中心" "app/taskCenter"
t "审计列表" "app/auditList"
t "告警列表" "app/alertList" "GET" ""
# alertList可能不存在，用alarmEvents
t "文件管理" "app/fileManage"
t "一键检测" "app/oneClickDetection"
t "清除事件设置" "app/purgeEventSettings"

log ""
log "=== 十六、常规设置 ==="
t "全局策略" "generalSettings/showGlobalPolicy"
t "HA设置" "generalSettings/showHA"
t "许可证" "generalSettings/showLicense"
t "密码策略" "generalSettings/showPasswordState"
t "标签设置" "generalSettings/labelSettings"
t "亲和组" "generalSettings/affinityGroup"
t "DRS设置" "generalSettings/drsSetting"
t "DPM设置" "generalSettings/dpmSetting"
t "动态设置" "generalSettings/dynamicSetting"
t "代理服务器" "generalSettings/proxyServerSettings"
t "邮件服务器" "generalSettings/mailServerList"
t "视频重定向" "generalSettings/videoRedirectList"
t "欢迎消息" "generalSettings/welcomeMessageList"
t "一体机列表" "generalSettings/listServer"
t "列表标签" "generalSettings/listLabel"
t "列表亲和组" "generalSettings/listAffinity"
t "VDE设置" "generalSettings/vdeSettings"
t "流量服务器" "generalSettings/trafficServerSettings"
t "RDP设置" "generalSettings/setRDP"
t "SPICE设置" "generalSettings/setSPICE"

log ""
log "=== 十七、终端管理 ==="
t "终端列表" "client/index"

log ""
log "=== 十八、组织管理 ==="
t "组织列表" "organization/list"

log ""
log "=== 十九、回收站 ==="
t "回收站" "recycleBin/index"
t "服务器回收" "serverRecycle/index"

log ""
log "=== 二十、分支机构 ==="
t "分支Dashboard" "branch/dashboard"
t "分支服务器" "branch/branchServers"
t "分支会话" "branch/branchSessions"

log ""
log "=== 二十一、发布部署 ==="
t "发布列表" "leaf/listReleases"
t "部署列表" "leaf/listDeployments"

log ""
log "=== 二十二、访问策略 ==="
t "访问策略" "visitPolicy/visitPolicys"

log ""
log "=== 二十三、角色管理 ==="
t "角色列表" "user/listRoles"

log ""
log "=== 测试汇总 ==="
log "通过: $PASS / 失败: $FAIL / 总计: $TOTAL"
log "完成: $(date)"

echo "Done! PASS=$PASS FAIL=$FAIL TOTAL=$TOTAL"
cat $OUT | grep "^PASS\|^FAIL" | cut -d'|' -f1 | sort | uniq -c
