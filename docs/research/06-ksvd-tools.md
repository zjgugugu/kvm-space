# KSVD 命令行工具清单

位置: /usr/lib/ksvd/bin/

## 核心服务工具
| 工具 | 用途 |
|------|------|
| ksvdcmd | KSVD命令服务 |
| ksvdmpcd | KSVD MPC服务（多点控制） |
| ksvdsmartd | SMART磁盘健康监控 |
| ksvdudpd | UDAP协议守护进程 |
| ksvdcacheio | 缓存IO服务 |
| ksvdcmon-ni | KSVD监控 |
| ksvd-dbmond | 数据库监控 |
| ksvd-netd | 网络守护 |
| ksvdbranchd | 分支模式守护 |

## 虚拟化管理
| 工具 | 用途 |
|------|------|
| ksvd-create-gold | 创建黄金镜像 |
| ksvd-create-server | 创建云服务器 |
| ksvd-provision | 桌面分配/部署 |
| ksvd-img | 镜像管理 |
| ksvd-gold-image-format-conversion.sh | 镜像格式转换 |
| ksvd-move-gold | 移动黄金镜像 |
| ksvd-make-cdrom.sh | 创建CDROM ISO |
| ksvd-vdeimg-ctl.py | VDE镜像控制 |
| ksvd-ps | 进程管理 |
| ksvd-show | 显示信息 |
| ksvd-session-list | 会话列表 |

## SSH/密钥管理
| 工具 | 用途 |
|------|------|
| authorizedkeys.sh | SSH密钥同步 |
| ssh_copy_id.sh | SSH密钥复制 |
| ssh_keygen.sh | SSH密钥生成 |
| sshpass | SSH密码认证工具 |

## 存储管理
| 工具 | 用途 |
|------|------|
| ksvd-storaged.sh | 存储守护 |
| ksvd-storage-util | 存储工具 |
| ksvd-local-cli | 本地存储CLI |
| ksvd-disk-cli.sh | 磁盘CLI |
| ksvd-prepare-brick | 准备GlusterFS brick |
| ksvd-bcache-setup.sh | bcache缓存设置 |
| expand_data_storage_brick.py | 数据存储扩容 |
| share_storage_util.sh | 共享存储工具 |
| get_storage_info.py | 获取存储信息 |
| get_msstorage_info.py | 获取MStorage信息 |
| san-storage-util | SAN存储工具 |
| ManageSanStorageApi.py | SAN存储API |
| storage_get_disk_sync_info.py | 磁盘同步信息 |
| monitor-storage.sh | 存储监控 |

## 网络管理
| 工具 | 用途 |
|------|------|
| ksvd-dump-net-config | 导出网络配置 |
| ksvd-dump-storage-config | 导出存储配置 |
| ksvd-ip-detect.sh | IP检测 |
| ksvd_net_vsctl | 虚拟交换机控制 |
| ksvd-ovs-network-hook.sh | OVS网络钩子 |
| ksvd-tap-control | TAP设备控制 |
| port_security_node | 端口安全 |
| ovs-vsctl, ovs-vswitchd, ovs-dpctl 等 | Open vSwitch工具集 |
| brctl | 网桥控制 |
| ifcfg_cluster_manage | 集群网卡管理 |

## GPU管理
| 工具 | 用途 |
|------|------|
| ksvd-gpu-ctl.py | GPU控制 |
| ksvd-vgpu-ctl.py | vGPU控制 |
| ksvd-mxgpu-ctl.py | MxGPU控制 |
| ksvd-vdegpu-ctl.py | VDE GPU控制 |
| ksvd-pci-ctl.py | PCI设备控制 |
| ksvd-pci-pt.sh | PCI直通 |
| ksvd-vdevfio-ctl.py | VDE VFIO控制 |

## 部署/配置
| 工具 | 用途 |
|------|------|
| ksvd-deploy | 部署主控 |
| ksvd-deploy-clean | 清理部署 |
| ksvd-deploy-node.py | 节点部署 |
| ksvd-deploy-single-node | 单节点部署 |
| ksvd-auto-config | 自动配置 |
| ksvd-config | 配置管理 |
| ksvd-set-issue | 设置issue |
| ksvd-setpasswd | 设置密码 |
| ksvd-mc-runas | MC运行身份 |
| ksvd-start-tomcat.sh | 启动Tomcat |
| ksvd-start-dcs.sh | 启动DCS微服务 |
| ksvd-start-pa.sh | 启动PA |

## HA/集群
| 工具 | 用途 |
|------|------|
| uniqb-ha | HA管理 |
| ksvd-self-heal.py | 自愈 |
| ksvd-self-heal.sh | 自愈脚本 |
| mariadb_cluster_health_check.py | MariaDB集群健康 |
| rabbitmq_cluster_heal.sh | RabbitMQ集群修复 |
| heketi-keep.sh | Heketi保活 |
| ocfs2_cluster_manage | OCFS2集群管理 |

## P2P/分发
| 工具 | 用途 |
|------|------|
| uniqb-p2pclient | P2P客户端 |
| create_torrent | 创建种子 |
| dump_torrent | 查看种子 |

## 备份/诊断
| 工具 | 用途 |
|------|------|
| db_backup.sh | 数据库备份 |
| ksvd-diagnostic | 诊断工具 |
| ksvd-support-report | 支持报告 |
| onekey-detect.py | 一键检测 |
| collect_log_files.py | 日志采集 |
| collect_gluster_log.sh | GlusterFS日志 |

## uniqb系列（Uniface/客户端相关）
| 工具 | 用途 |
|------|------|
| uniqbenv | Uniface环境 |
| uniqbprod | Uniface产品 |
| uniqb-runtime | Uniface运行时 |
| uniqb-runtime-server | Uniface运行时服务器 |
| uniqb-sessions | 会话管理 |
| uniqb-session-all.pl | 所有会话 |
| uniqb-shutdown | 关闭 |
| uniqb-shutdown-all.pl | 关闭所有 |
| uniqb-usb-monitor | USB监控 |
| uniqb-print | 打印重定向 |
| uniqb-autobr | 自动桥接 |
| uniqb-findsubnet | 查找子网 |
