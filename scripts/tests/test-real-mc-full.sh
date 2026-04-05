#!/bin/bash
# 全面测试真实麒麟信安MC的每个功能API
# 记录所有API响应，用于与我们的系统对比

COOKIE_FILE="/tmp/mc_test_session.txt"
BASE="https://localhost:8443/mc"
RESULT_FILE="/tmp/mc_full_test_results.txt"
rm -f $COOKIE_FILE $RESULT_FILE

# AES encryption
encrypt() {
    local KEY_HEX=$(echo -n 'ksvdqwerty147258' | xxd -p)
    local IV_HEX=$(echo -n 'ksvdqwerty147258' | xxd -p)
    echo -n "$1" | openssl enc -aes-128-cbc -K $KEY_HEX -iv $IV_HEX -base64 2>/dev/null | tr -d '\n'
}

log() {
    echo "$1" | tee -a $RESULT_FILE
}

# Test counter
PASS=0
FAIL=0
TOTAL=0

test_api() {
    local NAME="$1"
    local METHOD="$2"
    local URL="$3"
    local DATA="$4"
    TOTAL=$((TOTAL+1))

    local RESP
    if [ "$METHOD" = "GET" ]; then
        RESP=$(curl -sk -b $COOKIE_FILE -c $COOKIE_FILE \
            -H "X-Requested-With: XMLHttpRequest" \
            -w "\n__HTTP_CODE:%{http_code}__SIZE:%{size_download}" \
            "$BASE/$URL" 2>/dev/null)
    else
        RESP=$(curl -sk -b $COOKIE_FILE -c $COOKIE_FILE \
            -H "X-Requested-With: XMLHttpRequest" \
            -d "$DATA" \
            -w "\n__HTTP_CODE:%{http_code}__SIZE:%{size_download}" \
            "$BASE/$URL" 2>/dev/null)
    fi

    local HTTP_CODE=$(echo "$RESP" | grep -oP '__HTTP_CODE:\K[0-9]+' | tail -1)
    local SIZE=$(echo "$RESP" | grep -oP '__SIZE:\K[0-9]+' | tail -1)
    local BODY=$(echo "$RESP" | sed 's/__HTTP_CODE:[0-9]*__SIZE:[0-9]*$//')

    # Truncate body for readability
    local SHORT_BODY=$(echo "$BODY" | head -c 500)

    if [ "$HTTP_CODE" = "200" ] && [ "$SIZE" -gt 10 ] 2>/dev/null; then
        PASS=$((PASS+1))
        log "[PASS] $NAME | HTTP:$HTTP_CODE | Size:$SIZE | ${SHORT_BODY}"
    else
        FAIL=$((FAIL+1))
        log "[FAIL] $NAME | HTTP:$HTTP_CODE | Size:$SIZE | ${SHORT_BODY}"
    fi
}

# ====== LOGIN ======
log "=========================================="
log "麒麟信安云 MC 全功能测试"
log "时间: $(date)"
log "=========================================="
log ""

ENC_USER=$(encrypt "mcadmin")
ENC_PASS=$(encrypt '987qwe654asd*')

# Step 1: Get session
curl -sk -c $COOKIE_FILE "$BASE/" > /dev/null 2>&1

# Step 2: loginCheck
LOGIN_RESP=$(curl -sk -b $COOKIE_FILE -c $COOKIE_FILE \
    --data-urlencode "username=$ENC_USER" \
    --data-urlencode "password=$ENC_PASS" \
    -H "X-Requested-With: XMLHttpRequest" \
    "$BASE/user/loginCheck" 2>/dev/null)
FLAG=$(echo "$LOGIN_RESP" | grep -oP '"flag"\s*:\s*\K[0-9]+')
log "登录 loginCheck: flag=$FLAG, resp=$LOGIN_RESP"

# Step 3: successSession (accept any flag)
SS_RESP=$(curl -sk -b $COOKIE_FILE -c $COOKIE_FILE \
    -d "flag=$FLAG&username=mcadmin" \
    -H "X-Requested-With: XMLHttpRequest" \
    "$BASE/user/successSession" 2>/dev/null)
log "successSession: $SS_RESP"

ORG_ID=$(echo "$SS_RESP" | grep -oP '"orgId"\s*:\s*"\K[^"]*')
if [ -z "$ORG_ID" ]; then
    ORG_ID=$(echo "$SS_RESP" | grep -oP '"orgId"\s*:\s*\K[0-9]+')
fi
log "OrgId: $ORG_ID"

# Step 4: setOrgUser
if [ -n "$ORG_ID" ]; then
    SO_RESP=$(curl -sk -b $COOKIE_FILE -c $COOKIE_FILE \
        -d "id=$ORG_ID" \
        -H "X-Requested-With: XMLHttpRequest" \
        "$BASE/user/setOrgUser" 2>/dev/null)
    log "setOrgUser: $SO_RESP"
fi

# Verify login by checking dashboard
DASH_CODE=$(curl -sk -b $COOKIE_FILE -o /dev/null -w '%{http_code}' "$BASE/monitoring/dashboard" 2>/dev/null)
log "Dashboard访问: HTTP $DASH_CODE"
log ""

if [ "$DASH_CODE" != "200" ]; then
    log "ERROR: 登录失败，无法访问Dashboard"
    log "尝试flag=2强制登录..."
    SS_RESP2=$(curl -sk -b $COOKIE_FILE -c $COOKIE_FILE \
        -d "flag=2&username=mcadmin" \
        -H "X-Requested-With: XMLHttpRequest" \
        "$BASE/user/successSession" 2>/dev/null)
    log "强制successSession: $SS_RESP2"
    ORG_ID2=$(echo "$SS_RESP2" | grep -oP '"orgId"\s*:\s*"\K[^"]*')
    if [ -z "$ORG_ID2" ]; then
        ORG_ID2=$(echo "$SS_RESP2" | grep -oP '"orgId"\s*:\s*\K[0-9]+')
    fi
    if [ -n "$ORG_ID2" ]; then
        curl -sk -b $COOKIE_FILE -c $COOKIE_FILE \
            -d "id=$ORG_ID2" \
            -H "X-Requested-With: XMLHttpRequest" \
            "$BASE/user/setOrgUser" > /dev/null 2>&1
    fi
    DASH_CODE2=$(curl -sk -b $COOKIE_FILE -o /dev/null -w '%{http_code}' "$BASE/monitoring/dashboard" 2>/dev/null)
    log "重试Dashboard: HTTP $DASH_CODE2"
fi

log ""
log "=========================================="
log "一、仪表板 (Dashboard)"
log "=========================================="
test_api "仪表板页面" GET "monitoring/dashboard"
test_api "图表数据页面" GET "monitoring/charts"
test_api "VM使用统计AJAX" POST "monitoring/getVmUsageJson" ""
test_api "在线趋势AJAX" POST "monitoring/getOnlineTrendJson" "hours=6"
test_api "用户统计AJAX" POST "monitoring/getUserStatJson" ""
test_api "服务器状态AJAX" POST "monitoring/getServerStatusJson" ""
test_api "资源使用AJAX" POST "monitoring/getResourceUsageJson" ""
test_api "最近告警AJAX" POST "monitoring/getRecentAlertsJson" ""
test_api "用户排名AJAX" POST "monitoring/getUserRankingJson" ""
test_api "终端类型统计" POST "monitoring/getTerminalTypeJson" ""

log ""
log "=========================================="
log "二、桌面发布-黄金镜像"
log "=========================================="
test_api "黄金镜像列表页" GET "image/list"
test_api "镜像列表AJAX" POST "image/listJson" ""
test_api "镜像详情AJAX" POST "image/getImageDetail" "id=1"
test_api "应用分层列表" GET "image/appLayerList"
test_api "应用分层数据" POST "image/appLayerListJson" ""

log ""
log "=========================================="
log "三、桌面发布-桌面规格"
log "=========================================="
test_api "桌面规格列表页" GET "policy/list"
test_api "规格列表AJAX" POST "policy/listJson" ""
test_api "规格详情AJAX" POST "policy/getPolicyDetail" "id=1"

log ""
log "=========================================="
log "四、桌面发布-发布规则"
log "=========================================="
test_api "发布规则列表页" GET "userSelect/editList"
test_api "发布规则AJAX" POST "userSelect/editListJson" ""
test_api "桌面池列表" GET "desktopPool/list"
test_api "桌面池AJAX" POST "desktopPool/listJson" ""
test_api "应用管控列表" GET "app/appControl"
test_api "应用库" GET "app/appLibrary"
test_api "软件发布" GET "app/softPublish"

log ""
log "=========================================="
log "五、用户管理"
log "=========================================="
test_api "用户列表页" GET "user/listKsvdUsers"
test_api "用户列表AJAX" POST "user/listKsvdUsersJson" ""
test_api "用户组列表页" GET "user/listKsvdGroups"
test_api "用户组AJAX" POST "user/listKsvdGroupsJson" ""
test_api "LDAP服务器列表" GET "auth/listAuthProviders"
test_api "LDAP服务器AJAX" POST "auth/listAuthProvidersJson" ""

log ""
log "=========================================="
log "六、虚拟机管理"
log "=========================================="
test_api "会话管理页" GET "VM/sessions"
test_api "会话列表AJAX" POST "VM/sessionsJson" ""
test_api "桌面虚拟机页" GET "VM/desktopVms"
test_api "桌面虚拟机AJAX" POST "VM/desktopVmsJson" ""
test_api "云服务器页" GET "VM/cloudServers"
test_api "云服务器AJAX" POST "VM/cloudServersJson" ""
test_api "虚拟应用组页" GET "VM/appGroups"
test_api "虚拟应用会话页" GET "VM/appSessions"
test_api "VM详情AJAX" POST "VM/getVmDetail" "id=1"
test_api "VM快照列表" POST "VM/getVmSnapshots" "vmId=1"
test_api "VM监控数据" POST "VM/getVmMonitor" "vmId=1"
test_api "VNC控制台URL" POST "VM/getConsoleUrl" "vmId=1"

log ""
log "=========================================="
log "七、主机/一体机管理"
log "=========================================="
test_api "主机列表页" GET "host/list"
test_api "主机列表AJAX" POST "host/listJson" ""
test_api "主机详情-概要" POST "host/getHostDetail" "id=1"
test_api "主机详情-网络" POST "host/getHostNetwork" "id=1"
test_api "主机详情-监控" POST "host/getHostMonitor" "id=1"
test_api "主机详情-配置" POST "host/getHostConfig" "id=1"
test_api "主机详情-GPU" POST "host/getHostGpu" "id=1"
test_api "主机详情-VM列表" POST "host/getHostVms" "id=1"
test_api "主机详情-云服务器" POST "host/getHostCloudServers" "id=1"
test_api "主机详情-USB" POST "host/getHostUsb" "id=1"
test_api "主机详情-PCI" POST "host/getHostPci" "id=1"

log ""
log "=========================================="
log "八、网络管理"
log "=========================================="
test_api "网络列表页" GET "network/list"
test_api "网络列表AJAX" POST "network/listJson" ""
test_api "虚拟交换机" GET "virtualSwitch/list"
test_api "虚拟交换机AJAX" POST "virtualSwitch/listJson" ""
test_api "安全组列表" GET "network/securityGroups"
test_api "安全组AJAX" POST "network/securityGroupsJson" ""
test_api "MAC池列表" GET "MACAddressPool/list"
test_api "MAC池AJAX" POST "MACAddressPool/listJson" ""

log ""
log "=========================================="
log "九、存储管理"
log "=========================================="
test_api "存储域列表页" GET "storage/list"
test_api "存储域AJAX" POST "storage/listJson" ""
test_api "存储详情" POST "storage/getStorageDetail" "id=1"
test_api "分布式存储" GET "storage/distributed"
test_api "集中存储" GET "storage/centralized"
test_api "FCSAN" GET "storage/fcsan"
test_api "IPSAN" GET "storage/ipsan"
test_api "NAS存储" GET "storage/nas"

log ""
log "=========================================="
log "十、备份管理"
log "=========================================="
test_api "备份服务器页" GET "backup/backupServer"
test_api "备份服务器AJAX" POST "backup/backupServerListJson" ""
test_api "备份列表页" GET "backup/list"
test_api "备份列表AJAX" POST "backup/listJson" ""

log ""
log "=========================================="
log "十一、快照策略"
log "=========================================="
test_api "快照策略页" GET "VM/snapshotPolicyList"
test_api "快照策略AJAX" POST "VM/snapshotPolicyListJson" ""

log ""
log "=========================================="
log "十二、日志与告警"
log "=========================================="
test_api "服务器事件日志页" GET "app/eventList"
test_api "事件日志AJAX" POST "app/eventListJson" "type=server"
test_api "VM事件AJAX" POST "app/eventListJson" "type=vm"
test_api "审核日志页" GET "app/auditList"
test_api "审核日志AJAX" POST "app/auditListJson" ""
test_api "告警列表页" GET "app/alertList"
test_api "告警列表AJAX" POST "app/alertListJson" ""
test_api "录屏审计" GET "app/recordList"
test_api "录屏列表AJAX" POST "app/recordListJson" ""

log ""
log "=========================================="
log "十三、终端管理"
log "=========================================="
test_api "终端列表页" GET "client/index"
test_api "终端列表AJAX" POST "client/listJson" ""
test_api "终端任务AJAX" POST "client/taskListJson" ""

log ""
log "=========================================="
log "十四、系统管理"
log "=========================================="
test_api "管理员列表页" GET "app/adminList"
test_api "管理员AJAX" POST "app/adminListJson" ""
test_api "密码策略页" GET "app/passwordPolicy"
test_api "密码策略AJAX" POST "app/getPasswordPolicy" ""
test_api "访问策略页" GET "app/accessPolicy"
test_api "访问策略AJAX" POST "app/getAccessPolicy" ""
test_api "角色管理页" GET "app/roleSetting"
test_api "角色AJAX" POST "app/roleSettingJson" ""
test_api "全局策略页" GET "app/systemConfig"
test_api "全局策略AJAX" POST "app/getSystemConfig" ""
test_api "SMTP设置页" GET "app/smtpConfig"
test_api "SMTP设置AJAX" POST "app/getSmtpConfig" ""
test_api "HA设置页" GET "app/haConfig"
test_api "HA设置AJAX" POST "app/getHaConfig" ""
test_api "许可证页" GET "app/licenseSetting"
test_api "许可证AJAX" POST "app/getLicenseInfo" ""
test_api "标签设置页" GET "generalSettings/listLabel"
test_api "标签AJAX" POST "generalSettings/listLabelJson" ""
test_api "亲和组页" GET "generalSettings/listAffinity"
test_api "亲和组AJAX" POST "generalSettings/listAffinityJson" ""
test_api "DRS设置页" GET "generalSettings/drsSetting"
test_api "DRS设置AJAX" POST "generalSettings/getDrsConfig" ""
test_api "DPM设置页" GET "generalSettings/dpmSetting"
test_api "DPM设置AJAX" POST "generalSettings/getDpmConfig" ""
test_api "代理服务器页" GET "generalSettings/proxyServerSettings"
test_api "邮件服务器页" GET "generalSettings/mailServerList"
test_api "动态设置页" GET "generalSettings/dynamicSetting"
test_api "一体机列表" GET "generalSettings/listServer"
test_api "一体机AJAX" POST "generalSettings/listServerJson" ""

log ""
log "=========================================="
log "十五、任务中心与审批"
log "=========================================="
test_api "任务中心页" GET "app/taskCenter"
test_api "任务AJAX" POST "app/taskCenterJson" ""
test_api "审批中心页" GET "app/approvalCenter"
test_api "审批AJAX" POST "app/approvalCenterJson" ""

log ""
log "=========================================="
log "十六、维护工具"
log "=========================================="
test_api "一键检测页" GET "app/oneClickDetection"
test_api "一键检测AJAX" POST "app/getDetectionResult" ""
test_api "回收站页" GET "app/recycleBin"
test_api "回收站AJAX" POST "app/recycleBinJson" ""
test_api "维护工具页" GET "app/maintenance"
test_api "文件管理页" GET "app/fileManage"
test_api "文件列表AJAX" POST "app/fileManageJson" ""

log ""
log "=========================================="
log "十七、统计报表"
log "=========================================="
test_api "登录统计" GET "monitoring/charts"
test_api "统计图表AJAX" POST "monitoring/getChartsData" ""
test_api "分支机构Dashboard" GET "branch/dashboard"
test_api "分支机构AJAX" POST "branch/dashboardJson" ""

log ""
log "=========================================="
log "测试总结"
log "=========================================="
log "通过: $PASS"
log "失败: $FAIL"
log "总计: $TOTAL"
log "完成时间: $(date)"
