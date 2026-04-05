# 总控虚拟化界面 (Cockpit, 端口9090) 分析

## 访问信息
- **URL**: https://10.126.33.238:9090/
- **账号**: root / unikylinsec
- **技术栈**: Cockpit Web Framework + Vue.js + Element UI + Vuex
- **进程**: cockpit-ws (端口9090) + cockpit-bridge

## Cockpit模块列表 (/usr/share/cockpit/)
| 模块 | 类型 | 描述 |
|------|------|------|
| base1 | 核心 | Cockpit基础库(cockpit.js, jquery.js) |
| branding | 核心 | 品牌/主题 |
| shell | 核心 | 主Shell界面 |
| static | 核心 | 静态资源(CSS/JS/images) |
| **virtualization** | **自定义** | **虚拟化管理** (order:1, label:"虚拟化") |
| **maintain** | **自定义** | **存储维护** (order:2, label:"存储维护") |
| networkmanager | 系统 | 网络管理 |
| systemd | 系统 | 服务管理 |
| realmd | 系统 | 域加入 |
| tuned | 系统 | 性能调优 |
| motd | 系统 | 每日提示 |

## 虚拟化模块 (/usr/share/cockpit/virtualization/)

### 技术栈
- Vue.js 2 (非SFC，直接JS组件)
- Vuex 状态管理
- Element UI 组件库
- Cockpit.js API (与systemd/dbus交互)
- Bundle: bundle.min.js (构建产物)

### 前端结构
```
index.html          # 入口，引入Vue/Vuex/ElementUI/bundle.min.js
manifest.json       # Cockpit模块配置 {"虚拟化", order:1}
bundle.min.js       # 打包后的JS

/static/js/virtual/
  index.js          # 主入口
  api.js            # API调用
  store.js          # Vuex store
  mixin.js          # Vue mixins
  utils.js          # 工具函数
  validate.js       # 验证器
  
  view/
    stand-alone.js          # 单机模式视图
    colony.js               # 集群模式视图
    table.js                # 部署表格
    common-components.js    # 通用组件
    
    cluster-display/        # 集群显示
      check-dialog-password.js
      check-password.js
      cifs-table.js
      gfsAlone-table.js     # GlusterFS单机表格
      gfs-table.js          # GlusterFS集群表格
      network-config.js     # 网络配置
      nfs-table.js          # NFS表格
    
    step/                   # 部署步骤
      step-addhost.js       # 添加主机
      step-attribute.js     # 属性设置
      step-bios.js          # BIOS配置
      step-hostconfig.js    # 主机配置
      step-status.js        # 状态展示
      step-storageconfig.js # 存储配置
      step-storagemode.js   # 存储模式
    
    senior/                 # 高级配置
      centralServer.js      # 集中存储服务器
      cifsConfig.js         # CIFS配置
      nfsConfig.js          # NFS配置
      ntpServer.js          # NTP服务器
      seniorDialog.js       # 高级对话框
      serverRole.js         # 服务器角色
      virtualStorage.js     # 虚拟存储
      managementNetwork/    # 管理网络
  
  components/               # 自定义组件
    el-checkpass.js         # 密码检查
    el-message.js           # 消息提示
    el-selfswitch.js        # 自定义开关
    el-tip.js               # 提示组件

/static/js/maintain/        # 存储维护模块
  index.js, api.js, mixin.js, utils.js
  components/, views/
```

### 后端脚本 (/usr/share/cockpit/virtualization/bin/)
| 脚本 | 功能 |
|------|------|
| cockpit_cli.sh | Cockpit命令行接口 |
| config_node.sh | 节点配置 |
| add_node_to_cluster.sh | 添加节点到集群 |
| clean_cluster.sh | 清理集群 |
| deploy_mysql.sh | 部署MySQL |
| deploy_rabbitmq.sh | 部署RabbitMQ |
| docker_gluster.sh | Docker GlusterFS |
| change_manage_ip.sh | 修改管理IP |
| check_cluster_status.py | 检查集群状态 |
| advanced_config.sh | 高级配置 |
| re_deploy.sh | 重新部署 |
| roll_back_add_node.sh | 回滚添加节点 |
| time_server.sh | 时间服务器 |

### Ansible Playbooks (/usr/share/cockpit/virtualization/ansible/)
- 集群部署: add_node_to_cluster, clean_cluster, config_node
- 存储管理: set_data_storage, delete_data_storage, remount_data_storage
- GlusterFS: add_gluster_duplicate, stop_MStorage, remove_brick
- 网络: change_manage_ip, change_docker_ip, config-hosts
- 角色管理: change_role, change_branch
- 电源: one_key_reboot, one_key_shutdown
- 服务: restart_ksvd, get_KSVD_service_status
- NFS/CIFS: change_nfs, change_cifs
- 时间: change_NTP_server, start_chronyd, config-time-server

### 数据库 (/usr/share/cockpit/virtualization/db/)
- cockpit.sql - Cockpit数据
- create_cockpit_table.sql - 建表SQL

### KSVD共享状态 (/home/kylin-ksvd/cockpit/)
- cockpit.sql - 同步的Cockpit数据
- custom_domain.conf - 自定义域配置
- hosts, hosts.lock, hosts.temp - 主机列表
- ksvd_status, ksvd_status.lock - KSVD服务状态
- rollback - 回滚数据

## Cockpit功能总结
1. **部署向导**: 单机/集群模式选择 → 多步骤部署(添加主机→属性→BIOS→存储→状态)
2. **集群管理**: 添加/移除节点、检查集群状态、清理集群
3. **存储管理**: GlusterFS/NFS/CIFS配置、数据存储设置
4. **高级配置**: 服务器角色、集中存储、NTP、管理网络
5. **存储维护**: 独立模块，存储健康检查和维护
6. **一键检测**: detection目录下的检测工具
