# 服务器架构分析

## 服务器基本信息
- **IP**: 10.126.33.238
- **主机名**: node1
- **OS**: KylinSec OS Linux 3 (Core)，类RHEL/Fedora
- **架构**: aarch64 (ARM64)
- **用户**: root / unikylinsec

## 运行中的关键服务

| 服务 | 描述 | 端口 |
|------|------|------|
| cockpit.service | Cockpit Web Service (总控界面) | 9090 |
| KSVD.service | KSVD systemd Service (主服务) | - |
| KSVD-storaged.service | KSVD存储守护 | - |
| kylinproxy.service | ksvdproxy代理 | - |
| libvirtd.service | 虚拟化守护进程 | 16509 |
| mariadb.service | MariaDB 10.3.31数据库 | 3306(内部) |
| rabbitmq-server.service | RabbitMQ消息队列 | 15672, 25672, 4369 |
| sshd.service | SSH服务 | 22 |

## 端口详情

| 端口 | 进程 | 用途 |
|------|------|------|
| 22 | sshd | SSH远程管理 |
| 139/445 | smbd | Samba文件共享 |
| 5900-5901 | qemu-kvm | VNC远程桌面 |
| 6080 | python | noVNC Web代理 |
| 6881/6969 | uniqb-p2pclient/opentracker | P2P镜像分发 |
| 8088 | python | 内部API |
| 8443 | java (Tomcat) | MC管理控制台 |
| 9090 | cockpit-ws | Cockpit总控界面 |
| 9092 | gluster_proxy | GlusterFS代理 |
| 16509 | libvirtd | libvirt远程管理 |
| 24007 | glusterd | GlusterFS管理 |
| 48616 | ksvdcmd | KSVD命令服务 |
| 48622 | ksvdmpcd | KSVD MPC服务 |
| 48642-48643 | ksvdsmartd | KSVD SMART监控 |
| 49152-49153 | glusterfsd | GlusterFS brick |

## Java进程

### 1. Tomcat (MC管理控制台)
- **JVM**: OpenJDK 1.8.0_181 (aarch64)
- **路径**: /usr/lib/ksvd/etc/apache-tomcat
- **内存**: -Xms4096m -Xmx4096m
- **端口**: 8443 (HTTPS), 8005 (shutdown)
- **Webapp**: /usr/lib/ksvd/etc/apache-tomcat/webapps/mc
- **框架**: Grails (GSP模板引擎)
- **用户**: kylin-ksvd

### 2. DCS微服务 (Spring Boot)
- **JAR**: /usr/lib/ksvd/etc/micro-service/dcs.jar
- **配置**: --spring.profiles.active=prod
- **内存**: -Xms2048m -Xmx2048m
- **日志**: /var/lib/ksvd/mc/dcs-gc-*.log
- **用户**: kylin-ksvd

### 3. HSQLDB数据库
- **JAR**: /usr/lib/ksvd/etc/hsqldb/hsqldb/lib/hsqldb.jar
- **角色**: 嵌入式/Server模式数据库

## 文件系统

### KSVD核心目录
- `/usr/lib/ksvd/` - KSVD安装目录
  - `bin/` - 180+命令行工具和脚本
  - `etc/apache-tomcat/` - Tomcat + MC webapp
  - `etc/micro-service/` - Spring Boot微服务
  - `etc/hsqldb/` - HSQLDB数据库
- `/var/lib/ksvd/` - KSVD运行数据
  - `mc/` - MC运行时数据
  - `settings.node` - 节点配置
  - `server.xml` - 服务器配置
- `/home/kylin-ksvd/` - 共享存储(GlusterFS挂载)
  - `.ksvd/` - SSH密钥等共享配置
  - `cockpit/` - Cockpit自定义
  - `db/` - 数据库
  - `ISO/` - ISO镜像
  - `logs/` - 日志
  - `torrent/` - P2P种子
  - `network/` - 网络配置
  - `ha/` - 高可用配置

### KSVD节点角色（settings.node）
- CM_VDI: 管理+计算节点
- CM_Only: 仅管理节点
- VDI_Only: 仅计算节点
- Arbiter: 仲裁节点
- Gateway: 网关节点
- VDE_Only: 瘦终端节点

## Cron定时任务
```
0 0 * * * /bin/bash /usr/lib/ksvd/bin/db_backup.sh                    # 每日数据库备份
* * * * * /usr/lib/ksvd/bin/collect_log_files.py --function=timer_task_every_minute  # 每分钟日志采集
*/1 * * * * /usr/lib/ksvd/bin/authorizedkeys.sh                       # 每分钟SSH密钥同步
```

## SSH密钥同步机制
- 脚本: `/usr/lib/ksvd/bin/authorizedkeys.sh`
- 共享存储密钥: `/home/kylin-ksvd/.ksvd/authorized_keys`
- 本地密钥: `/root/.ssh/authorized_keys`
- 机制: 每分钟从共享存储同步到本地
- **解决**: 我们的公钥已添加到共享存储，免密登录持久化
