# KVM Cloud 虚拟化管理平台

基于 KVM/libvirt 的企业级虚拟桌面云管理平台，提供完整的虚拟机生命周期管理、宿主机监控、模板管理等功能。

## 功能特性

- **虚拟机管理** — 创建、启动、停止、暂停、恢复、重启、强制停止、删除
- **快照管理** — 创建、回滚、删除快照，支持定时快照策略
- **宿主机管理** — 自动检测硬件信息，实时监控 CPU/内存/磁盘/负载
- **模板系统** — 黄金镜像管理，基于模板快速创建虚拟机
- **规格管理** — 预定义 CPU/内存/磁盘配置，标准化虚拟机规格
- **用户管理** — 三级角色体系（系统管理员/安全管理员/审计管理员）
- **网络管理** — 桥接网络、NAT 网络配置
- **存储管理** — 存储池管理和磁盘分配
- **事件审计** — 完整的操作日志记录
- **仪表盘** — 集群总览、资源使用率、实时统计

## 技术栈

| 层级 | 技术 |
|------|------|
| 前端 | Vue 3 + Element Plus + ECharts + Vite |
| 后端 | Node.js + Express |
| 数据库 | SQLite (better-sqlite3) |
| 虚拟化 | KVM / libvirt / QEMU |
| 认证 | JWT + bcryptjs |

## 项目结构

```
kvm-cloud/
├── server/                     # 后端服务
│   ├── src/
│   │   ├── app.js              # 主入口
│   │   ├── db/
│   │   │   ├── schema.js       # 数据库 Schema
│   │   │   └── sqlite-wrapper.js
│   │   ├── routes/             # API 路由 (16个模块)
│   │   │   ├── auth.js         # 认证
│   │   │   ├── vms.js          # 虚拟机
│   │   │   ├── hosts.js        # 宿主机
│   │   │   ├── templates.js    # 模板
│   │   │   ├── specs.js        # 规格
│   │   │   ├── networks.js     # 网络
│   │   │   ├── storage.js      # 存储
│   │   │   ├── users.js        # 用户
│   │   │   ├── events.js       # 事件
│   │   │   ├── dashboard.js    # 仪表盘
│   │   │   ├── alerts.js       # 告警
│   │   │   ├── backups.js      # 备份
│   │   │   ├── stats.js        # 统计
│   │   │   ├── system.js       # 系统配置
│   │   │   ├── publish-rules.js    # 发布规则
│   │   │   └── snapshot-policies.js # 快照策略
│   │   └── virt/               # 虚拟化驱动
│   │       ├── driver.js       # 驱动基类
│   │       ├── mock-driver.js  # 模拟驱动 (开发/演示)
│   │       └── libvirt-driver.js # Libvirt 真实驱动
│   ├── data/                   # SQLite 数据库存储
│   ├── start-libvirt.sh        # Libvirt 模式启动脚本
│   └── package.json
├── web/                        # 前端应用
│   ├── src/
│   │   ├── api/index.js        # Axios API 客户端
│   │   ├── router/index.js     # Vue Router
│   │   ├── store/auth.js       # Pinia 状态管理
│   │   ├── layouts/MainLayout.vue
│   │   └── views/              # 页面组件 (16个)
│   │       ├── Dashboard.vue   # 仪表盘
│   │       ├── VMs.vue         # 虚拟机列表
│   │       ├── VMDetail.vue    # 虚拟机详情
│   │       ├── Hosts.vue       # 宿主机列表
│   │       ├── HostDetail.vue  # 宿主机详情
│   │       ├── Templates.vue   # 模板管理
│   │       ├── Specs.vue       # 规格管理
│   │       ├── Networks.vue    # 网络管理
│   │       ├── Storage.vue     # 存储管理
│   │       ├── Users.vue       # 用户管理
│   │       ├── Events.vue      # 事件日志
│   │       ├── Alerts.vue      # 告警管理
│   │       ├── Reports.vue     # 报表
│   │       ├── PublishRules.vue # 发布规则
│   │       ├── System.vue      # 系统设置
│   │       └── Login.vue       # 登录
│   ├── dist/                   # 构建产物
│   └── package.json
└── .gitignore
```

## 快速开始

### 环境要求

- **操作系统**: Ubuntu 20.04+ / Debian 11+
- **Node.js**: v18+
- **libvirt**: 8.0+
- **QEMU/KVM**: 需要 CPU 虚拟化支持 (Intel VT-x / AMD-V)

### 安装步骤

#### 1. 安装系统依赖

```bash
# 安装 KVM/libvirt
sudo apt update
sudo apt install -y qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils virtinst

# 验证 KVM 支持
kvm-ok
virsh version
```

#### 2. 安装 Node.js

```bash
# 下载 Node.js 18
curl -fsSL https://nodejs.org/dist/v18.20.8/node-v18.20.8-linux-x64.tar.xz -o node-v18.tar.xz
tar -xf node-v18.tar.xz -C /usr/local/
ln -sf /usr/local/node-v18.20.8-linux-x64/bin/node /usr/local/bin/node
ln -sf /usr/local/node-v18.20.8-linux-x64/bin/npm /usr/local/bin/npm
```

#### 3. 部署项目

```bash
# 克隆代码
git clone https://github.com/zjgugugu/kvm-space.git /opt/kvm-cloud

# 安装后端依赖
cd /opt/kvm-cloud/server
npm install

# 前端已预编译在 web/dist/ 中，无需额外构建
```

#### 4. 启动服务

```bash
# Libvirt 模式 (生产环境，连接真实 KVM)
cd /opt/kvm-cloud/server
export KVM_MODE=libvirt
export PORT=3000
node src/app.js

# 或使用启动脚本
bash start-libvirt.sh

# Mock 模式 (开发/演示，无需 libvirt)
export KVM_MODE=mock
node src/app.js
```

#### 5. 访问

浏览器打开 `http://<服务器IP>:3000`

### 默认账号

| 角色 | 用户名 | 密码 | 说明 |
|------|--------|------|------|
| 系统管理员 | admin | admin123 | 全部权限 |
| 安全管理员 | secadmin | admin123 | 安全相关 |
| 审计管理员 | auditor | admin123 | 审计日志 |

> ⚠️ 首次部署后请及时修改默认密码。

## 运行模式

### Libvirt 模式 (`KVM_MODE=libvirt`)

连接本地 libvirt 守护进程，直接管理真实 KVM 虚拟机。

- 启动时自动检测宿主机硬件信息（CPU/内存/磁盘/网络）
- 通过 `virsh` 命令执行虚拟机操作
- 使用 `qemu-img` 创建和管理磁盘
- 自动设置磁盘文件权限（`libvirt-qemu:kvm`）

### Mock 模式 (`KVM_MODE=mock`)

模拟虚拟化操作，适用于开发调试和功能演示。

- 不需要安装 libvirt/QEMU
- 所有操作在内存中模拟
- 可在任何系统上运行

## API 文档

所有 API 均以 `/api` 为前缀，需 JWT 认证（除登录接口外）。

### 认证

```bash
# 登录获取 Token
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'

# 后续请求携带 Token
curl -H "Authorization: Bearer <token>" http://localhost:3000/api/vms
```

### 主要接口

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/api/auth/login` | 登录 |
| GET | `/api/info` | 系统信息（无需认证） |
| GET | `/api/dashboard/overview` | 仪表盘概览 |
| GET | `/api/hosts` | 宿主机列表 |
| GET | `/api/hosts/:id/stats` | 宿主机实时统计 |
| GET | `/api/vms` | 虚拟机列表 |
| POST | `/api/vms` | 创建虚拟机 |
| GET | `/api/vms/:id` | 虚拟机详情 |
| POST | `/api/vms/:id/action` | 虚拟机操作 |
| GET | `/api/vms/:id/snapshots` | 快照列表 |
| POST | `/api/vms/:id/snapshots` | 创建快照 |
| GET | `/api/templates` | 模板列表 |
| POST | `/api/templates` | 创建模板 |
| GET | `/api/specs` | 规格列表 |
| POST | `/api/specs` | 创建规格 |
| GET | `/api/networks` | 网络列表 |
| GET | `/api/storage` | 存储列表 |
| GET | `/api/users` | 用户列表 |
| GET | `/api/events` | 事件日志 |
| GET | `/api/alerts/settings` | 告警设置 |
| GET | `/api/system/config` | 系统配置 |
| GET | `/api/snapshot-policies` | 快照策略 |

### 虚拟机操作

```bash
# action 可选值: start, stop, force_stop, reboot, force_reboot, suspend, resume
curl -X POST http://localhost:3000/api/vms/<vm_id>/action \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"action":"start"}'
```

### 创建虚拟机流程

```bash
# 1. 创建模板
curl -X POST /api/templates -d '{
  "name": "ubuntu22",
  "os_type": "linux",
  "os_variant": "ubuntu22.04",
  "vcpus": 2,
  "memory": 2048,
  "disk_size": 20
}'

# 2. 创建规格
curl -X POST /api/specs -d '{
  "name": "small",
  "vcpus": 2,
  "memory": 2048,
  "disk_size": 20
}'

# 3. 创建虚拟机 (需要 template_id, spec_id, host_id)
curl -X POST /api/vms -d '{
  "name": "my-vm",
  "template_id": "<template_id>",
  "spec_id": "<spec_id>",
  "host_id": "<host_id>",
  "owner_id": "admin"
}'
```

## 数据存储

- **数据库**: `server/data/kvm-cloud.db` (SQLite)
- **虚拟机磁盘**: `/data/kvm-cloud/images/` (qcow2 格式)
- **ISO 镜像**: `/data/kvm-cloud/iso/`

## 后台运行

```bash
# 使用 nohup
cd /opt/kvm-cloud/server
nohup bash start-libvirt.sh > /var/log/kvm-cloud.log 2>&1 &

# 使用 systemd (推荐)
sudo cat > /etc/systemd/system/kvm-cloud.service << 'EOF'
[Unit]
Description=KVM Cloud Management Platform
After=libvirtd.service network.target

[Service]
Type=simple
WorkingDirectory=/opt/kvm-cloud/server
Environment=KVM_MODE=libvirt
Environment=PORT=3000
ExecStart=/usr/local/bin/node src/app.js
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable kvm-cloud
sudo systemctl start kvm-cloud
```

## 开发

```bash
# 前端开发 (热重载)
cd web
npm install
npm run dev    # http://localhost:5173

# 后端开发 (mock 模式)
cd server
npm install
KVM_MODE=mock node --watch src/app.js

# 前端构建
cd web
npm run build  # 输出到 dist/
```

## 许可证

MIT
