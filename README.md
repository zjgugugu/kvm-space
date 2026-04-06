# KVM Cloud 云管理平台

基于 KVM/libvirt 的企业级虚拟桌面云管理平台，兼容麒麟信安云V7R023管理界面。  
提供**管理控制台（MC, 端口8444）**和**总控虚拟化界面（Cockpit, 端口9091）**双系统架构。

## 系统架构

```
┌─────────────────────────────────────────────────────┐
│                   浏览器                              │
│  https://<IP>:8444  (管理控制台)                       │
│  https://<IP>:9091  (总控虚拟化界面)                    │
└──────────┬──────────────────────┬────────────────────┘
           │                      │
┌──────────▼──────────┐  ┌───────▼───────────────┐
│  MC Server (8444)   │  │  Cockpit Server (9091)│
│  Node.js + Express  │  │  Node.js + Express    │
│  26 API 路由模块     │  │  5 API 路由模块        │
│  sql.js (SQLite)    │  │  sql.js (SQLite)      │
│  Libvirt 驱动       │  │  系统管理命令          │
└──────────┬──────────┘  └───────┬───────────────┘
           │                      │
┌──────────▼──────────────────────▼───────────────┐
│              KylinSec OS Linux 3                 │
│         KVM / libvirt / QEMU (aarch64)           │
└─────────────────────────────────────────────────┘
```

## 功能模块

### 管理控制台 (MC, 端口 8444)

| 模块 | 功能 |
|------|------|
| 仪表盘 | 集群总览、CPU/内存/存储使用率、虚拟机/宿主机统计 |
| 虚拟机管理 | 创建/启动/停止/暂停/恢复/重启/迁移/删除、VNC控制台 |
| 宿主机管理 | 硬件信息自动检测、实时监控、维护模式 |
| 模板系统 | 黄金镜像管理、基于模板快速创建虚拟机 |
| 规格管理 | 预定义 CPU/内存/磁盘配置 |
| 桌面池 | VDI 桌面池管理（自动/手动） |
| 网络管理 | 虚拟交换机、子网、VLAN |
| 存储管理 | 存储池、磁盘分配 |
| 快照策略 | 定时快照、自动清理 |
| 备份管理 | 定时备份、保留策略 |
| 发布规则 | 应用发布/推送 |
| 应用管理 | 内置规则/自定义规则/软件管理/发布 |
| 用户管理 | 三级角色（系统管理员/安全管理员/审计管理员） |
| 终端绑定 | 终端与桌面绑定 |
| 客户端管理 | 客户端列表、任务下发 |
| 告警管理 | 三级阈值（紧急/严重/一般）、告警记录 |
| 事件日志 | 操作审计、服务器事件 |
| 报表统计 | 资源使用统计 |
| 系统配置 | HA/DRS/DPM/动态策略/标签/亲和性/组织/快照/启动顺序 |
| 伸缩配置 | 自动伸缩策略 |
| 僵尸服务器 | 僵尸资源检测与清理 |
| 一键检测 | 系统状态快速检测 |
| 回收站 | 已删除资源恢复 |
| 文件管理 | 虚拟机文件操作 |
| 维护管理 | 系统维护（清理/优化/日志/服务状态） |

### 总控虚拟化界面 (Cockpit, 端口 9091)

| 模块 | 功能 |
|------|------|
| 系统概览 | 主机名/OS/内核、CPU/内存/交换分区使用率、磁盘/网络接口 |
| 虚拟化 | 单机/集群部署向导、节点管理、存储状态、GlusterFS/NFS/CIFS |
| 存储维护 | 脑裂恢复、备份管理、日志记录、网络监测 |
| 服务管理 | systemd 服务列表、启动/停止/重启/启用/禁用 |
| 系统日志 | journalctl 查看器、按级别/服务过滤 |
| 网络管理 | 网络接口、路由表、DNS 配置 |
| 存储管理 | 文件系统、LVM 卷组、块设备 |

## 技术栈

| 组件 | MC (8444) | Cockpit (9091) |
|------|-----------|----------------|
| 前端 | Vue 3 + Element Plus + ECharts + Vite | Vue 2 + Element UI (单页面) |
| 后端 | Node.js 14 + Express | Node.js 14 + Express |
| 数据库 | sql.js (SQLite in memory) | sql.js (独立 cockpit.db) |
| 虚拟化 | libvirt / virsh / qemu-img | execSync (系统命令) |
| 认证 | JWT + bcryptjs | JWT + bcryptjs |
| 传输 | HTTPS (自签名证书) | HTTPS (自签名证书) |

## 项目结构

```
kvm-space/
├── server/                      # MC 后端 (端口 8444)
│   ├── src/
│   │   ├── app.js               # 主入口
│   │   ├── db/
│   │   │   ├── schema.js        # 数据库 Schema (31+ 表)
│   │   │   └── sqlite-wrapper.js
│   │   ├── routes/              # API 路由 (26 个模块)
│   │   │   ├── auth.js          # 认证 (登录/登出)
│   │   │   ├── dashboard.js     # 仪表盘 (5 接口)
│   │   │   ├── vms.js           # 虚拟机管理
│   │   │   ├── hosts.js         # 宿主机管理
│   │   │   ├── templates.js     # 模板管理
│   │   │   ├── specs.js         # 规格管理
│   │   │   ├── desktop-pools.js # 桌面池
│   │   │   ├── networks.js      # 网络管理
│   │   │   ├── network-extra.js # 网络扩展
│   │   │   ├── storage.js       # 存储管理
│   │   │   ├── snapshot-policies.js # 快照策略
│   │   │   ├── backups.js       # 备份管理
│   │   │   ├── publish-rules.js # 发布规则
│   │   │   ├── app-management.js # 应用管理
│   │   │   ├── users.js         # 用户管理
│   │   │   ├── terminal-bindings.js # 终端绑定
│   │   │   ├── clients.js       # 客户端管理
│   │   │   ├── alerts.js        # 告警管理
│   │   │   ├── events.js        # 事件日志
│   │   │   ├── stats.js         # 统计
│   │   │   ├── system.js        # 系统配置
│   │   │   ├── system-extra.js  # 系统扩展
│   │   │   ├── scaling.js       # 伸缩配置
│   │   │   ├── recycle-bin.js   # 回收站
│   │   │   ├── file-manage.js   # 文件管理
│   │   │   └── maintenance.js   # 维护管理
│   │   └── virt/                # 虚拟化驱动
│   │       ├── driver.js        # 基类
│   │       ├── mock-driver.js   # 模拟驱动
│   │       └── libvirt-driver.js # Libvirt 驱动
│   ├── data/                    # MC 数据库
│   └── package.json
├── web/                         # MC 前端 (Vue 3)
│   ├── src/
│   │   ├── api/index.js         # Axios API 客户端
│   │   ├── router/index.js      # Vue Router (41 路由)
│   │   ├── store/auth.js        # Pinia 认证状态
│   │   ├── layouts/MainLayout.vue
│   │   └── views/               # 41 个 Vue 页面
│   ├── dist/                    # 构建产物
│   └── package.json
├── cockpit/                     # Cockpit 总控虚拟化界面 (端口 9091)
│   ├── server/
│   │   └── src/
│   │       ├── app.js           # 主入口
│   │       ├── schema.js        # Cockpit 数据库 Schema
│   │       └── routes/          # API 路由 (5 个模块)
│   │           ├── auth.js      # 认证
│   │           ├── cluster.js   # 集群管理
│   │           ├── config.js    # 高级配置
│   │           ├── maintain.js  # 存储维护
│   │           └── system.js    # 系统管理
│   └── web/
│       └── index.html           # 单页面前端 (Vue 2 + Element UI)
├── certs/                       # SSL 证书
├── start.sh                     # 统一启动脚本
├── scripts/                     # 运维脚本
│   ├── tests/                   # 自动化测试
│   │   ├── test-api-v2.sh       # MC API 测试 (41/41)
│   │   ├── test-sub-apis.sh     # MC 子 API 测试 (7/7)
│   │   └── test-cockpit-api.sh  # Cockpit API 测试 (42/42)
│   ├── services/                # 服务管理脚本
│   └── utilities/               # 工具脚本
└── docs/                        # 文档
    └── research/                # 研究分析文档
```

## 快速部署

### 环境要求

- **操作系统**: KylinSec OS Linux 3 / CentOS 7+ / RHEL 7+ (aarch64 或 x86_64)
- **Node.js**: v14+ (服务器上使用 `/usr/local/node-v14.21.3-linux-arm64/bin/node`)
- **libvirt**: 5.0+ (KVM 虚拟化)
- **CPU**: 需要硬件虚拟化支持

### 1. 部署代码

```bash
git clone https://github.com/zjgugugu/kvm-space.git /opt/kvm-space
cd /opt/kvm-space

# 安装 MC 后端依赖
cd server && npm install && cd ..

# 安装 Cockpit 后端依赖
cd cockpit/server && npm install && cd ../..
```

### 2. 生成 SSL 证书

```bash
mkdir -p certs
openssl req -x509 -newkey rsa:2048 -keyout certs/server.key -out certs/server.crt \
  -days 3650 -nodes -subj '/CN=kvm-cloud'
```

### 3. 启动服务

```bash
# 启动 MC (端口 8444)
cd /opt/kvm-space
node server/src/app.js &

# 启动 Cockpit (端口 9091)
node cockpit/server/src/app.js &
```

或使用统一启动脚本:

```bash
bash start.sh
```

### 4. 访问

| 服务 | URL | 默认账号 |
|------|-----|----------|
| 管理控制台 (MC) | `https://<IP>:8444` | admin / admin123 |
| 总控虚拟化界面 (Cockpit) | `https://<IP>:9091` | root / root |

其他 MC 账号:

| 角色 | 用户名 | 密码 |
|------|--------|------|
| 超级管理员 | root | root |
| 安全管理员 | secadmin | admin123 |
| 审计管理员 | auditor | admin123 |

> ⚠️ 首次部署后请修改默认密码。

## API 概览

### MC API (端口 8444)

所有接口以 `/api` 为前缀，需 JWT 认证（除登录和 `/api/info`）。  
列表接口统一返回 `{ data: [...], total: N }` 格式。

```bash
# 登录
TOKEN=$(curl -sk https://localhost:8444/api/auth/login \
  -X POST -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"admin123"}' | grep -o '"token":"[^"]*"' | cut -d'"' -f4)

# 查询虚拟机
curl -sk -H "Authorization: Bearer $TOKEN" https://localhost:8444/api/vms
```

主要接口 (共 70+ 端点):

| 模块 | 接口示例 | 说明 |
|------|----------|------|
| 认证 | `POST /api/auth/login` | 登录 |
| 仪表盘 | `GET /api/dashboard/overview` | 集群概览 |
| 虚拟机 | `GET /api/vms`, `POST /api/vms/:id/action` | CRUD + 生命周期 |
| 宿主机 | `GET /api/hosts`, `GET /api/hosts/:id/stats` | 列表 + 实时统计 |
| 模板 | `GET /api/templates` | 模板管理 |
| 网络 | `GET /api/networks`, `GET /api/network-extra/subnets` | 交换机 + 子网 |
| 存储 | `GET /api/storage` | 存储池 + 磁盘 |
| 快照策略 | `GET /api/snapshot-policies` | 定时快照 |
| 备份 | `GET /api/backups` | 备份管理 |
| 告警 | `GET /api/alerts`, `GET /api/alerts/settings` | 告警 + 阈值设置 |
| 事件 | `GET /api/events` | 操作审计 |
| 系统 | `GET /api/system/config` | 系统配置 |
| 维护 | `GET /api/maintenance/system-info` | 系统维护 |

### Cockpit API (端口 9091)

| 模块 | 接口 | 说明 |
|------|------|------|
| 公开 | `GET /api/info` | 系统信息（无需认证） |
| 认证 | `POST /api/auth/login` | 登录 |
| 集群 | `GET /api/cluster/status`, `POST /api/cluster/deploy` | 集群部署与管理 |
| 配置 | `GET /api/config/ntp`, `PUT /api/config/nfs` | NTP/NFS/CIFS/集中存储 |
| 维护 | `GET /api/maintain/backups`, `POST /api/maintain/recovery/scan` | 存储维护 |
| 系统 | `GET /api/system/overview` | CPU/内存/磁盘/网络 |
| 系统 | `GET /api/system/services` | systemd 服务管理 |
| 系统 | `GET /api/system/logs` | journalctl 日志 |
| 系统 | `GET /api/system/networking` | 网络接口/路由/DNS |
| 系统 | `GET /api/system/storage` | 块设备/文件系统/LVM |
| 系统 | `GET /api/system/accounts` | 系统账户 |

## 测试

```bash
# MC API 测试 (41 端点)
bash scripts/tests/test-api-v2.sh       # 41/41 ✅

# MC 子 API 测试 (7 端点)
bash scripts/tests/test-sub-apis.sh     # 7/7 ✅

# Cockpit API 测试 (42 端点)
bash scripts/tests/test-cockpit-api.sh  # 42/42 ✅

# 虚拟机生命周期测试 (15 操作)
bash scripts/tests/test-vm-lifecycle3.sh # 15/15 ✅
```

总计: **105/105** 自动化测试全部通过。

## 开发

```bash
# 前端开发（Windows 热重载）
cd web
npx vite --host    # http://localhost:5173

# 前端构建
cd web
npx vite build     # 输出到 dist/

# 后端开发（Mock 模式，无需 libvirt）
cd server
KVM_MODE=mock node src/app.js
```

## 许可证

MIT
