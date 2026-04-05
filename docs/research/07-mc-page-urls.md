# MC管理控制台 - 完整页面URL映射

## 登录信息
- **AES加密**: key=iv=`ksvdqwerty147258`, AES-128-CBC, PKCS7, Base64输出
- **登录流程**: 
  1. GET /mc/ → 获取JSESSIONID
  2. POST /mc/user/loginCheck (username=AES加密, password=AES加密) → JSON {flag,msg,url}
  3. POST /mc/user/successSession (flag=N, username=明文) → JSON {result,orgId}
  4. POST /mc/user/setOrgUser (id=orgId) → JSON {success}
  5. 跳转到目标URL

## 已成功抓取的页面 (96个)

### 🏠 Dashboard
| URL | 描述 | 大小 |
|-----|------|------|
| monitoring/dashboard | 主控看板 | 45,625 |
| monitoring/charts | 图表页 | 40,885 |

### 📦 桌面发布
| URL | 描述 | 大小 |
|-----|------|------|
| image/list | 黄金镜像列表 | 58,276 |
| image/listAppLayers | 应用层列表 | 50,348 |
| userSelect/editList | 桌面分配 | 64,005 |
| policy/list | 桌面规格/会话策略 | 72,197 |
| desktopPool/list | 桌面池列表 | 50,244 |
| imageApp/builtinRule | 内置应用规则 | 42,837 |
| imageApp/customApp | 自定义应用 | 42,838 |
| imageApp/listAppLib | 应用库 | 45,337 |
| imageApp/listMachineApp | 机器应用 | 44,973 |

### 👥 用户管理
| URL | 描述 | 大小 |
|-----|------|------|
| user/listKsvdUsers | 用户列表 | 76,886 |
| user/listKsvdGroups | 用户组列表 | 87,670 |
| auth/listAuthProviders | LDAP服务器 | 71,877 |
| user/terminalAndUser | 终端与用户 | 42,922 |

### 🖥️ 虚拟机管理
| URL | 描述 | 大小 |
|-----|------|------|
| VM/desktopVms | 云桌面虚拟机列表 | 68,113 |
| VM/snapshotList | 快照列表 | 5,042 |
| VM/snapStrategy | 快照策略 | 82,917 |
| VM/snapSettings | 快照设置 | 75,602 |

### 🖧 主机管理
| URL | 描述 | 大小 |
|-----|------|------|
| servers/listServer | 服务器列表 | 54,996 |
| servers/clusterMasters | 集群管理 | 82,408 |

### 🌐 网络管理
| URL | 描述 | 大小 |
|-----|------|------|
| network/list | 网络列表 | 68,340 |
| network/securityGroup | 安全组 | 72,171 |
| network/macAddress | MAC地址管理 | 47,696 |
| MACAddressPool/list | MAC地址池 | 40,238 |
| network/networkConfigure | 网络配置规则 | 66,045 |
| network/vlanPool | VLAN池 | 70,105 |
| network/subNet | 子网管理 | 68,534 |
| network/portMirroring | 端口镜像 | 68,300 |

### 💾 存储管理
| URL | 描述 | 大小 |
|-----|------|------|
| storage/dataStore | 数据存储 | 66,749 |
| storageNew/storageNew | 新存储管理 | 68,117 |

### 📊 监控/日志/告警
| URL | 描述 | 大小 |
|-----|------|------|
| monitoring/serverEvents | 服务器事件 | 71,524 |
| monitoring/sessionEvents | 会话事件 | 70,829 |
| monitoring/alarmEvents | 告警事件 | 72,132 |
| monitoring/alarmSettings | 告警设置 | 68,886 |
| monitoring/auditEvents | 审核事件 | 78,942 |
| monitoring/clientAuditEvents | 终端审核事件 | 71,060 |
| monitoring/vdeEvents | VDE事件 | 69,861 |
| monitoring/serverVirtualEvents | 服务器虚拟化事件 | 70,831 |
| monitoring/servers | 服务器监控 | 44,725 |
| monitoring/sessions | 会话监控 | 45,110 |
| monitoring/sharedStorageStatus | 共享存储状态 | 40,169 |
| monitoring/virtualStorageStatus | 虚拟存储状态 | 40,174 |
| app/auditList | 审计列表 | 37,691 |

### ⚙️ 系统设置
| URL | 描述 | 大小 |
|-----|------|------|
| generalSettings/showGlobalPolicy | 全局策略 | 137,055 |
| generalSettings/mailServerList | 邮件服务器 | 50,015 |
| generalSettings/showHA | HA配置 | 83,391 |
| generalSettings/showLicense | 许可证 | 77,613 |
| generalSettings/listLabel | 标签管理 | 55,557 |
| generalSettings/listAffinity | 亲和组 | 55,240 |
| generalSettings/drsSetting | DRS设置 | 132,098 |
| generalSettings/dpmSetting | DPM设置 | 132,508 |
| generalSettings/dynamicSetting | 动态热添加 | 132,037 |
| generalSettings/videoRedirectList | 视频重定向 | 77,193 |
| generalSettings/welcomeMessageList | 欢迎消息 | 50,021 |
| generalSettings/vdeSettings | VDE设置 | 75,065 |
| generalSettings/listServer | 服务器列表设置 | 56,038 |
| generalSettings/trafficServerSettings | 流量服务器 | 82,721 |
| user/listRoles | 角色管理 | 140,176 |
| user/showPasswordPolicy | 密码策略 | 85,655 |
| organization/list | 组织管理 | 85,037 |
| visitPolicy/visitPolicys | 访问策略 | 75,736 |
| resourceTag/list | 资源标签 | 39,491 |

### 📈 统计报表
| URL | 描述 | 大小 |
|-----|------|------|
| statistics/userLoginInfo | 用户登录统计 | 72,127 |
| statistics/operationEventInfo | 操作事件统计 | 72,339 |
| statistics/usageTimeInfo | 使用时长统计 | 72,697 |
| statistics/alarmStatisticsInfo | 告警统计 | 74,239 |
| statistics/onlineUserNumberInfo | 在线用户数 | 46,411 |
| statistics/onlineClientInfo | 在线客户端 | 69,676 |
| statistics/clientStateInfo | 客户端状态 | 69,745 |
| statistics/vmStatusInfo | 虚拟机状态 | 72,625 |
| statistics/vmAlarmInfo | 虚拟机告警 | 72,463 |
| statistics/serverAlarmInfo | 服务器告警 | 72,536 |
| statistics/serverVirtualResource | 服务器虚拟化资源 | 73,801 |
| statistics/serverVirtualTop | 服务器虚拟化TOP | 70,023 |
| statistics/userFaultInfo | 用户故障 | 71,862 |
| statistics/faultTypeInfo | 故障类型 | 71,625 |
| statistics/operationUserInfo | 操作用户 | 77,590 |
| statistics/vmRecoverInfo | 虚拟机恢复 | 71,917 |
| statistics/unusedVMInfo | 未使用虚拟机 | 71,954 |
| statistics/userUsbInfo | 用户USB | 70,778 |
| statistics/dataCopyAudit | 数据拷贝审计 | 72,576 |

### 🔧 其他
| URL | 描述 | 大小 |
|-----|------|------|
| app/taskCenter | 任务中心 | 76,682 |
| app/approvalCenter | 审批中心 | 74,298 |
| recycleBin/index | 回收站(桌面) | 102,881 |
| serverRecycle/index | 回收站(服务器) | 80,448 |
| backup/backupServer | 备份服务器 | 75,872 |
| client/index | 终端管理 | 128,860 |
| app/fileManage | 文件管理 | 47,257 |
| app/oneClickDetection | 一键检测 | 47,989 |
| branch/dashboard | 分支看板 | 22,597 |
| virtualApp/virtualAppGroups | 虚拟应用组 | 47,862 |
| virtualApp/appSessions | 应用会话 | 45,237 |
| serverVirtualization/index | 服务器虚拟化 | 152,358 |

## 未抓取/404的页面
- VM/index (重定向)
- generalSettings/showPasswordState (404)
- generalSettings/proxyServerSettings (1587 bytes, 可能需要升级)
- serverVirtualization/backup/highSetting (404)
- serverVirtualization/loadBalance/index (404)
- serverVirtualization/appHA/index (404)
- serverVirtualization/autoScaling/listAutoScalingGroup (404)
- serverVirtualization/zombieCloudServer/index (404)
- serverVirtualization/serverCloudStartOrder/index (404)
- image/listImageVerManage (36 bytes)

注：serverVirtualization子页面可能通过主页面的Tab/AJAX加载
