<template>
  <div class="mc-layout">
    <!-- 顶部导航栏 -->
    <div class="mc-navbar">
      <div class="navbar-container">
        <!-- Logo -->
        <div class="navbar-brand" @click="$router.push('/dashboard')">
          <span class="brand-text">KVM Cloud</span>
        </div>
        <!-- 主导航菜单 (横排顶部Tab) -->
        <nav class="navbar-menu">
          <a v-for="item in topNavItems" :key="item.id"
             class="nav-item" :class="{ active: currentTopNav === item.id }"
             @click="navigateTop(item)">
            {{ item.label }}
          </a>
        </nav>
        <!-- 右侧: 帮助/告警/用户 -->
        <div class="navbar-right">
          <div class="navbar-icon" @click="$router.push('/system/tasks')" title="任务中心">
            <i class="fa fa-tasks"></i>
            <span class="badge badge-warning" v-if="taskCount">{{ taskCount }}</span>
          </div>
          <div class="navbar-icon" @click="$router.push('/alarm/events')" title="告警">
            <i class="fa fa-bell"></i>
            <span class="badge badge-danger" v-if="alertCount">{{ alertCount }}</span>
          </div>
          <div class="navbar-icon" @click="openHelp" title="帮助">
            <i class="fa fa-question-circle"></i>
          </div>
          <div class="navbar-user" @click.stop="showUserMenu = !showUserMenu">
            <i class="fa fa-user-circle"></i>
            <span class="username">{{ auth.user?.display_name || auth.user?.username || 'admin' }}</span>
            <i class="fa fa-caret-down"></i>
            <div class="user-dropdown" v-show="showUserMenu">
              <div class="dropdown-item" @click="handleCmd('password')"><i class="fa fa-key"></i> 修改密码</div>
              <div class="dropdown-item" @click="handleCmd('about')"><i class="fa fa-info-circle"></i> 关于</div>
              <div class="dropdown-divider"></div>
              <div class="dropdown-item" @click="handleCmd('logout')"><i class="fa fa-sign-out"></i> 注销</div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- 主体区域 = 左侧边栏 + 内容 -->
    <div class="mc-body">
      <!-- 左侧导航 (根据顶部选中项动态变化) -->
      <div class="mc-sidebar" v-if="sidebarMenu.length > 0" :class="{ collapsed: sidebarCollapsed }">
        <div class="sidebar-toggle" @click="sidebarCollapsed = !sidebarCollapsed">
          <i :class="sidebarCollapsed ? 'fa fa-angle-right' : 'fa fa-angle-left'"></i>
        </div>
        <ul class="sidebar-nav" v-show="!sidebarCollapsed">
          <template v-for="group in sidebarMenu" :key="group.id">
            <!-- 单独项目 -->
            <li v-if="!group.children" class="nav-leaf"
                :class="{ active: isRouteActive(group.path) }">
              <router-link :to="group.path">
                <i :class="group.icon || 'fa fa-circle-o'"></i>
                <span>{{ group.label }}</span>
              </router-link>
            </li>
            <!-- 带子菜单的组 -->
            <li v-else class="nav-group" :class="{ open: isGroupOpen(group.id) }">
              <a class="group-header" @click="toggleGroup(group.id)">
                <i :class="group.icon || 'fa fa-folder'"></i>
                <span>{{ group.label }}</span>
                <i class="fa fa-angle-down arrow"></i>
              </a>
              <ul class="sub-nav" v-show="isGroupOpen(group.id)">
                <li v-for="child in group.children" :key="child.path"
                    :class="{ active: isRouteActive(child.path) }">
                  <router-link :to="child.path">{{ child.label }}</router-link>
                </li>
              </ul>
            </li>
          </template>
        </ul>
      </div>

      <!-- 主内容区 -->
      <div class="mc-main" :class="{ 'dark-bg': isDashboard, 'no-sidebar': sidebarMenu.length === 0 }">
        <router-view />
      </div>
    </div>

    <!-- 底部任务台 -->
    <div class="task-platform" :class="{ show: showTaskPanel }">
      <div class="task-header">
        <span class="task-title">任务台</span>
        <span class="task-link" @click="$router.push('/system/tasks')">查看全部任务</span>
        <span class="task-refresh" @click="loadRecentTasks">⟳</span>
        <span class="task-close" @click="showTaskPanel = false">✕</span>
      </div>
      <div class="task-body">
        <table class="task-table" v-if="recentTasks.length">
          <thead><tr><th>状态</th><th>类型</th><th>操作</th><th>对象</th><th>用户</th><th>进度</th><th>时间</th></tr></thead>
          <tbody>
            <tr v-for="t in recentTasks" :key="t.id">
              <td><span :class="'st-' + t.status">{{ t.status === 'completed' ? '✓' : t.status === 'failed' ? '✗' : '◎' }}</span></td>
              <td>{{ t.resource_type || '-' }}</td>
              <td>{{ t.action || '-' }}</td>
              <td>{{ t.resource_name || '-' }}</td>
              <td>{{ t.user || '-' }}</td>
              <td>{{ t.progress ?? 100 }}%</td>
              <td>{{ t.created_at }}</td>
            </tr>
          </tbody>
        </table>
        <div v-else class="task-empty">暂无任务</div>
      </div>
    </div>
    <div class="task-trigger" @click="showTaskPanel = !showTaskPanel" v-show="!showTaskPanel">
      <span>▲ 任务台</span>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useAuthStore } from '../store/auth'
import { ElMessageBox, ElMessage } from 'element-plus'
import api from '../api'

const router = useRouter()
const route = useRoute()
const auth = useAuthStore()
const alertCount = ref(0)
const taskCount = ref(0)
const showUserMenu = ref(false)
const showTaskPanel = ref(false)
const recentTasks = ref([])
const sidebarCollapsed = ref(false)
const openGroups = ref(new Set())

const isDashboard = computed(() => route.path === '/dashboard')
const currentTopNav = computed(() => route.meta?.topNav || 'dashboard')

// ===== 顶部导航定义 =====
const topNavItems = [
  { id: 'dashboard', label: '仪表板', path: '/dashboard' },
  { id: 'desktop-publish', label: '桌面发布', path: '/gold-images' },
  { id: 'desktop-vm', label: '桌面虚拟机', path: '/vms' },
  { id: 'server-virt', label: '服务器虚拟化', path: '/server-virt' },
  { id: 'network', label: '网络池', path: '/networks' },
  { id: 'storage', label: '存储池', path: '/storage' },
  { id: 'hosts', label: '一体机', path: '/hosts' },
  { id: 'log-alarm', label: '日志告警', path: '/log/server-events' },
  { id: 'statistics', label: '统计报表', path: '/stats/user-login' },
  { id: 'system', label: '系统管理', path: '/system/global-policy' },
  { id: 'clients', label: '终端管理', path: '/clients' },
]

// ===== 侧边栏菜单定义 (根据topNav动态切换) =====
const sidebarMenuMap = {
  'dashboard': [], // 仪表板无侧边栏
  'desktop-publish': [
    { id: 'gold-images', label: '黄金镜像', path: '/gold-images', icon: 'fa fa-diamond' },
    { id: 'desktop-publish', label: '桌面发布', icon: 'fa fa-desktop', children: [
      { label: '发布规则', path: '/desktop-assignment' },
      { label: '会话设置', path: '/session-settings' },
      { label: '桌面池', path: '/desktop-pools' },
      { label: '应用程序层', path: '/app-layers' },
      { label: '软件库', path: '/software-library' },
      { label: '软件发布', path: '/software-publish' },
    ]},
    { id: 'app-control', label: '应用管控', icon: 'fa fa-shield', children: [
      { label: '内置规则', path: '/app-control/builtin' },
      { label: '自定义应用', path: '/app-control/custom' },
    ]},
    { id: 'app-publish', label: '应用发布', icon: 'fa fa-rocket', children: [
      { label: '应用组', path: '/virtual-app/groups' },
      { label: '应用会话', path: '/virtual-app/sessions' },
    ]},
    { id: 'user-mgmt', label: '用户管理', icon: 'fa fa-users', children: [
      { label: '用户管理', path: '/users' },
      { label: '用户组', path: '/user-groups' },
      { label: 'LDAP服务器', path: '/ldap-servers' },
      { label: '终端与用户', path: '/terminal-user' },
    ]},
  ],
  'desktop-vm': [], // 虚拟机列表页，左侧显示最近访问的VM
  'server-virt': [], // 服务器虚拟化，左侧会显示分组
  'network': [
    { id: 'network-pool', label: '网络池', path: '/networks', icon: 'fa fa-sitemap' },
    { id: 'vswitch', label: '虚拟交换机', icon: 'fa fa-exchange', children: [
      // 虚拟交换机列表动态加载
    ]},
  ],
  'storage': [
    { id: 'storage-pool', label: '存储池', path: '/storage', icon: 'fa fa-database' },
    { id: 'data-store', label: '数据存储', icon: 'fa fa-hdd-o', children: [
      // 数据存储列表动态加载
    ]},
  ],
  'hosts': [], // 一体机列表页，左侧显示集群服务器
  'log-alarm': [
    { id: 'log', label: '日志', icon: 'fa fa-file-text-o', children: [
      { label: '服务器事件', path: '/log/server-events' },
      { label: '会话事件', path: '/log/session-events' },
      { label: '服务器虚拟化事件', path: '/log/server-virt-events' },
      { label: '审计事件', path: '/log/audit-events' },
      { label: '终端审计事件', path: '/log/client-audit' },
    ]},
    { id: 'alarm', label: '告警', icon: 'fa fa-exclamation-triangle', children: [
      { label: '告警事件', path: '/alarm/events' },
      { label: '告警设置', path: '/alarm/settings' },
    ]},
  ],
  'statistics': [
    { id: 'stats-user', label: '用户统计', icon: 'fa fa-user', children: [
      { label: '登录统计', path: '/stats/user-login' },
      { label: '在线人数', path: '/stats/user-online' },
      { label: '使用时长', path: '/stats/user-time' },
      { label: 'USB统计', path: '/stats/user-usb' },
      { label: '数据拷贝审计', path: '/stats/data-copy' },
    ]},
    { id: 'stats-vm', label: '虚拟机统计', icon: 'fa fa-television', children: [
      { label: '虚拟机状态', path: '/stats/vm-status' },
      { label: '闲置虚拟机', path: '/stats/vm-unused' },
    ]},
    { id: 'stats-sv', label: '服务器虚拟化', icon: 'fa fa-server', children: [
      { label: '资源统计', path: '/stats/sv-resource' },
      { label: 'Top统计', path: '/stats/sv-top' },
    ]},
    { id: 'stats-op', label: '运维统计', icon: 'fa fa-wrench', children: [
      { label: '运维用户', path: '/stats/op-user' },
      { label: '运维事件', path: '/stats/op-event' },
      { label: '恢复统计', path: '/stats/op-recover' },
    ]},
    { id: 'stats-fault', label: '故障统计', icon: 'fa fa-bug', children: [
      { label: '故障用户', path: '/stats/fault-user' },
      { label: '故障类型', path: '/stats/fault-type' },
    ]},
    { id: 'stats-client', label: '终端统计', icon: 'fa fa-laptop', children: [
      { label: '终端状态', path: '/stats/client-state' },
      { label: '终端在线', path: '/stats/client-online' },
    ]},
    { id: 'stats-alarm', label: '告警统计', icon: 'fa fa-bell', children: [
      { label: '告警次数', path: '/stats/alarm-count' },
      { label: '服务器告警', path: '/stats/alarm-server' },
      { label: '虚拟机告警', path: '/stats/alarm-vm' },
    ]},
  ],
  'system': [
    { id: 'auth-mgmt', label: '权限管理', icon: 'fa fa-lock', children: [
      { label: '管理员账号', path: '/system/admins' },
      { label: '密码策略', path: '/system/password-policy' },
      { label: '访问策略', path: '/system/access-policy' },
      { label: '角色管理', path: '/system/roles' },
    ]},
    { id: 'sys-config', label: '系统配置', icon: 'fa fa-cog', children: [
      { label: '全局策略', path: '/system/global-policy' },
      { label: '视频重定向', path: '/system/video-redirect' },
      { label: '流量服务器', path: '/system/traffic-server' },
      { label: '邮件服务', path: '/system/mail-server' },
      { label: '欢迎信息', path: '/system/welcome-msg' },
      { label: '标签设置', path: '/system/labels' },
      { label: '亲和组', path: '/system/affinity' },
      { label: '动态策略', path: '/system/dynamic-policy' },
      { label: '资源调度', path: '/system/organization' },
      { label: '授权许可', path: '/system/license' },
      { label: '高可用', path: '/system/ha' },
      { label: '僵尸云服务器', path: '/system/zombie' },
      { label: '云服务启动顺序', path: '/system/boot-order' },
    ]},
    { id: 'vm-backup', label: '虚拟机备份', icon: 'fa fa-cloud-upload', children: [
      { label: '创建备份', path: '/system/vm-backups' },
      { label: '备份服务器', path: '/system/backup-server' },
      { label: '高级设置', path: '/system/backup-settings' },
    ]},
    { id: 'snapshot', label: '快照中心', icon: 'fa fa-camera', children: [
      { label: '快照策略', path: '/system/snap-strategy' },
      { label: '快照设置', path: '/system/snap-settings' },
    ]},
    { id: 'scaling', label: '弹性伸缩与负载均衡', icon: 'fa fa-balance-scale', children: [
      { label: '自动伸缩策略', path: '/system/auto-scaling-strategy' },
      { label: '自动伸缩组', path: '/system/auto-scaling-group' },
      { label: '负载均衡', path: '/system/load-balance' },
    ]},
    { id: 'cluster', label: '集群管理', icon: 'fa fa-cubes', children: [
      { label: 'DRS管理', path: '/system/drs' },
      { label: 'DPM管理', path: '/system/dpm' },
    ]},
    { id: 'file-manage', label: '文件管理', path: '/system/file-manage', icon: 'fa fa-folder-open' },
    { id: 'task-center', label: '任务中心', path: '/system/tasks', icon: 'fa fa-tasks' },
    { id: 'approval-center', label: '审批中心', path: '/system/approvals', icon: 'fa fa-check-square-o' },
    { id: 'maintenance', label: '维护实用程序', path: '/system/maintenance', icon: 'fa fa-medkit' },
    { id: 'recycle-bin', label: '回收站', path: '/system/recycle-bin', icon: 'fa fa-trash' },
    { id: 'one-click', label: '一键检测', path: '/system/one-click-detection', icon: 'fa fa-search' },
  ],
  'clients': [
    { id: 'client-list', label: '终端列表', path: '/clients', icon: 'fa fa-laptop' },
    { id: 'client-tasks', label: '终端任务', path: '/clients/tasks', icon: 'fa fa-list' },
  ],
}

const sidebarMenu = computed(() => sidebarMenuMap[currentTopNav.value] || [])

function navigateTop(item) {
  router.push(item.path)
}

function isRouteActive(path) {
  return route.path === path
}

function isGroupOpen(groupId) {
  return openGroups.value.has(groupId)
}

function toggleGroup(groupId) {
  const s = new Set(openGroups.value)
  if (s.has(groupId)) s.delete(groupId)
  else s.add(groupId)
  openGroups.value = s
}

// Auto-open sidebar groups matching current route
watch(() => route.path, () => {
  const menu = sidebarMenu.value
  for (const group of menu) {
    if (group.children) {
      for (const child of group.children) {
        if (route.path === child.path) {
          openGroups.value = new Set([...openGroups.value, group.id])
          return
        }
      }
    }
  }
}, { immediate: true })

function openHelp() {
  ElMessageBox.alert('KVM Cloud 管理控制台\n如需帮助请联系系统管理员', '帮助', { confirmButtonText: '确定' })
}

async function loadAlertCount() {
  try {
    const res = await api.get('/alerts', { params: { status: 'active' } })
    alertCount.value = res.data?.length || 0
  } catch(e) {}
}
async function loadBadgeCounts() {
  try { taskCount.value = ((await api.get('/events/tasks', { params: { status: 'pending' } })).data || []).length } catch(e) {}
}
async function loadRecentTasks() {
  try {
    const res = await api.get('/events/tasks')
    recentTasks.value = (res.data || []).slice(0, 10)
  } catch(e) {}
}

function handleCmd(cmd) {
  showUserMenu.value = false
  if (cmd === 'logout') {
    auth.logout()
    router.push('/login')
  } else if (cmd === 'password') {
    ElMessageBox.prompt('请输入旧密码', '修改密码 - 第1步', { inputType: 'password', confirmButtonText: '下一步', cancelButtonText: '取消' })
      .then(({ value: oldPwd }) => {
        if (!oldPwd) return ElMessage.warning('请输入旧密码')
        ElMessageBox.prompt('请输入新密码（至少6位）', '修改密码 - 第2步', { inputType: 'password', confirmButtonText: '确定', cancelButtonText: '取消' })
          .then(({ value: newPwd }) => {
            if (!newPwd || newPwd.length < 6) return ElMessage.warning('密码至少6位')
            api.put('/auth/password', { old_password: oldPwd, new_password: newPwd })
              .then(() => ElMessage.success('密码修改成功'))
              .catch(() => {})
          }).catch(() => {})
      }).catch(() => {})
  } else if (cmd === 'about') {
    ElMessageBox.alert('KVM Cloud 虚拟化管理平台 v1.0.0\n基于 KVM 的桌面云与服务器虚拟化解决方案', '关于', { confirmButtonText: '确定' })
  }
}

document.addEventListener('click', () => { showUserMenu.value = false })

onMounted(() => {
  loadAlertCount()
  loadBadgeCounts()
  loadRecentTasks()
})
</script>

<style scoped>
/* ========== 管理控制台布局 ========== */
.mc-layout {
  height: 100vh;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

/* ===== 顶部导航栏 ===== */
.mc-navbar {
  height: 56px;
  background: linear-gradient(90deg, #0a1628 0%, #132040 50%, #0a1628 100%);
  border-bottom: 1px solid rgba(66, 151, 251, 0.3);
  flex-shrink: 0;
  z-index: 100;
}
.navbar-container {
  height: 100%;
  display: flex;
  align-items: center;
  padding: 0 16px;
}
.navbar-brand {
  display: flex;
  align-items: center;
  cursor: pointer;
  margin-right: 24px;
  flex-shrink: 0;
}
.brand-text {
  color: #fff;
  font-size: 18px;
  font-weight: 700;
  letter-spacing: 1px;
  text-shadow: 0 0 10px rgba(66, 151, 251, 0.5);
}
.navbar-menu {
  display: flex;
  align-items: center;
  flex: 1;
  height: 100%;
  overflow-x: auto;
  gap: 2px;
}
.nav-item {
  color: #b8c7db;
  text-decoration: none;
  padding: 0 14px;
  height: 100%;
  display: flex;
  align-items: center;
  font-size: 14px;
  white-space: nowrap;
  transition: all 0.2s;
  border-bottom: 2px solid transparent;
  cursor: pointer;
}
.nav-item:hover, .nav-item.active {
  color: #fff;
  background: rgba(66, 151, 251, 0.15);
  border-bottom-color: #4297fb;
}
.nav-item.active { font-weight: 600; }

/* 右侧 */
.navbar-right {
  display: flex;
  align-items: center;
  gap: 12px;
  margin-left: auto;
  flex-shrink: 0;
}
.navbar-icon {
  position: relative;
  cursor: pointer;
  width: 32px; height: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 4px;
  color: #b8c7db;
  font-size: 16px;
  transition: all 0.2s;
}
.navbar-icon:hover { background: rgba(255,255,255,0.1); color: #fff; }
.badge {
  position: absolute;
  top: -4px; right: -6px;
  min-width: 16px; height: 16px;
  border-radius: 8px;
  font-size: 10px;
  line-height: 16px;
  text-align: center;
  padding: 0 4px;
  color: #fff;
}
.badge-warning { background: #e6a23c; }
.badge-danger { background: #f56c6c; }
.navbar-user {
  display: flex;
  align-items: center;
  cursor: pointer;
  padding: 4px 8px;
  border-radius: 4px;
  position: relative;
  color: #b8c7db;
  gap: 6px;
  transition: background 0.2s;
}
.navbar-user:hover { background: rgba(255,255,255,0.1); }
.username { color: #fff; font-size: 13px; }
.user-dropdown {
  position: absolute;
  top: calc(100% + 4px); right: 0;
  min-width: 140px;
  background: #1a2744;
  border: 1px solid rgba(66, 151, 251, 0.3);
  border-radius: 4px;
  box-shadow: 0 4px 12px rgba(0,0,0,0.4);
  z-index: 200;
  padding: 4px 0;
}
.user-dropdown .dropdown-item {
  color: #b8c7db;
  padding: 8px 16px;
  font-size: 13px;
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 8px;
  transition: all 0.15s;
}
.user-dropdown .dropdown-item:hover { color: #fff; background: rgba(66, 151, 251, 0.2); }
.dropdown-divider { height: 1px; background: rgba(66, 151, 251, 0.15); margin: 4px 0; }

/* ===== 主体区域 ===== */
.mc-body {
  flex: 1;
  display: flex;
  overflow: hidden;
}

/* ===== 左侧导航 ===== */
.mc-sidebar {
  width: 220px;
  background: #090f26;
  border-right: 1px solid rgba(66, 151, 251, 0.15);
  flex-shrink: 0;
  display: flex;
  flex-direction: column;
  overflow-y: auto;
  transition: width 0.25s;
  position: relative;
}
.mc-sidebar.collapsed { width: 40px; }
.sidebar-toggle {
  position: absolute;
  top: 8px; right: 4px;
  width: 24px; height: 24px;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  color: #5a7089;
  border-radius: 3px;
  z-index: 1;
}
.sidebar-toggle:hover { color: #fff; background: rgba(66, 151, 251, 0.2); }

.sidebar-nav {
  list-style: none;
  padding: 8px 0;
  margin: 0;
}
/* 单独项目 */
.nav-leaf a {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 10px 16px;
  color: #b8c7db;
  text-decoration: none;
  font-size: 13px;
  transition: all 0.15s;
  border-left: 3px solid transparent;
}
.nav-leaf a:hover { color: #fff; background: rgba(66, 151, 251, 0.1); }
.nav-leaf.active a { color: #4297fb; background: rgba(66, 151, 251, 0.12); border-left-color: #4297fb; }
.nav-leaf a i { width: 16px; text-align: center; font-size: 14px; }

/* 分组 */
.nav-group .group-header {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 10px 16px;
  color: #b8c7db;
  font-size: 13px;
  cursor: pointer;
  transition: all 0.15s;
  border-left: 3px solid transparent;
}
.nav-group .group-header:hover { color: #fff; background: rgba(66, 151, 251, 0.08); }
.nav-group .group-header i.arrow { margin-left: auto; transition: transform 0.2s; }
.nav-group.open .group-header i.arrow { transform: rotate(180deg); }
.nav-group .group-header > i:first-child { width: 16px; text-align: center; font-size: 14px; }

.sub-nav {
  list-style: none;
  padding: 0;
  margin: 0;
}
.sub-nav li a {
  display: block;
  padding: 8px 16px 8px 42px;
  color: #8ba7c7;
  text-decoration: none;
  font-size: 12px;
  transition: all 0.15s;
  border-left: 3px solid transparent;
}
.sub-nav li a:hover { color: #fff; background: rgba(66, 151, 251, 0.08); }
.sub-nav li.active a { color: #4297fb; background: rgba(66, 151, 251, 0.12); border-left-color: #4297fb; }

/* ===== 主内容区 ===== */
.mc-main {
  flex: 1;
  overflow-y: auto;
  background: #f0f2f5;
  padding: 16px;
}
.mc-main.dark-bg { background: #0c1530; padding: 12px; }
.mc-main.no-sidebar { /* 无侧边栏时全宽 */ }

/* ===== 底部任务台 ===== */
.task-platform {
  position: fixed;
  bottom: 0; left: 0; right: 0;
  height: 280px;
  background: rgba(8, 14, 35, 0.98);
  border-top: 1px solid rgba(66, 151, 251, 0.4);
  transform: translateY(100%);
  transition: transform 0.3s ease;
  z-index: 101;
}
.task-platform.show { transform: translateY(0); }
.task-header {
  height: 40px;
  display: flex;
  align-items: center;
  background: rgba(63, 81, 147, 1);
  padding: 0 20px;
  gap: 16px;
}
.task-title { color: #fff; font-size: 14px; }
.task-link { color: #fff; font-size: 13px; cursor: pointer; }
.task-link:hover { text-decoration: underline; }
.task-refresh, .task-close { color: #fff; font-size: 16px; cursor: pointer; margin-left: auto; }
.task-close { margin-left: 12px; }
.task-body { height: calc(100% - 40px); overflow-y: auto; padding: 8px 16px; }
.task-table { width: 100%; border-collapse: collapse; color: #b8c7db; font-size: 12px; }
.task-table th { background: rgba(66, 151, 251, 0.15); padding: 6px 10px; text-align: left; color: #8ba7c7; font-weight: 500; border-bottom: 1px solid rgba(66, 151, 251, 0.2); }
.task-table td { padding: 6px 10px; border-bottom: 1px solid rgba(255,255,255,0.05); }
.st-completed { color: #67c23a; }
.st-failed { color: #f56c6c; }
.st-pending { color: #409eff; }
.task-empty { color: #5a7089; text-align: center; padding: 40px; }
.task-trigger {
  position: fixed;
  bottom: 0; left: 50%;
  transform: translateX(-50%);
  background: rgba(63, 81, 147, 0.95);
  color: #fff;
  padding: 4px 20px;
  border-radius: 6px 6px 0 0;
  font-size: 12px;
  cursor: pointer;
  z-index: 100;
}
.task-trigger:hover { background: rgba(63, 81, 147, 1); }

/* Placeholder view styling */
:deep(.placeholder-view) {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  min-height: 400px;
  color: #666;
}
:deep(.placeholder-view .placeholder-icon) {
  font-size: 48px;
  margin-bottom: 16px;
}
:deep(.placeholder-view h3) {
  margin: 0 0 8px;
  color: #333;
}
:deep(.placeholder-view p) {
  color: #999;
}
</style>
