#!/bin/bash
# 全面测试真实麒麟信安MC (端口8443) - 逐功能对照测试
# 不用 set -e, 允许单个测试失败继续执行

BASE="https://localhost:8443/mc"
COOKIE="/tmp/mc_test_cookie.txt"
OUT="/tmp/mc_test_results.txt"
rm -f $COOKIE $OUT

echo "========================================" | tee $OUT
echo " 麒麟信安MC全功能测试 $(date)" | tee -a $OUT
echo "========================================" | tee -a $OUT

# ===== 登录 =====
echo "" | tee -a $OUT
echo "【一、登录测试】" | tee -a $OUT

curl -sk -c $COOKIE "$BASE/" -o /dev/null 2>/dev/null
ENC_USER=$(echo -n "mcadmin" | openssl enc -aes-128-cbc -K "6b73766471776572747931343732353800" -iv "6b73766471776572747931343732353800" -base64 2>/dev/null)
ENC_PASS=$(echo -n '987qwe654asd*' | openssl enc -aes-128-cbc -K "6b73766471776572747931343732353800" -iv "6b73766471776572747931343732353800" -base64 2>/dev/null)

LOGIN_RESP=$(curl -sk -b $COOKIE -c $COOKIE "$BASE/user/loginCheck" -X POST -d "username=${ENC_USER}&password=${ENC_PASS}" 2>/dev/null)
FLAG=$(echo "$LOGIN_RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('flag',''))" 2>/dev/null)
if [ -z "$FLAG" ]; then FLAG="2"; fi

SESS_RESP=$(curl -sk -b $COOKIE -c $COOKIE "$BASE/user/successSession" -X POST -d "flag=${FLAG}&username=mcadmin" 2>/dev/null)
ORG_ID=$(echo "$SESS_RESP" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('orgId',''))" 2>/dev/null)
if [ -z "$ORG_ID" ]; then ORG_ID="1"; fi

curl -sk -b $COOKIE -c $COOKIE "$BASE/user/setOrgUser" -X POST -d "id=${ORG_ID}" -o /dev/null 2>/dev/null

# 验证登录成功
DASH_CODE=$(curl -sk -b $COOKIE "$BASE/monitoring/dashboard" -o /dev/null -w '%{http_code}' 2>/dev/null)
if [ "$DASH_CODE" = "200" ]; then
  echo "  ✓ 登录成功 (flag=$FLAG, orgId=$ORG_ID)" | tee -a $OUT
else
  echo "  ✗ 登录失败 (HTTP $DASH_CODE), flag=$FLAG" | tee -a $OUT
  echo "  loginCheck响应: $LOGIN_RESP" | tee -a $OUT
  echo "  successSession响应: $SESS_RESP" | tee -a $OUT
fi

# 辅助函数: 测试页面可访问性
test_page() {
  local url="$1"
  local name="$2"
  local code=$(curl -sk -b $COOKIE "$BASE/$url" -o /dev/null -w '%{http_code}' 2>/dev/null)
  local size=$(curl -sk -b $COOKIE "$BASE/$url" 2>/dev/null | wc -c)
  if [ "$code" = "200" ]; then
    echo "  ✓ $name ($url) [${size}B]" | tee -a $OUT
  else
    echo "  ✗ $name ($url) [HTTP $code]" | tee -a $OUT
  fi
}

# 辅助函数: 测试AJAX接口
test_ajax() {
  local url="$1"
  local name="$2"
  local method="${3:-GET}"
  local data="$4"
  
  if [ "$method" = "POST" ]; then
    RESP=$(curl -sk -b $COOKIE "$BASE/$url" -X POST -d "$data" \
      -H "X-Requested-With: XMLHttpRequest" -H "Content-Type: application/x-www-form-urlencoded" 2>/dev/null)
  else
    RESP=$(curl -sk -b $COOKIE "$BASE/$url" \
      -H "X-Requested-With: XMLHttpRequest" 2>/dev/null)
  fi
  local size=${#RESP}
  # 判断是否JSON
  IS_JSON=$(echo "$RESP" | python3 -c "import sys,json; json.load(sys.stdin); print('yes')" 2>/dev/null || echo "no")
  if [ "$IS_JSON" = "yes" ]; then
    echo "  ✓ $name [JSON ${size}B] $(echo "$RESP" | head -c 200)" | tee -a $OUT
  else
    if [ $size -gt 0 ]; then
      echo "  ~ $name [HTML/Other ${size}B]" | tee -a $OUT
    else
      echo "  ✗ $name [Empty response]" | tee -a $OUT
    fi
  fi
}

# ===== 二、Dashboard =====
echo "" | tee -a $OUT
echo "【二、Dashboard / 监控】" | tee -a $OUT
test_page "monitoring/dashboard" "Dashboard主页"
test_page "monitoring/charts" "统计图表页"
test_ajax "monitoring/getDashboard" "Dashboard数据(AJAX)"
test_ajax "monitoring/getVmStatusCount" "VM状态统计"
test_ajax "monitoring/getOnlineTrend" "在线趋势数据"
test_ajax "monitoring/getUserStatistics" "用户统计"
test_ajax "monitoring/getServerStatus" "服务器状态"
test_ajax "monitoring/getResourceUsage" "资源使用"
test_ajax "monitoring/getRecentAlerts" "最近告警"
test_ajax "monitoring/getUserRanking" "用户在线排名"
test_ajax "monitoring/getClientSystemType" "终端系统类型"

# ===== 三、桌面发布 - 黄金镜像 =====
echo "" | tee -a $OUT
echo "【三、桌面发布 - 黄金镜像】" | tee -a $OUT
test_page "image/list" "黄金镜像列表页"
test_ajax "image/getImageList" "镜像列表(AJAX)" "POST" "page=1&rows=20"
test_ajax "image/getImageDetail" "镜像详情(AJAX)" "POST" "id=1"
test_page "image/create" "创建镜像页"

# ===== 四、桌面发布 - 应用程序层 =====
echo "" | tee -a $OUT
echo "【四、桌面发布 - 应用程序层】" | tee -a $OUT
test_page "app/appLayer" "应用程序层页"

# ===== 五、桌面发布 - 桌面池 =====
echo "" | tee -a $OUT
echo "【五、桌面发布 - 桌面池/发布规则】" | tee -a $OUT
test_page "VM/desktopPoolList" "桌面池列表"
test_ajax "VM/getDesktopPoolList" "桌面池数据(AJAX)" "POST" "page=1&rows=20"
test_page "VM/publishRule" "发布规则页"

# ===== 六、桌面发布 - 软件库 =====
echo "" | tee -a $OUT
echo "【六、桌面发布 - 软件库】" | tee -a $OUT
test_page "app/softwareLibrary" "软件库页"
test_page "app/softwarePublish" "软件发布页"

# ===== 七、桌面发布 - 桌面规格 =====
echo "" | tee -a $OUT
echo "【七、桌面发布 - 桌面规格】" | tee -a $OUT
test_page "policy/desktopSpec" "桌面规格列表"
test_ajax "policy/getDesktopSpecList" "规格列表(AJAX)" "POST" "page=1&rows=20"

# ===== 八、虚拟机管理 =====
echo "" | tee -a $OUT
echo "【八、虚拟机管理】" | tee -a $OUT
test_page "VM/vmList" "虚拟机列表页"
test_ajax "VM/getVmList" "VM列表(AJAX)" "POST" "page=1&rows=20"
test_ajax "VM/getVmStatusCount" "VM状态计数(AJAX)"
test_page "VM/vmDetail" "VM详情页"
test_page "VM/vmBackup" "VM备份页"
test_page "VM/vmSnapshot" "VM快照页"
test_page "VM/vmSession" "VM会话页"

# ===== 九、云服务器 =====
echo "" | tee -a $OUT
echo "【九、云服务器】" | tee -a $OUT
test_page "VM/serverList" "云服务器列表"
test_ajax "VM/getServerList" "云服务器列表(AJAX)" "POST" "page=1&rows=20"

# ===== 十、主机管理 =====
echo "" | tee -a $OUT
echo "【十、主机管理】" | tee -a $OUT
test_page "host/list" "主机列表页"
test_ajax "host/getHostList" "主机列表(AJAX)" "POST" "page=1&rows=20"
test_ajax "host/getHostStatus" "主机状态(AJAX)"
test_page "host/detail" "主机详情页"
test_page "host/gpuList" "GPU列表页"
test_page "host/usbList" "USB设备页"
test_page "host/pciList" "PCI设备页"

# ===== 十一、网络管理 =====
echo "" | tee -a $OUT
echo "【十一、网络管理】" | tee -a $OUT
test_page "virtualSwitch/list" "虚拟交换机列表"
test_ajax "virtualSwitch/getList" "交换机列表(AJAX)" "POST" "page=1&rows=20"
test_page "network/securityGroup" "安全组页"
test_ajax "network/getSecurityGroupList" "安全组列表(AJAX)" "POST" "page=1&rows=20"
test_page "MACAddressPool/list" "MAC地址池"
test_ajax "MACAddressPool/getList" "MAC池列表(AJAX)" "POST" "page=1&rows=20"
test_page "network/subnetList" "子网管理页"

# ===== 十二、存储管理 =====
echo "" | tee -a $OUT
echo "【十二、存储管理】" | tee -a $OUT
test_page "storage/distributedStorage" "分布式存储页"
test_ajax "storage/getDistributedStorageList" "分布式存储(AJAX)" "POST" "page=1&rows=20"
test_page "storage/dataStorage" "数据存储页"
test_ajax "storage/getDataStorageList" "数据存储(AJAX)" "POST" "page=1&rows=20"
test_page "storage/centralStorage" "集中存储页"
test_page "storage/fcsan" "FCSAN页"
test_page "storage/ipsan" "IPSAN页"
test_page "storage/nas" "NAS页"

# ===== 十三、备份管理 =====
echo "" | tee -a $OUT
echo "【十三、备份管理】" | tee -a $OUT
test_page "backup/serverList" "备份服务器列表"
test_ajax "backup/getServerList" "备份服务器(AJAX)" "POST" "page=1&rows=20"
test_page "backup/vmBackupList" "VM备份列表"
test_page "backup/serverBackupList" "云服务器备份列表"

# ===== 十四、快照策略 =====
echo "" | tee -a $OUT
echo "【十四、快照策略】" | tee -a $OUT
test_page "VM/snapshotPolicyList" "快照策略列表"
test_ajax "VM/getSnapshotPolicyList" "快照策略(AJAX)" "POST" "page=1&rows=20"

# ===== 十五、用户管理 =====
echo "" | tee -a $OUT
echo "【十五、用户管理】" | tee -a $OUT
test_page "user/list" "用户列表页"
test_ajax "user/getUserList" "用户列表(AJAX)" "POST" "page=1&rows=20"
test_page "user/groupList" "用户组页"
test_ajax "user/getGroupList" "用户组(AJAX)" "POST" "page=1&rows=20"
test_page "auth/ldapServer" "LDAP服务器页"
test_page "auth/adDomain" "AD域页"

# ===== 十六、日志 =====
echo "" | tee -a $OUT
echo "【十六、日志管理】" | tee -a $OUT
test_page "app/serverEvent" "服务器事件日志"
test_ajax "app/getServerEventList" "服务器事件(AJAX)" "POST" "page=1&rows=20"
test_page "app/vmEvent" "虚拟机事件日志"
test_ajax "app/getVmEventList" "VM事件(AJAX)" "POST" "page=1&rows=20"
test_page "app/serverVirtualEvent" "服务器虚拟化事件"
test_page "app/auditEvent" "审核事件"
test_ajax "app/getAuditEventList" "审核事件(AJAX)" "POST" "page=1&rows=20"
test_page "app/vdeEvent" "VDE事件"
test_page "app/terminalAuditEvent" "终端审核事件"
test_page "app/storageLog" "存储日志"

# ===== 十七、告警 =====
echo "" | tee -a $OUT
echo "【十七、告警管理】" | tee -a $OUT
test_page "app/alertEvent" "告警事件页"
test_ajax "app/getAlertEventList" "告警列表(AJAX)" "POST" "page=1&rows=20"
test_page "app/alertSetting" "告警设置页"
test_ajax "app/getAlertSettingList" "告警设置(AJAX)" "POST" "page=1&rows=20"

# ===== 十八、录屏审计 =====
echo "" | tee -a $OUT
echo "【十八、录屏审计】" | tee -a $OUT
test_page "app/recordingList" "录屏列表"
test_page "app/recordingLabel" "录屏标签"

# ===== 十九、终端管理 =====
echo "" | tee -a $OUT
echo "【十九、终端管理】" | tee -a $OUT
test_page "client/list" "终端列表"
test_ajax "client/getClientList" "终端列表(AJAX)" "POST" "page=1&rows=20"
test_page "client/taskList" "终端任务列表"

# ===== 二十、系统管理 =====
echo "" | tee -a $OUT
echo "【二十、系统管理】" | tee -a $OUT
test_page "user/adminList" "管理员账号"
test_ajax "user/getAdminList" "管理员列表(AJAX)" "POST" "page=1&rows=20"
test_page "app/passwordPolicy" "密码策略"
test_ajax "app/getPasswordPolicy" "密码策略(AJAX)"
test_page "app/accessPolicy" "访问策略"
test_ajax "app/getAccessPolicy" "访问策略(AJAX)"
test_page "app/roleManagement" "角色管理"

# ===== 二十一、系统配置 =====
echo "" | tee -a $OUT
echo "【二十一、系统配置】" | tee -a $OUT
test_page "app/globalPolicy" "全局策略"
test_ajax "app/getGlobalPolicy" "全局策略(AJAX)"
test_page "app/smtpSetting" "SMTP设置"
test_page "app/haSetting" "HA设置"
test_page "app/licenseSetting" "许可证"
test_page "app/labelSetting" "标签设置"
test_page "app/affinityGroup" "亲和组"
test_page "app/dynamicScaling" "动态扩展"
test_page "app/orgManagement" "组织管理"

# ===== 二十二、任务/审批中心 =====
echo "" | tee -a $OUT
echo "【二十二、任务中心/审批中心】" | tee -a $OUT
test_page "app/taskCenter" "任务中心"
test_ajax "app/getTaskList" "任务列表(AJAX)" "POST" "page=1&rows=20"
test_page "app/approvalCenter" "审批中心"
test_ajax "app/getApprovalList" "审批列表(AJAX)" "POST" "page=1&rows=20"

# ===== 二十三、维护工具 =====
echo "" | tee -a $OUT
echo "【二十三、维护工具】" | tee -a $OUT
test_page "app/debugLog" "调试日志"
test_page "app/oneKeyDetection" "一键检测"
test_page "app/systemUpgrade" "系统升级"

# ===== 二十四、回收站 =====
echo "" | tee -a $OUT
echo "【二十四、回收站】" | tee -a $OUT
test_page "VM/recycleBin" "回收站"
test_ajax "VM/getRecycleBinList" "回收站列表(AJAX)" "POST" "page=1&rows=20"

# ===== 二十五、统计报表 =====
echo "" | tee -a $OUT
echo "【二十五、统计报表】" | tee -a $OUT
test_page "app/userLoginStats" "用户登录统计"
test_page "app/vmUsageStats" "VM使用统计"
test_page "app/serverStats" "服务器统计"
test_page "app/storageStats" "存储统计"
test_page "app/faultStats" "故障统计"
test_page "app/clientStats" "终端统计"
test_page "app/alarmStats" "告警统计"
test_page "app/auditStats" "审计统计"
test_page "app/usageTimeStats" "使用时长统计"

# ===== 二十六、文件管理 =====
echo "" | tee -a $OUT
echo "【二十六、文件管理】" | tee -a $OUT
test_page "app/isoManagement" "ISO管理"

# ===== 汇总 =====
echo "" | tee -a $OUT
echo "========================================" | tee -a $OUT
TOTAL=$(grep -c "  [✓✗~]" $OUT)
PASS=$(grep -c "  ✓" $OUT)
FAIL=$(grep -c "  ✗" $OUT)
PARTIAL=$(grep -c "  ~" $OUT)
echo "汇总: 共${TOTAL}项, 通过${PASS}项, 失败${FAIL}项, 部分${PARTIAL}项" | tee -a $OUT
echo "========================================" | tee -a $OUT

echo ""
echo "详细结果已保存到 $OUT"
