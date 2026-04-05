# MC 全功能差距分析与实施计划

## 一、现有代码状态汇总

### 前端 (41个Vue组件, 路由完整覆盖所有模块)
### 后端 (16个路由文件, 79个API端点)
### 数据库 (31张表)

---

## 二、模块级差距对比

### ✅ = 已实现   ⚠️ = 部分实现   ❌ = 未实现

---

### 1. 仪表板 (Dashboard)
| MC功能 | 我们的状态 | 差距说明 |
|--------|-----------|---------|
| 虚拟机使用情况(运行/未运行) | ✅ Dashboard.vue 549行 | 需验证数据来源 |
| 服务器统计(在线/离线) | ✅ | 需验证 |
| 集群资源使用情况(CPU/内存/存储) | ✅ | 需验证 |
| 在线趋势图(分/时/天) | ⚠️ | 需确认图表实现 |
| 用户在线情况 | ⚠️ | 需与真实数据对比 |
| 用户在线时长排序 | ⚠️ | 需确认 |
| **对比测试**: 调用 /mc/reporting/dashboard 对比数据 | | |

### 2. 桌面发布 (Desktop Publish)
| MC功能 | 我们的状态 | 差距说明 |
|--------|-----------|---------|
| 黄金镜像 - 列表/新建/删除/维护/导入 | ✅ Templates.vue 252行 | 需验证完整操作 |
| 桌面规格 - 6个配置标签页 | ✅ Specs.vue 177行 | 需对比真实字段 |
| 发布规则 - 用户/组分配 | ✅ PublishRules.vue 153行 | 需对比 |
| 桌面池管理 | ✅ DesktopPools.vue 117行 | 需对比 |
| 应用程序层 | ⚠️ AppManagement.vue 289行 无API | ❌ 缺少API调用 |
| 软件库 | ⚠️ 复用AppManagement | ❌ 缺少独立实现 |
| 软件发布 | ⚠️ 复用AppManagement | ❌ 缺少独立实现 |
| 应用管控-内置规则库 | ⚠️ 复用AppManagement | ❌ 缺少实现 |
| 应用管控-自定义规则库 | ⚠️ 复用AppManagement | ❌ 缺少实现 |
| 应用发布-应用组 | ⚠️ 复用AppManagement | ❌ 缺少实现 |
| 应用发布-应用会话 | ⚠️ 复用AppManagement | ❌ 缺少实现 |
| 桌面发布文件管理 | ✅ FileManage.vue | 无API |
| **MC页面**: image_list, policy_list, userSelect_editList, desktopPool_list | | |

### 3. 用户管理
| MC功能 | 我们的状态 | 差距说明 |
|--------|-----------|---------|
| 用户CRUD | ✅ Users.vue 242行 | 需对比字段 |
| 用户组管理 | ✅ 路由已有 | 需验证 |
| LDAP服务器 | ✅ 路由已有, auth.js | 需对比 |
| 客户端接入控制 | ⚠️ TerminalUser.vue 117行无API | ❌ 缺API |
| **MC页面**: user_listKsvdUsers, user_listKsvdGroups, auth_listAuthProviders | | |

### 4. 桌面虚拟机
| MC功能 | 我们的状态 | 差距说明 |
|--------|-----------|---------|
| VM列表+搜索/筛选 | ✅ VMs.vue 308行 | 需对比 |
| VM操作(开/关/重启/强制) | ✅ vms.js 10个POST | 需对比 |
| 远程控制(VNC/SPICE) | ✅ | 需验证 |
| 系统还原 | ⚠️ | 需确认 |
| 热添加(网卡/磁盘) | ⚠️ | 需确认 |
| 编辑配置 | ⚠️ | 需确认 |
| 热迁移/存储迁移 | ⚠️ | 需确认 |
| 快照管理 | ✅ | 需确认 |
| 回收站 | ✅ RecycleBin.vue | 无API |
| VM详情页(5个tab) | ✅ VMDetail.vue 395行 | 需对比 |
| **MC页面**: VM_desktopVms (iframe SPA) | | |

### 5. 服务器虚拟化
| MC功能 | 我们的状态 | 差距说明 |
|--------|-----------|---------|
| 云服务器列表+管理 | ✅ ServerVirt.vue 88行 | 需大幅扩展 |
| 云服务器详情(8个子表) | ⚠️ | 详情表不完整 |
| 负载均衡 | ⚠️ ScalingConfig 256行无API | ❌ 缺API |
| 自动伸缩组 | ⚠️ 同上 | ❌ 缺API |
| 自动伸缩策略 | ⚠️ 同上 | ❌ 缺API |
| 备份高级设置 | ⚠️ | ❌ 缺实现 |
| 云服务器启动顺序 | ⚠️ SystemConfigPage | ❌ 缺API |
| 僵尸云服务器 | ⚠️ ZombieServers 76行无API | ❌ 缺API |
| 应用HA | ⚠️ | ❌ 缺实现 |
| **MC页面**: serverVirtualization_index (很复杂, 8个子表) | | |

### 6. 网络池
| MC功能 | 我们的状态 | 差距说明 |
|--------|-----------|---------|
| 虚拟交换机(名称/描述/VLAN/端口/操作) | ✅ Networks.vue 364行 | 需对比列 |
| 安全组(名称/描述/操作) | ✅ SecurityGroups.vue 136行 | 需对比 |
| 子网(9列) | ✅ NetworkSubPage.vue 240行 | 需对比字段 |
| MAC地址池(2个表) | ✅ MacPool.vue 74行 | 需扩展 |
| 端口镜像(9列) | ✅ NetworkSubPage | 需对比 |
| VLAN池 | ✅ NetworkSubPage | 需对比 |
| 网络配置规则 | ✅ NetworkSubPage | 需对比 |
| 网络配置记录 | ⚠️ | 需确认 |
| 虚拟防火墙 | ✅ NetworkSubPage | 需对比 |
| **MC页面**: network_list + 7个子tab | | |

### 7. 存储池
| MC功能 | 我们的状态 | 差距说明 |
|--------|-----------|---------|
| 存储管理 | ✅ Storage.vue 258行 | 需对比 |
| 数据存储详情 | ⚠️ StorageDetail.vue 85行无API | ❌ 缺API |
| 分布式存储 | ⚠️ | 需确认实现 |
| 集中存储(FC/IP SAN) | ⚠️ | 需确认 |
| **MC页面**: storageNew_storageNew, storage_dataStore | | |

### 8. 一体机/主机管理
| MC功能 | 我们的状态 | 差距说明 |
|--------|-----------|---------|
| 主集群列表 | ✅ Hosts.vue 249行 | 需对比 |
| 新增主机/修改集群名/联机切换 | ✅ hosts.js 3POST | 需对比 |
| 主机详情(概要/网络/GPU等) | ✅ HostDetail.vue 207行 | 需对比tab |
| **MC页面**: servers_clusterMasters | | |

### 9. 日志告警
| MC功能 | 我们的状态 | 差距说明 |
|--------|-----------|---------|
| 服务器事件(6列) | ✅ Events.vue 134行 | 需对比列 |
| 虚拟机事件(9列) | ✅ EventLog.vue 98行 | 需对比列 |
| 服务器虚拟化事件(10列) | ✅ EventLog复用 | 需对比列 |
| 审核事件(7列) | ✅ EventLog复用 | 需对比列 |
| VDE用户事件(9列) | ⚠️ | 可能缺少 |
| 终端审核日志(7列) | ✅ EventLog复用 | 需对比列 |
| 告警事件(6列) | ✅ Alerts.vue 201行 | 需对比 |
| 告警设置(4列) | ✅ AlarmSettings.vue 104行 | 需对比 |
| 实时会话 | ⚠️ | 需确认 |
| 容量图表 | ⚠️ | 需确认 |
| **MC页面**: monitoring_* 系列 | | |

### 10. 统计报表
| MC功能 | 我们的状态 | 差距说明 |
|--------|-----------|---------|
| 用户登录信息(6列) | ✅ StatsView.vue 173行 | 需对比 |
| 用户使用时间(4列) | ✅ StatsView复用 | 需对比 |
| 用户操作统计(3列) | ✅ StatsView复用 | 需对比 |
| 操作行为统计(3列) | ✅ StatsView复用 | 需对比 |
| 告警类统计(3种) | ✅ StatsView复用 | 需对比 |
| 虚拟机恢复统计(3列) | ✅ StatsView复用 | 需对比 |
| USB信息统计(12列) | ⚠️ | 可能字段不完整 |
| 数据拷贝审计(12列) | ⚠️ | 可能字段不完整 |
| 故障统计(2种) | ✅ | 需对比 |
| 在线终端/用户统计(图表) | ⚠️ | 需确认 |
| **MC页面**: statistics_* 系列 | | |

### 11. 系统管理
| MC功能 | 我们的状态 | 差距说明 |
|--------|-----------|---------|
| 常规设置 | ✅ System.vue 426行 | 需对比 |
| HA设置 | ⚠️ SystemConfigPage | 需对比 |
| 许可 | ✅ License.vue 90行 | 需对比 |
| SMTP服务器设置 | ✅ System.vue | 需对比 |
| VDE设置 | ⚠️ | 需确认 |
| DRS设置 | ⚠️ ScalingConfig | 需确认 |
| DPM设置 | ⚠️ ScalingConfig | 需确认 |
| 动态热添加 | ⚠️ SystemConfigPage | 需确认 |
| 视频缓存/重定向 | ⚠️ SystemConfigPage | 需确认 |
| 欢迎消息 | ⚠️ SystemConfigPage | 需确认 |
| 标签设置 | ⚠️ SystemConfigPage | 需确认 |
| 亲和组 | ⚠️ SystemConfigPage | 需确认 |
| 管理员账号 | ✅ System.vue | 需对比 |
| 密码策略 | ✅ System.vue | 需对比 |
| 访问策略 | ✅ System.vue | 需对比 |
| 角色管理 | ✅ System.vue | 需对比 |
| 组织资源 | ⚠️ SystemConfigPage | 需确认 |
| **MC页面**: generalSettings_*, user_listRoles, 等 | | |

### 12. 备份管理
| MC功能 | 我们的状态 | 差距说明 |
|--------|-----------|---------|
| 备份服务器管理 | ✅ BackupManagement.vue 147行 | 需对比 |
| 备份列表(11列) | ✅ | 需对比完整列 |
| 新增备份/立即备份 | ✅ backups.js 3POST | 需对比 |
| **MC真实列**: 用户/桌面/组/间隔天数/保留份数/备份位置/定时时间/最后备份时间/状态/备注/操作 | | |

### 13. 快照管理
| MC功能 | 我们的状态 | 差距说明 |
|--------|-----------|---------|
| 快照策略(8列) | ✅ SnapshotPolicies.vue 92行 | 需对比列 |
| 快照设置 | ⚠️ | 需确认 |
| **MC真实列**: 策略名称/描述/发布规则数/快照时间/保留个数/下次开始时间/生效/操作 | | |

### 14. 终端管理
| MC功能 | 我们的状态 | 差距说明 |
|--------|-----------|---------|
| 终端列表 | ⚠️ Clients.vue 96行无API | ❌ 缺API |
| 电源管理/软件升级/系统升级 | ⚠️ | ❌ 缺实现 |
| 批量删除 | ⚠️ | ❌ 缺实现 |
| **MC页面**: client_index (2个表: grid-table-terminal, grid-table-task) | | |

### 15. 其他
| MC功能 | 我们的状态 | 差距说明 |
|--------|-----------|---------|
| 任务中心 | ✅ TaskCenter.vue 127行 | 需对比 |
| 审批中心 | ✅ ApprovalCenter.vue 107行 | 需对比 |
| 回收站(3个tab) | ⚠️ RecycleBin.vue 81行无API | ❌ 缺API |
| 一键检测 | ⚠️ OneClickDetection.vue 72行无API | ❌ 缺API |
| 文件管理 | ⚠️ FileManage.vue 143行无API | ❌ 缺API |

---

## 三、关键差距总结

### A. 完全缺失API的模块 (前端骨架有，后端为空)
1. **应用管控** (AppManagement) - 无独立路由文件
2. **终端管理** (Clients) - 无路由文件
3. **负载均衡/自动伸缩** (ScalingConfig) - 无路由文件
4. **僵尸云服务器** (ZombieServers) - 无路由文件
5. **回收站** (RecycleBin) - 无路由文件
6. **一键检测** (OneClickDetection) - 无路由文件
7. **文件管理** (FileManage) - 无路由文件
8. **客户端接入控制** (TerminalUser) - 无路由文件
9. **存储详情** (StorageDetail) - 无API

### B. 缺失的数据库表
1. app_control_rules (应用管控规则)
2. app_layers (应用程序层)
3. software_library (软件库)
4. virtual_app_groups (应用组)
5. load_balancers (负载均衡)
6. scaling_groups (自动伸缩组)
7. scaling_strategies (自动伸缩策略)
8. zombie_servers (僵尸服务器)
9. terminals (终端)
10. organizations (组织)
11. access_policies (访问策略)
12. port_mirroring (端口镜像)
13. vlan_pools (VLAN池)
14. network_config_rules (网络配置规则)

### C. 需要端到端对比测试的核心模块
每个模块需要：
1. 抓取真实MC的API响应数据
2. 对比我们系统的API响应格式
3. 对比前端列表列/按钮/表单字段
4. 截图对比UI

---

## 四、实施顺序（按优先级）

### Phase A: 核心模块补全（先让所有页面能正常显示和交互）

**Sprint 1: 补全缺失API (1-2天)**
1. 创建 server/src/routes/app-control.js
2. 创建 server/src/routes/clients.js  
3. 创建 server/src/routes/scaling.js
4. 创建 server/src/routes/recycle-bin.js
5. 创建 server/src/routes/file-manage.js
6. 创建 server/src/routes/organization.js
7. 补充缺失数据库表
8. 为所有无API的Vue组件添加接口调用

**Sprint 2: 对比真实MC API响应格式 (1天)**
1. 编写脚本抓取真实MC的所有API JSON响应
2. 对比每个API的请求/响应格式
3. 调整我们的API格式匹配真实系统

**Sprint 3: 前端列/字段对齐 (1-2天)**
1. 逐页对比每个jqGrid的colNames和colModel
2. 调整每个el-table的列定义
3. 补全按钮和操作功能

### Phase B: 端到端测试

**Sprint 4: 自动化对比测试 (1天)**
1. 编写e2e测试脚本，自动对比真实MC vs 我们的系统
2. 对比内容：页面标题、表格列数、按钮数量、API响应格式
3. 生成差异报告

**Sprint 5: 逐模块修复差异 (2-3天)**
1. 按差异报告逐个修复
2. 每修复一个模块立即重新测试

### Phase C: LibVirt集成与真实操作

**Sprint 6: VM操作验证 (1天)**
1. 在Linux服务器上测试所有VM操作
2. 验证libvirt-driver.js的每个操作

---

## 五、测试策略

### 1. API对比测试
```bash
# 对每个MC API endpoint:
# 1) curl 真实MC获取响应
# 2) curl 我们的系统获取响应  
# 3) 对比JSON结构
```

### 2. 页面对比测试
```bash
# 对每个页面:
# 1) 抓取真实MC的HTML结构
# 2) 对比我们页面的DOM结构
# 3) 验证按钮、列、表单字段一致性
```

### 3. 功能操作测试
```bash
# 对每个CRUD操作:
# 1) 在真实MC执行操作
# 2) 在我们系统执行相同操作
# 3) 验证结果一致
```
