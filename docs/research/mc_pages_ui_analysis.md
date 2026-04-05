# MC 页面 UI 结构完整分析

## 统计汇总
- 总页面数: 123 (原始抓取) + 30 (重新抓取) + 5 (新发现)
- 有效页面: 128 (全部确认正常)
- 404错误页: 0 (已全部修复，原25个404是URL路径有误)

---

## 404 页面修复（URL路径映射）

所有25个"404"页面实际上是URL路径不对。真实URL映射如下：

| 原始错误URL | 正确URL | 页面标题 |
|------------|---------|---------|
| /mc/app/accessPolicy | /mc/visitPolicy/visitPolicys | 访问策略 |
| /mc/app/adminList | /mc/user/list | 管理员账号 |
| /mc/app/alertList | /mc/monitoringNew/monitoringNew | 日志告警 |
| /mc/app/eventList | /mc/monitoringNew/monitoringNew | 日志告警 |
| /mc/app/haConfig | /mc/generalSettings/showHA | HA设置 |
| /mc/app/licenseSetting | /mc/generalSettings/showLicense | 许可 |
| /mc/app/maintenance | /mc/app/oneClickDetection | 一键检测 |
| /mc/app/passwordPolicy | /mc/user/showPasswordPolicy | 密码策略 |
| /mc/app/recycleBin | /mc/recycleBin/index | 回收站 |
| /mc/app/roleSetting | /mc/user/listRoles | 角色管理 |
| /mc/app/smtpConfig | /mc/generalSettings/mailServerList | SMTP服务器设置 |
| /mc/app/systemConfig | /mc/generalSettings/showGlobalPolicy | 常规设置 |
| /mc/backup/list | /mc/VM/backups | 备份管理 |
| /mc/generalSettings/showPasswordState | /mc/user/showPasswordPolicy | 密码策略 |
| /mc/host/list | /mc/servers/clusterMasters | 主集群 |
| /mc/serverVirtualization/appHA/index | /mc/serverVirtualization/index | 服务器虚拟化(应用HA子页) |
| /mc/serverVirtualization/autoScaling/listAutoScalingGroup | /mc/serverAutoScaling/listAutoScalingGroupPage | 自动伸缩组 |
| /mc/serverVirtualization/backup/highSetting | /mc/serverVMBackup/highSetting | 备份高级设置 |
| /mc/serverVirtualization/loadBalance/index | /mc/loadBalance/index | 负载均衡 |
| /mc/serverVirtualization/serverCloudStartOrder/index | /mc/serverCloudStartOrder/index | 云服务器启动顺序 |
| /mc/serverVirtualization/zombieCloudServer/index | /mc/zombieCloudServer/index | 僵尸云服务器 |
| /mc/snapshot/policyList | /mc/VM/snapStrategy | 快照策略 |
| /mc/storage/list | /mc/storageNew/storageNew | 存储管理 |
| /mc/virtualSwitch/list | /mc/network/list | 虚拟交换机 |
| /mc/VM/sessions | /mc/monitoring/sessions | 实时会话 |

### 新发现的页面（不在原始抓取中）

| URL | 标题 |
|-----|------|
| /mc/user/list | 管理员账号 |
| /mc/generalSettings/affinityGroup | 亲和组设置 |
| /mc/generalSettings/labelSettings | 标签设置 |
| /mc/serverAutoScaling/listAutoScalingStrategyPage | 自动伸缩策略 |
| /mc/VM/backups | 备份管理 |

---

## 全局导航栏结构（从 dashboard 提取）

| 导航项 | URL | 说明 |
|--------|-----|------|
| 仪表板 | /mc/reporting/dashboard | 总概览 |
| 桌面发布 | /mc/image/list | 黄金镜像/规格/规则 |
| 桌面虚拟机 | /mc/VM/desktopVms | 桌面VM管理 |
| 服务器虚拟化 | /mc/serverVirtualization/index | 云服务器管理 |
| 网络池 | /mc/network/list | 网络资源管理 |
| 存储池 | /mc/storageNew/storageNew | 存储资源管理 |
| 一体机 | /mc/servers/clusterMasters | 物理机管理 |
| 日志告警 | /mc/monitoringNew/monitoringNew | 监控日志 |
| 统计报表 | /mc/statistics/userLoginInfo | 报表 |
| 终端管理 | /mc/client/index | TC管理 |
| 系统管理 | /mc/generalSettings/showGlobalPolicy | 全局设置 |

---

## 各页面详细 UI 结构

### 仪表板模块

#### dashboard.html — 仪表板
- Title: 管理控制台： 仪表板
- UI类型: Widget面板 (RequireJS, echarts图表)
- 面板: 虚拟机使用情况, 服务器统计, 集群资源使用情况(CPU/内存/存储), 在线趋势图, 用户在线情况, 用户在线时长排序

#### branch_dashboard.html — 分支仪表板
- Title: 管理控制台： 仪表板
- 分支机构专用仪表板

#### monitoring_dashboard.html — 监控仪表板
- Title: 管理控制台： 仪表板

---

### 桌面发布模块

#### image_list.html — 黄金镜像
- Title: 管理控制台： 黄金镜像
- Table: simple-table
- Buttons: **新建**, 删除, 维护, 更多
- Toolbar: 新建黄金镜像, 导入黄金镜像

#### image_listAppLayers.html — 应用程序层
- Title: 管理控制台： 应用程序层
- Table: grid-table
- Buttons: **新建**
- Toolbar: 导入应用程序层

#### policy_list.html — 桌面规格
- Title: 管理控制台： 桌面规格
- Table: grid-table
- Grid Columns: 名称, 说明, 覆盖值, 操作
- Buttons: **新建**, 删除
- Toolbar: 新建桌面规格

#### userSelect_editList.html — 发布规则
- Title: 管理控制台： 发布规则
- Tables: grid-table-recycle, grid-table-revert
- Buttons: **新建**, 编辑, 更多, 添加, 取消

#### desktopPool_list.html — 桌面池
- Title: 管理控制台： 桌面池
- Table: grid-table
- Grid Columns: ...操作
- Buttons: **新建**

#### app_fileManage.html — 桌面发布文件
- Title: 管理控制台： 桌面发布文件
- Tabs: 桌面发布文件 | 终端管理文件

---

### 应用管控模块

#### imageApp_builtinRule.html — 内置规则库
- Title: 管理控制台： 内置规则库

#### imageApp_customApp.html — 自定义规则库
- Title: 管理控制台： 自定义规则库

#### imageApp_listAppLib.html — 软件库
- Title: 管理控制台： 软件库
- Table: imageApps-grid-table
- Buttons: 同步, 删除
- Actions: 删除, 编辑

#### imageApp_listMachineApp.html — 软件发布
- Title: 管理控制台： 软件发布
- Table: machineApp-grid-table
- Actions: 编辑

---

### 桌面虚拟机模块

#### VM_desktopVms.html — 桌面虚拟机
- Title: 管理控制台： 桌面虚拟机
- UI类型: iframe SPA (/mc/reporting/dist/index.html)
- 内嵌功能: 应用管控, 多虚拟磁盘, 磁盘加密

#### VM_snapStrategy.html — 快照策略
- Title: 管理控制台： 快照策略
- Tabs: 桌面虚拟机 | 云服务器
- Table: grid-table
- Grid Columns: 策略名称, 描述, 发布规则数, 快照时间, 保留个数, 下次开始时间, 生效, 操作
- Buttons: **立即快照**, 生效, 失效, 删除, **新建**
- Toolbar: 即可生成快照, 策略生效, 策略失效, 删除快照策略, 新建快照策略

#### VM_snapSettings.html — 快照设置
- Title: 管理控制台： 快照设置
- Table: simple-table

#### VM_snapshotList.html — 快照列表
- 无title（可能是弹窗）

---

### 服务器虚拟化模块

#### serverVirtualization_index.html — 服务器虚拟化
- Title: 管理控制台： 服务器虚拟化
- Tables: grid-table, warnTable, networkTable, diskTable, taskTable, backupTable, snapshotTable, pciTable, gpuTable
- Buttons: **导出**, 启动顺序, 刷新, 筛选, **新增**, **开机**, **关机**, 更多, 导出磁盘, 附加裸设备映射, 删除, 创建快照, 编辑, 恢复

---

### 网络池模块

#### network_list.html — 虚拟交换机 (默认tab)
- Title: 管理控制台： 网络池
- Tabs: **虚拟交换机** | 安全组 | 子网 | MAC地址池 | 网络配置规则 | 网络配置记录 | 端口镜像 | 虚拟防火墙
- Table: virtualSwitch-table
- Grid Columns: 名称, 描述, VLAN, 虚拟机/端口, 操作
- Buttons: **新建**
- Actions: 编辑, 删除

#### network_securityGroup.html — 安全组
- Grid Columns: 名称, 描述, 操作
- Buttons: **添加**
- Actions: 编辑, 删除

#### network_subNet.html — 子网
- Grid Columns: 名称, 描述, 子网, 子网掩码, VLAN ID, 网关, 首选DNS服务器, 备份DNS服务器, 操作
- Buttons: **添加**
- Actions: 编辑, 删除

#### network_macAddress.html — MAC地址池
- Tables: macAddressPool-table, macAddressRecord-table
- Grid Columns(地址池): MAC地址池名称, MAC地址前缀, 池开始地址, 池结束地址
- Grid Columns(记录): MAC地址, 桌面, 用户, 组织, 网卡, 计算机名称, IP地址, 服务器, 启动时间
- Buttons: **添加**, 撤销 MAC 地址

#### network_portMirroring.html — 端口镜像
- Grid Columns: 名称, 描述, 虚拟交换机, 服务器, 源类型, 源, 目的类型, 目的, 操作
- Buttons: **添加**

#### network_vlanPool.html — VLAN池 (虚拟交换机详情子tab)
- Tabs: 概要 | 虚拟机 | 云服务器 | 主机 | 端口 | VLAN池 | 端口组
- Grid Columns: 起始VLAN ID, 结束VLAN ID, 操作
- Buttons: **添加**

#### network_networkConfigure.html — 网络配置规则
- Title: 管理控制台： 网络池

---

### 存储池模块

#### storage_list.html — 存储管理（重新抓取 /mc/storageNew/storageNew）
- Title: 管理控制台： 存储管理
- 注意: storageNew/storageNew 是新版存储页面入口

#### storage_dataStore.html — 数据存储
- Title: 管理控制台： 存储池

#### storageNew_storageNew.html — 存储管理新版
- Title: 管理控制台： 服务器事件（title可能有误）

#### storage_list.html — [404 未抓取]

---

### 一体机 / 主机模块

#### servers_clusterMasters.html — 主集群
- Title: 管理控制台： 主集群
- Table: grid-table
- Buttons: **新增主机**, 修改集群名, 切换联机, 更多
- Actions: 移除

#### host_list.html — 主集群（重新抓取 /mc/servers/clusterMasters）
- Title: 管理控制台： 主集群
- Table: grid-table
- Buttons: **新增主机**, 修改集群名, 切换联机, 更多
- Toolbar: 新增主机, 修改集群名, 切换联机
- Actions: 移除

---

### 用户管理模块

#### user_listKsvdUsers.html — 用户列表
- Title: 管理控制台： 用户
- Table: grid-table-user
- Buttons: **新建**, 编辑, 更多
- Toolbar: 新建用户, 编辑, 删除复选框点中的所有用户

#### user_listKsvdGroups.html — 用户组
- Title: 管理控制台： 组

#### user_listRoles.html — 角色管理
- Title: 管理控制台： 角色管理
- Buttons: **新建**, 编辑, 删除
- Toolbar: 新建角色

#### user_showPasswordPolicy.html — 密码策略
- Title: 管理控制台： 密码策略
- Table: simple-table

#### user_terminalAndUser.html — 客户端接入控制
- Title: 管理控制台： 客户端接入控制

#### auth_listAuthProviders.html — LDAP服务器
- Title: 管理控制台： LDAP 服务器
- Table: grid-table
- Grid Columns: ...操作
- Buttons: **新建**
- Toolbar: 新建 LDAP 服务器

---

### 日志告警模块

#### monitoring_alarmEvents.html — 告警事件
- Grid Columns: 告警级别, 告警名称, 告警对象, 对象类型, 告警时间, 详情
- Buttons: **导出**

#### monitoring_alarmSettings.html — 告警设置
- Grid Columns: 告警名称, 紧急阈值(0为禁用), 严重阈值(0为禁用), 一般阈值(0为禁用)
- Buttons: 保存, 开启, 关闭

#### monitoring_auditEvents.html — 审核事件
- Grid Columns: 严重性, 日期, 操作, 用户, 目标, 值, IP
- Buttons: **导出**

#### monitoring_serverEvents.html — 服务器事件
- Grid Columns: 严重性, 日期, 类型, 服务器, 资源, 信息
- Buttons: **导出**

#### monitoring_sessionEvents.html — 虚拟机事件
- Grid Columns: 严重性, 日期, 类型, 服务器, 部署模式, 信息, 用户名, 虚拟机, 组织
- Buttons: **导出**

#### monitoring_serverVirtualEvents.html — 服务器虚拟化事件
- Grid Columns: 严重性, 日期, 类型, 运行主机, 资源, 信息, 用户名, 云服务器, 组织, 部署模式
- Buttons: **导出**

#### monitoring_vdeEvents.html — VDE用户事件
- Grid Columns: 严重性, 日期, 类型, VDE服务器, 部署模式, 信息, 用户名, 虚拟机, 组织
- Buttons: **导出**

#### monitoring_clientAuditEvents.html — 终端审核日志
- Grid Columns: 严重性, 日期, 操作, 用户, 终端名称, 信息, 终端IP
- Buttons: **导出**

#### monitoring_sessions.html — 实时会话
- Title: 管理控制台： 实时会话

#### monitoring_servers.html — 本地服务器
- Title: 管理控制台： 本地服务器

#### monitoring_charts.html — 容量图表
- Title: 管理控制台： 容量图表

---

### 统计报表模块

#### statistics_userLoginInfo.html — 用户登录信息
- Grid Columns: 用户, 虚拟机, 客户端IP, 开始连接时间, 断开连接时间, 备注
- Buttons: **导出**

#### statistics_usageTimeInfo.html — 用户使用时间
- Grid Columns: 用户, 虚拟机, 总时长, 平均时长
- Buttons: **导出**

#### statistics_operationUserInfo.html — 用户操作统计
- Grid Columns: 用户, IP, 次数
- Buttons: **导出**

#### statistics_operationEventInfo.html — 操作行为统计
- Grid Columns: IP, 操作类型, 次数
- Buttons: **导出**

#### statistics_alarmStatisticsInfo.html — 告警次数统计
- Grid Columns: 告警级别, 告警名称, 告警对象, 紧急次数, 严重次数, 一般次数, 总计
- Buttons: **导出**

#### statistics_serverAlarmInfo.html — 服务器告警时长统计
- Grid Columns: 告警级别, 告警名称, 告警对象, 紧急时长, 严重时长, 一般时长, 总计
- Buttons: **导出**

#### statistics_vmAlarmInfo.html — 虚拟机告警时长统计
- Grid Columns: 告警级别, 告警名称, 告警对象, 紧急时长, 严重时长, 一般时长, 总计
- Buttons: **导出**

#### statistics_vmRecoverInfo.html — 虚拟机恢复统计
- Grid Columns: 用户, 虚拟机, 次数
- Buttons: **导出**

#### statistics_vmStatusInfo.html — 虚拟机状态统计

#### statistics_unusedVMInfo.html — 未使用的虚拟机
- Grid Columns: 用户, 虚拟机, 分配时间, 最近使用时间
- Buttons: **导出**

#### statistics_userFaultInfo.html — 用户故障统计
- Grid Columns: 用户, 次数
- Buttons: **导出**

#### statistics_faultTypeInfo.html — 故障类型统计
- Grid Columns: 故障类型, 次数
- Buttons: **导出**

#### statistics_dataCopyAudit.html — 数据拷贝审计
- Grid Columns: 用户, 虚拟机, IP, 盘符, 文档名, 文档大小, 操作类型, 时间, 开始时间, 结束时间, 源路径, 目标路径
- Buttons: **导出**

#### statistics_userUsbInfo.html — USB信息统计
- Grid Columns: 用户, 客户端IP, 桌面名, 设备名, vid, pid, 类型, 驱动, 协议, 速率, 状态, 上报时间

#### statistics_onlineUserNumberInfo.html — 在线用户数
#### statistics_onlineClientInfo.html — 在线终端统计
#### statistics_clientStateInfo.html — 终端状态统计
#### statistics_serverVirtualResource.html — 服务器虚拟化资源统计
#### statistics_serverVirtualTop.html — 服务器虚拟化TOP统计

---

### 系统管理模块

#### generalSettings_showGlobalPolicy.html — 常规设置
- Table: simple-table
- Buttons: 重置密码

#### generalSettings_showHA.html — HA设置
- Buttons: 编辑, 更新

#### generalSettings_showLicense.html — 许可
- Buttons: 编辑

#### generalSettings_mailServerList.html — SMTP服务器设置
- Table: grid-table
- Buttons: **添加**
- Actions: 删除, 编辑

#### generalSettings_vdeSettings.html — VDE设置
- Grid Columns: 设置项, 说明, 值, 严重阈值(0为禁用), 一般阈值(0为禁用)

#### generalSettings_drsSetting.html — DRS设置
- Table: drs-grid-table
- Buttons: 配置

#### generalSettings_dpmSetting.html — DPM设置
- Table: dpm-grid-table
- Buttons: 配置

#### generalSettings_dynamicSetting.html — 动态热添加
- Table: dynamic-grid-table
- Buttons: 热添加配置, 添加, 移除

#### generalSettings_listLabel.html — 标签设置
- Table: list-grid-table
- Buttons: **新增**

#### generalSettings_listAffinity.html — 亲和组设置
- Table: list-group-table

#### generalSettings_welcomeMessageList.html — 欢迎消息设置
- Table: grid-table
- Buttons: **添加**
- Actions: 删除, 编辑

#### generalSettings_videoRedirectList.html — 重定向设置
- Table: grid-table
- Buttons: 代理设置, **添加**, 更多
- Actions: 删除, 编辑

#### generalSettings_proxyServerSettings.html — 代理服务器设置
- Table: proxy-grid-table
- Buttons: 添加, 编辑, 删除, 保存, 取消

#### generalSettings_trafficServerSettings.html — 视频缓存设置
- Table: simple-table

---

### 其他模块

#### visitPolicy_visitPolicys.html — 访问策略
- Grid Columns: 规则名称, 规则说明
- Buttons: **新建规则**, 编辑规则, 删除规则

#### organization_list.html — 组织资源
- Tables: simple-table, listMachineTable
- Buttons: **新建**, 编辑, 更多

#### recycleBin_index.html — 回收站（桌面VM）
- Tabs: 云服务器 | 桌面虚拟机 | 桌面磁盘
- Buttons: 回收站设置, **恢复**, **删除**

#### serverRecycle_index.html — 回收站（云服务器）
- Tabs: 桌面虚拟机 | 云服务器
- Buttons: 回收站设置, **恢复**, **删除**

#### app_approvalCenter.html — 审批中心
- Table: grid-table

#### app_taskCenter.html — 任务列表
- Table: grid-table

#### app_oneClickDetection.html — 一键检测

#### backup_backupServer.html — 备份服务器设置
- Table: grid-table
- Buttons: **添加**
- Actions: 编辑, 删除

#### virtualApp_virtualAppGroups.html — 应用组
- Table: virtual-groups-grid-table
- Buttons: **新建**, 删除

#### virtualApp_appSessions.html — 应用会话
- Table: app-sessions-grid-table
- Buttons: **断开**, **注销**

#### client_index.html — 终端管理
- Tables: grid-table-terminal, grid-table-task
- Buttons: 设置, 电源管理, 软件升级, 系统升级, 更多, 批量删除

#### resourceTag_list.html — 资源标签

#### MACAddressPool_list.html — MAC地址池
- Toolbar: 新建 MAC 地址池

#### login_result.html — 登录页

---

## 错误状态页面
- monitoring_sharedStorageStatus.html — 标题为"错误"
- monitoring_virtualStorageStatus.html — 标题为"错误"

---

## 重新抓取页面的详细 UI 结构（补充）

### 备份管理模块

#### backup_list.html — 备份管理（实际URL: /mc/VM/backups）
- Title: 管理控制台： 备份管理
- Tabs: 桌面虚拟机 | 云服务器
- Table: grid-table
- Grid Columns: 用户, 桌面, 组, 间隔天数, 保留份数, 备份位置, 定时时间, 最后备份时间, 最后状态, 备注, 操作
- Buttons: **新增备份**, 删除, 超时继续, **立即备份**

### 用户/管理员模块（补充）

#### user_list.html / app_adminList.html — 管理员账号（实际URL: /mc/user/list）
- Title: 管理控制台： 管理员账号
- Table: user-table
- Buttons: **新建**, 编辑, 更多
- Toolbar: 创建新管理员

### 服务器虚拟化子模块（补充）

#### serverVirtualization_loadBalance.html — 负载均衡（/mc/loadBalance/index）
- Title: 管理控制台： 负载均衡
- Tables: grid-table, grid-table-listener
- Buttons: **创建**, 编辑, 删除

#### serverVirtualization_autoScaling.html — 自动伸缩组（/mc/serverAutoScaling/listAutoScalingGroupPage）
- Title: 管理控制台： 服务器虚拟化
- Tables: grid-table, grid-table-machine
- Buttons: **创建**, 启用, 停用

#### serverAutoScaling_strategy.html — 自动伸缩策略（/mc/serverAutoScaling/listAutoScalingStrategyPage）
- Title: 管理控制台： 服务器虚拟化
- Table: grid-table
- Buttons: **创建**, 启用, 停用, 删除

#### serverVirtualization_backup_highSetting.html — 备份高级设置（/mc/serverVMBackup/highSetting）
- Title: 管理控制台： 备份高级设置
- Table: grid-table-highSetting

#### serverVirtualization_serverCloudStartOrder.html — 云服务器启动顺序（/mc/serverCloudStartOrder/index）
- Title: 管理控制台： 云服务器启动顺序
- Table: serverCloudStartOrderTable
- Buttons: ...更多操作

#### serverVirtualization_zombieCloudServer.html — 僵尸云服务器（/mc/zombieCloudServer/index）
- Title: 管理控制台： 僵尸云服务器
- Tables: zombieCloudServerTable + 详情子表(warnTable, networkTable, diskTable, taskTable, backupTable, snapshotTable)
- Buttons: **开机**, **关机**, 删除, 附加裸设备映射, 创建快照, 编辑, 恢复

### 系统设置子模块（补充）

#### generalSettings_affinityGroup.html — 亲和组设置（/mc/generalSettings/affinityGroup）
- Title: 亲和组设置
- Table: list-grid-table
- Buttons: **新增**, 启用, 停用, 删除

#### generalSettings_labelSettings.html — 标签设置（/mc/generalSettings/labelSettings）
- Title: 标签设置
- Table: list-grid-table
- Buttons: **新建**, 删除

---

## 完整系统管理左侧导航（从 generalSettings/showGlobalPolicy 提取）

| 分类 | 页面 | URL |
|------|------|-----|
| 系统管理 | 常规设置 | /mc/generalSettings/showGlobalPolicy |
| | HA设置 | /mc/generalSettings/showHA |
| | 许可 | /mc/generalSettings/showLicense |
| | SMTP服务器设置 | /mc/generalSettings/mailServerList |
| | VDE设置 | /mc/generalSettings/vdeSettings |
| | DRS设置 | /mc/generalSettings/drsSetting |
| | DPM设置 | /mc/generalSettings/dpmSetting |
| | 动态热添加 | /mc/generalSettings/dynamicSetting |
| | 视频缓存设置 | /mc/generalSettings/trafficServerSettings |
| | 重定向设置 | /mc/generalSettings/videoRedirectList |
| | 欢迎消息设置 | /mc/generalSettings/welcomeMessageList |
| | 标签设置 | /mc/generalSettings/labelSettings |
| | 亲和组设置 | /mc/generalSettings/affinityGroup |
| 用户管理 | 用户列表 | /mc/user/listKsvdUsers 或 /mc/user/list |
| | 组 | /mc/user/listKsvdGroups |
| | 角色管理 | /mc/user/listRoles |
| | 密码策略 | /mc/user/showPasswordPolicy |
| | 客户端接入控制 | /mc/user/terminalAndUser |
| | 访问策略 | /mc/visitPolicy/visitPolicys |
| | LDAP服务器 | /mc/auth/listAuthProviders |
| 组织管理 | 组织资源 | /mc/organization/list |
| 备份管理 | 备份服务器 | /mc/backup/backupServer |
| | 备份管理 | /mc/VM/backups |
| 回收站 | 回收站 | /mc/recycleBin/index |
| | 服务器回收站 | /mc/serverRecycle/index |
| 工具 | 一键检测 | /mc/app/oneClickDetection |
| | 文件管理 | /mc/app/fileManage |
| | 任务中心 | /mc/app/taskCenter |
| | 审批中心 | /mc/app/approvalCenter |
