import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '../store/auth'

const routes = [
  {
    path: '/login',
    name: 'Login',
    component: () => import('../views/Login.vue'),
    meta: { public: true }
  },
  {
    path: '/',
    component: () => import('../layouts/MainLayout.vue'),
    redirect: '/dashboard',
    children: [
      // ===== 仪表板 =====
      { path: 'dashboard', name: 'Dashboard', component: () => import('../views/Dashboard.vue'), meta: { title: '仪表板', topNav: 'dashboard' } },

      // ===== 桌面发布 =====
      { path: 'gold-images', name: 'GoldImages', component: () => import('../views/Templates.vue'), meta: { title: '黄金镜像', topNav: 'desktop-publish', sideNav: 'gold-images' } },
      // 桌面发布子菜单
      { path: 'desktop-assignment', name: 'DesktopAssignment', component: () => import('../views/PublishRules.vue'), meta: { title: '发布规则', topNav: 'desktop-publish', sideNav: 'desktop-publish' } },
      { path: 'session-settings', name: 'SessionSettings', component: () => import('../views/Specs.vue'), meta: { title: '会话设置', topNav: 'desktop-publish', sideNav: 'desktop-publish' } },
      { path: 'desktop-pools', name: 'DesktopPools', component: () => import('../views/DesktopPools.vue'), meta: { title: '桌面池', topNav: 'desktop-publish', sideNav: 'desktop-publish' } },
      { path: 'app-layers', name: 'AppLayers', component: () => import('../views/AppManagement.vue'), meta: { title: '应用程序层', topNav: 'desktop-publish', sideNav: 'desktop-publish' } },
      { path: 'software-library', name: 'SoftwareLibrary', component: () => import('../views/AppManagement.vue'), meta: { title: '软件库', topNav: 'desktop-publish', sideNav: 'desktop-publish' } },
      { path: 'software-publish', name: 'SoftwarePublish', component: () => import('../views/AppManagement.vue'), meta: { title: '软件发布', topNav: 'desktop-publish', sideNav: 'desktop-publish' } },
      // 应用管控
      { path: 'app-control/builtin', name: 'AppControlBuiltin', component: () => import('../views/AppManagement.vue'), meta: { title: '内置规则', topNav: 'desktop-publish', sideNav: 'app-control' } },
      { path: 'app-control/custom', name: 'AppControlCustom', component: () => import('../views/AppManagement.vue'), meta: { title: '自定义应用', topNav: 'desktop-publish', sideNav: 'app-control' } },
      // 应用发布
      { path: 'virtual-app/groups', name: 'VirtualAppGroups', component: () => import('../views/AppManagement.vue'), meta: { title: '应用组', topNav: 'desktop-publish', sideNav: 'app-publish' } },
      { path: 'virtual-app/sessions', name: 'VirtualAppSessions', component: () => import('../views/AppManagement.vue'), meta: { title: '应用会话', topNav: 'desktop-publish', sideNav: 'app-publish' } },
      // 用户管理
      { path: 'users', name: 'Users', component: () => import('../views/Users.vue'), meta: { title: '用户管理', topNav: 'desktop-publish', sideNav: 'user-mgmt' } },
      { path: 'user-groups', name: 'UserGroups', component: () => import('../views/Users.vue'), meta: { title: '用户组', topNav: 'desktop-publish', sideNav: 'user-mgmt', defaultTab: 'groups' } },
      { path: 'ldap-servers', name: 'LdapServers', component: () => import('../views/Users.vue'), meta: { title: 'LDAP服务器', topNav: 'desktop-publish', sideNav: 'user-mgmt', defaultTab: 'ldap' } },
      { path: 'terminal-user', name: 'TerminalAndUser', component: () => import('../views/TerminalUser.vue'), meta: { title: '终端与用户', topNav: 'desktop-publish', sideNav: 'user-mgmt' } },

      // ===== 桌面虚拟机 =====
      { path: 'vms', name: 'VMs', component: () => import('../views/VMs.vue'), meta: { title: '桌面虚拟机', topNav: 'desktop-vm' } },
      { path: 'vms/:id', name: 'VMDetail', component: () => import('../views/VMDetail.vue'), meta: { title: '虚拟机详情', topNav: 'desktop-vm' } },

      // ===== 服务器虚拟化 =====
      { path: 'server-virt', name: 'ServerVirtualization', component: () => import('../views/ServerVirt.vue'), meta: { title: '云服务器', topNav: 'server-virt' } },
      { path: 'server-virt/:id', name: 'ServerVirtDetail', component: () => import('../views/VMDetail.vue'), meta: { title: '云服务器详情', topNav: 'server-virt' } },

      // ===== 网络池 =====
      { path: 'networks', name: 'Networks', component: () => import('../views/Networks.vue'), meta: { title: '网络池', topNav: 'network', sideNav: 'network-pool' } },
      { path: 'networks/vswitch/:name', name: 'VSwitchDetail', component: () => import('../views/VSwitchDetail.vue'), meta: { title: '虚拟交换机', topNav: 'network', sideNav: 'vswitch' } },
      { path: 'networks/security-groups', name: 'SecurityGroups', component: () => import('../views/SecurityGroups.vue'), meta: { title: '安全组', topNav: 'network', sideNav: 'network-pool' } },
      { path: 'networks/port-groups', name: 'PortGroups', component: () => import('../views/NetworkSubPage.vue'), meta: { title: '端口组', topNav: 'network', sideNav: 'network-pool' } },
      { path: 'networks/subnets', name: 'Subnets', component: () => import('../views/NetworkSubPage.vue'), meta: { title: '子网', topNav: 'network', sideNav: 'network-pool' } },
      { path: 'networks/mac-pool', name: 'MacPool', component: () => import('../views/MacPool.vue'), meta: { title: 'MAC地址池', topNav: 'network', sideNav: 'network-pool' } },
      { path: 'networks/vlan-pool', name: 'VlanPool', component: () => import('../views/NetworkSubPage.vue'), meta: { title: 'VLAN池', topNav: 'network', sideNav: 'network-pool' } },
      { path: 'networks/port-mirroring', name: 'PortMirroring', component: () => import('../views/NetworkSubPage.vue'), meta: { title: '端口镜像', topNav: 'network', sideNav: 'network-pool' } },
      { path: 'networks/config-rules', name: 'NetworkConfigRules', component: () => import('../views/NetworkSubPage.vue'), meta: { title: '配置规则', topNav: 'network', sideNav: 'network-pool' } },
      { path: 'networks/firewall', name: 'VirtualFirewall', component: () => import('../views/NetworkSubPage.vue'), meta: { title: '虚拟防火墙', topNav: 'network', sideNav: 'network-pool' } },

      // ===== 存储池 =====
      { path: 'storage', name: 'Storage', component: () => import('../views/Storage.vue'), meta: { title: '存储池', topNav: 'storage', sideNav: 'storage-pool' } },
      { path: 'storage/:name', name: 'StorageDetail', component: () => import('../views/StorageDetail.vue'), meta: { title: '数据存储详情', topNav: 'storage', sideNav: 'data-store' } },

      // ===== 一体机 (物理机) =====
      { path: 'hosts', name: 'Hosts', component: () => import('../views/Hosts.vue'), meta: { title: '一体机', topNav: 'hosts' } },
      { path: 'hosts/:id', name: 'HostDetail', component: () => import('../views/HostDetail.vue'), meta: { title: '服务器详情', topNav: 'hosts' } },

      // ===== 日志告警 =====
      { path: 'log/server-events', name: 'ServerEvents', component: () => import('../views/Events.vue'), meta: { title: '服务器事件', topNav: 'log-alarm', sideNav: 'log' } },
      { path: 'log/session-events', name: 'SessionEvents', component: () => import('../views/EventLog.vue'), meta: { title: '会话事件', topNav: 'log-alarm', sideNav: 'log' } },
      { path: 'log/server-virt-events', name: 'ServerVirtEvents', component: () => import('../views/EventLog.vue'), meta: { title: '服务器虚拟化事件', topNav: 'log-alarm', sideNav: 'log' } },
      { path: 'log/audit-events', name: 'AuditEvents', component: () => import('../views/EventLog.vue'), meta: { title: '审计事件', topNav: 'log-alarm', sideNav: 'log' } },
      { path: 'log/client-audit', name: 'ClientAuditEvents', component: () => import('../views/EventLog.vue'), meta: { title: '终端审计事件', topNav: 'log-alarm', sideNav: 'log' } },
      { path: 'alarm/events', name: 'AlarmEvents', component: () => import('../views/Alerts.vue'), meta: { title: '告警事件', topNav: 'log-alarm', sideNav: 'alarm' } },
      { path: 'alarm/settings', name: 'AlarmSettings', component: () => import('../views/AlarmSettings.vue'), meta: { title: '告警设置', topNav: 'log-alarm', sideNav: 'alarm' } },

      // ===== 统计报表 =====
      { path: 'stats/user-login', name: 'StatsUserLogin', component: () => import('../views/StatsView.vue'), meta: { title: '登录统计', topNav: 'statistics', sideNav: 'stats-user' } },
      { path: 'stats/user-online', name: 'StatsUserOnline', component: () => import('../views/StatsView.vue'), meta: { title: '在线人数', topNav: 'statistics', sideNav: 'stats-user' } },
      { path: 'stats/user-time', name: 'StatsUserTime', component: () => import('../views/StatsView.vue'), meta: { title: '使用时长', topNav: 'statistics', sideNav: 'stats-user' } },
      { path: 'stats/user-usb', name: 'StatsUserUsb', component: () => import('../views/StatsView.vue'), meta: { title: 'USB统计', topNav: 'statistics', sideNav: 'stats-user' } },
      { path: 'stats/data-copy', name: 'StatsDataCopy', component: () => import('../views/StatsView.vue'), meta: { title: '数据拷贝审计', topNav: 'statistics', sideNav: 'stats-user' } },
      { path: 'stats/vm-status', name: 'StatsVmStatus', component: () => import('../views/StatsView.vue'), meta: { title: '虚拟机状态', topNav: 'statistics', sideNav: 'stats-vm' } },
      { path: 'stats/vm-unused', name: 'StatsVmUnused', component: () => import('../views/StatsView.vue'), meta: { title: '闲置虚拟机', topNav: 'statistics', sideNav: 'stats-vm' } },
      { path: 'stats/sv-resource', name: 'StatsSvResource', component: () => import('../views/StatsView.vue'), meta: { title: '资源统计', topNav: 'statistics', sideNav: 'stats-sv' } },
      { path: 'stats/sv-top', name: 'StatsSvTop', component: () => import('../views/StatsView.vue'), meta: { title: 'Top统计', topNav: 'statistics', sideNav: 'stats-sv' } },
      { path: 'stats/op-user', name: 'StatsOpUser', component: () => import('../views/StatsView.vue'), meta: { title: '运维用户', topNav: 'statistics', sideNav: 'stats-op' } },
      { path: 'stats/op-event', name: 'StatsOpEvent', component: () => import('../views/StatsView.vue'), meta: { title: '运维事件', topNav: 'statistics', sideNav: 'stats-op' } },
      { path: 'stats/op-recover', name: 'StatsOpRecover', component: () => import('../views/StatsView.vue'), meta: { title: '恢复统计', topNav: 'statistics', sideNav: 'stats-op' } },
      { path: 'stats/fault-user', name: 'StatsFaultUser', component: () => import('../views/StatsView.vue'), meta: { title: '故障用户', topNav: 'statistics', sideNav: 'stats-fault' } },
      { path: 'stats/fault-type', name: 'StatsFaultType', component: () => import('../views/StatsView.vue'), meta: { title: '故障类型', topNav: 'statistics', sideNav: 'stats-fault' } },
      { path: 'stats/client-state', name: 'StatsClientState', component: () => import('../views/StatsView.vue'), meta: { title: '终端状态', topNav: 'statistics', sideNav: 'stats-client' } },
      { path: 'stats/client-online', name: 'StatsClientOnline', component: () => import('../views/StatsView.vue'), meta: { title: '终端在线', topNav: 'statistics', sideNav: 'stats-client' } },
      { path: 'stats/alarm-count', name: 'StatsAlarmCount', component: () => import('../views/StatsView.vue'), meta: { title: '告警次数', topNav: 'statistics', sideNav: 'stats-alarm' } },
      { path: 'stats/alarm-server', name: 'StatsAlarmServer', component: () => import('../views/StatsView.vue'), meta: { title: '服务器告警', topNav: 'statistics', sideNav: 'stats-alarm' } },
      { path: 'stats/alarm-vm', name: 'StatsAlarmVm', component: () => import('../views/StatsView.vue'), meta: { title: '虚拟机告警', topNav: 'statistics', sideNav: 'stats-alarm' } },

      // ===== 系统管理 =====
      // 权限管理 → System.vue with tab
      { path: 'system/admins', name: 'AdminAccounts', component: () => import('../views/System.vue'), meta: { title: '管理员账号', topNav: 'system', sideNav: 'auth-mgmt', defaultTab: 'admins' } },
      { path: 'system/password-policy', name: 'PasswordPolicy', component: () => import('../views/System.vue'), meta: { title: '密码策略', topNav: 'system', sideNav: 'auth-mgmt', defaultTab: 'password' } },
      { path: 'system/access-policy', name: 'AccessPolicy', component: () => import('../views/System.vue'), meta: { title: '访问策略', topNav: 'system', sideNav: 'auth-mgmt', defaultTab: 'access' } },
      { path: 'system/roles', name: 'RoleManagement', component: () => import('../views/System.vue'), meta: { title: '角色管理', topNav: 'system', sideNav: 'auth-mgmt', defaultTab: 'roles' } },
      // 系统配置
      { path: 'system/global-policy', name: 'GlobalPolicy', component: () => import('../views/System.vue'), meta: { title: '全局策略', topNav: 'system', sideNav: 'sys-config', defaultTab: 'policies' } },
      { path: 'system/video-redirect', name: 'VideoRedirect', component: () => import('../views/SystemConfigPage.vue'), meta: { title: '视频重定向', topNav: 'system', sideNav: 'sys-config' } },
      { path: 'system/traffic-server', name: 'TrafficServer', component: () => import('../views/SystemConfigPage.vue'), meta: { title: '流量服务器', topNav: 'system', sideNav: 'sys-config' } },
      { path: 'system/mail-server', name: 'MailServer', component: () => import('../views/System.vue'), meta: { title: '邮件服务', topNav: 'system', sideNav: 'sys-config', defaultTab: 'smtp' } },
      { path: 'system/welcome-msg', name: 'WelcomeMessage', component: () => import('../views/SystemConfigPage.vue'), meta: { title: '欢迎信息', topNav: 'system', sideNav: 'sys-config' } },
      { path: 'system/labels', name: 'LabelSettings', component: () => import('../views/SystemConfigPage.vue'), meta: { title: '标签设置', topNav: 'system', sideNav: 'sys-config' } },
      { path: 'system/affinity', name: 'AffinityGroup', component: () => import('../views/SystemConfigPage.vue'), meta: { title: '亲和组', topNav: 'system', sideNav: 'sys-config' } },
      { path: 'system/dynamic-policy', name: 'DynamicPolicy', component: () => import('../views/SystemConfigPage.vue'), meta: { title: '动态策略', topNav: 'system', sideNav: 'sys-config' } },
      { path: 'system/organization', name: 'Organization', component: () => import('../views/SystemConfigPage.vue'), meta: { title: '资源调度', topNav: 'system', sideNav: 'sys-config' } },
      { path: 'system/license', name: 'License', component: () => import('../views/License.vue'), meta: { title: '授权许可', topNav: 'system', sideNav: 'sys-config' } },
      { path: 'system/ha', name: 'HA', component: () => import('../views/SystemConfigPage.vue'), meta: { title: '高可用', topNav: 'system', sideNav: 'sys-config' } },
      { path: 'system/zombie', name: 'ZombieServer', component: () => import('../views/ZombieServers.vue'), meta: { title: '僵尸云服务器', topNav: 'system', sideNav: 'sys-config' } },
      { path: 'system/boot-order', name: 'BootOrder', component: () => import('../views/SystemConfigPage.vue'), meta: { title: '云服务启动顺序', topNav: 'system', sideNav: 'sys-config' } },
      // 虚拟机备份
      { path: 'system/vm-backups', name: 'VMBackups', component: () => import('../views/BackupManagement.vue'), meta: { title: '创建备份', topNav: 'system', sideNav: 'vm-backup', defaultTab: 'list' } },
      { path: 'system/backup-server', name: 'BackupServer', component: () => import('../views/BackupManagement.vue'), meta: { title: '备份服务器', topNav: 'system', sideNav: 'vm-backup', defaultTab: 'servers' } },
      { path: 'system/backup-settings', name: 'BackupSettings', component: () => import('../views/System.vue'), meta: { title: '高级设置', topNav: 'system', sideNav: 'vm-backup', defaultTab: 'backup' } },
      // 快照中心
      { path: 'system/snap-strategy', name: 'SnapStrategy', component: () => import('../views/SnapshotPolicies.vue'), meta: { title: '快照策略', topNav: 'system', sideNav: 'snapshot' } },
      { path: 'system/snap-settings', name: 'SnapSettings', component: () => import('../views/SystemConfigPage.vue'), meta: { title: '快照设置', topNav: 'system', sideNav: 'snapshot' } },
      // 弹性伸缩与负载均衡
      { path: 'system/auto-scaling-strategy', name: 'AutoScalingStrategy', component: () => import('../views/ScalingConfig.vue'), meta: { title: '自动伸缩策略', topNav: 'system', sideNav: 'scaling' } },
      { path: 'system/auto-scaling-group', name: 'AutoScalingGroup', component: () => import('../views/ScalingConfig.vue'), meta: { title: '自动伸缩组', topNav: 'system', sideNav: 'scaling' } },
      { path: 'system/load-balance', name: 'LoadBalance', component: () => import('../views/ScalingConfig.vue'), meta: { title: '负载均衡', topNav: 'system', sideNav: 'scaling' } },
      // 集群管理
      { path: 'system/drs', name: 'DRS', component: () => import('../views/ScalingConfig.vue'), meta: { title: 'DRS管理', topNav: 'system', sideNav: 'cluster' } },
      { path: 'system/dpm', name: 'DPM', component: () => import('../views/ScalingConfig.vue'), meta: { title: 'DPM管理', topNav: 'system', sideNav: 'cluster' } },
      // 其他系统管理
      { path: 'system/file-manage', name: 'FileManage', component: () => import('../views/FileManage.vue'), meta: { title: '文件管理', topNav: 'system', sideNav: 'file-manage' } },
      { path: 'system/tasks', name: 'TaskCenter', component: () => import('../views/TaskCenter.vue'), meta: { title: '任务中心', topNav: 'system', sideNav: 'task-center' } },
      { path: 'system/approvals', name: 'ApprovalCenter', component: () => import('../views/ApprovalCenter.vue'), meta: { title: '审批中心', topNav: 'system', sideNav: 'approval-center' } },
      { path: 'system/maintenance', name: 'Maintenance', component: () => import('../views/Maintenance.vue'), meta: { title: '维护实用程序', topNav: 'system', sideNav: 'maintenance' } },
      { path: 'system/recycle-bin', name: 'RecycleBin', component: () => import('../views/RecycleBin.vue'), meta: { title: '回收站', topNav: 'system', sideNav: 'recycle-bin' } },
      { path: 'system/one-click-detection', name: 'OneClickDetection', component: () => import('../views/OneClickDetection.vue'), meta: { title: '一键检测', topNav: 'system', sideNav: 'one-click' } },

      // ===== 终端管理 =====
      { path: 'clients', name: 'Clients', component: () => import('../views/Clients.vue'), meta: { title: '终端列表', topNav: 'clients', sideNav: 'client-list' } },
      { path: 'clients/tasks', name: 'ClientTasks', component: () => import('../views/Clients.vue'), meta: { title: '终端任务', topNav: 'clients', sideNav: 'client-tasks', defaultTab: 'tasks' } },
      { path: 'clients/:id', name: 'ClientDetail', component: () => import('../views/Clients.vue'), meta: { title: '终端详情', topNav: 'clients' } },

      // ===== 兼容旧路由 =====
      { path: 'templates', redirect: '/gold-images' },
      { path: 'specs', redirect: '/session-settings' },
      { path: 'publish-rules', redirect: '/desktop-assignment' },
      { path: 'desktop-users', redirect: '/users' },
      { path: 'events', redirect: '/log/server-events' },
      { path: 'alerts', redirect: '/alarm/events' },
      { path: 'reports', redirect: '/stats/user-login' },
      { path: 'tasks', redirect: '/system/tasks' },
      { path: 'approvals', redirect: '/system/approvals' },
      { path: 'system', redirect: '/system/global-policy' },
    ]
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

router.beforeEach((to, from, next) => {
  if (to.meta.public) return next()
  const auth = useAuthStore()
  if (!auth.isLoggedIn) return next('/login')
  next()
})

export default router
