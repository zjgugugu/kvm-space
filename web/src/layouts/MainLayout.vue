<template>
  <div class="ksvd-layout">
    <!-- 顶部导航栏 (对标KSVD) -->
    <div class="ksvd-navbar">
      <div class="navbar-container">
        <!-- Logo -->
        <div class="navbar-brand" @click="$router.push('/dashboard')">
          <img src="" alt="" style="display:none;" />
          <span class="brand-text">KVM Cloud</span>
        </div>
        <!-- 主导航菜单 (横排) -->
        <nav class="navbar-menu">
          <router-link to="/dashboard" class="nav-item" :class="{ active: isActive('/dashboard') }">仪表板</router-link>
          <div class="nav-item nav-dropdown" :class="{ active: isActive('/templates', '/specs', '/publish-rules', '/desktop-users') }">
            <span>桌面发布</span>
            <div class="dropdown-menu">
              <router-link to="/templates" class="dropdown-item">黄金镜像</router-link>
              <router-link to="/specs" class="dropdown-item">桌面规格</router-link>
              <router-link to="/publish-rules" class="dropdown-item">发布规则</router-link>
              <router-link to="/desktop-users" class="dropdown-item">用户管理</router-link>
            </div>
          </div>
          <router-link to="/vms" class="nav-item" :class="{ active: isActive('/vms') }">桌面虚拟机</router-link>
          <router-link to="/hosts" class="nav-item" :class="{ active: isActive('/hosts') }">一体机</router-link>
          <router-link to="/networks" class="nav-item" :class="{ active: isActive('/networks') }">网络池</router-link>
          <router-link to="/storage" class="nav-item" :class="{ active: isActive('/storage') }">存储池</router-link>
          <div class="nav-item nav-dropdown" :class="{ active: isActive('/events', '/alerts') }">
            <span>日志告警</span>
            <div class="dropdown-menu">
              <router-link to="/events" class="dropdown-item">日志</router-link>
              <router-link to="/alerts" class="dropdown-item">告警事件</router-link>
            </div>
          </div>
          <router-link to="/reports" class="nav-item" :class="{ active: isActive('/reports') }">统计报表</router-link>
          <router-link to="/system" class="nav-item" :class="{ active: isActive('/system') }">系统管理</router-link>
        </nav>
        <!-- 右侧: 任务/审批/告警/用户 -->
        <div class="navbar-right">
          <div class="navbar-icon" @click="$router.push('/tasks')" title="任务中心">
            <i class="icon-task"></i>
            <span class="badge badge-warning" v-if="taskCount">{{ taskCount }}</span>
          </div>
          <div class="navbar-icon" @click="$router.push('/approvals')" title="审批中心">
            <i class="icon-approval"></i>
            <span class="badge badge-info" v-if="approvalCount">{{ approvalCount }}</span>
          </div>
          <div class="navbar-icon" @click="$router.push('/alerts')" title="告警事件">
            <i class="icon-alarm"></i>
            <span class="badge badge-danger" v-if="alertCount">{{ alertCount }}</span>
          </div>
          <div class="navbar-user" @click="showUserMenu = !showUserMenu">
            <span class="username">{{ auth.user?.display_name || auth.user?.username || 'admin' }}</span>
            <i class="arrow-down"></i>
            <div class="user-dropdown" v-show="showUserMenu" @click.stop>
              <div class="dropdown-item" @click="handleCmd('password')">重置密码</div>
              <div class="dropdown-item" @click="handleCmd('logout')">注销</div>
              <div class="dropdown-item" @click="handleCmd('about')">关于</div>
            </div>
          </div>
        </div>
      </div>
    </div>
    <!-- 主内容区 -->
    <div class="ksvd-main" :class="{ 'dark-bg': isDashboard }">
      <router-view />
    </div>
    <!-- 底部任务台 (对标KSVD) -->
    <div class="task-platform" :class="{ show: showTaskPanel }">
      <div class="task-header">
        <span class="task-title">任务台</span>
        <span class="task-link" @click="$router.push('/tasks')">查看全部任务</span>
        <span class="task-refresh" @click="loadRecentTasks">⟳</span>
        <span class="task-close" @click="showTaskPanel = false">✕</span>
      </div>
      <div class="task-body">
        <table class="task-table" v-if="recentTasks.length">
          <thead>
            <tr>
              <th>状态</th><th>类型</th><th>操作</th><th>对象</th><th>用户</th><th>进度</th><th>开始时间</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="t in recentTasks" :key="t.id">
              <td><span :class="'status-' + t.status">{{ t.status === 'completed' ? '✓' : t.status === 'failed' ? '✗' : '◎' }}</span></td>
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
    <!-- 任务台触发按钮 -->
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
const approvalCount = ref(0)
const showUserMenu = ref(false)
const showTaskPanel = ref(false)
const recentTasks = ref([])

const isDashboard = computed(() => route.path === '/dashboard')

function isActive(...paths) {
  return paths.some(p => route.path === p || route.path.startsWith(p + '/'))
}

async function loadAlertCount() {
  try {
    const res = await api.get('/alerts', { params: { status: 'active' } })
    alertCount.value = res.data?.length || 0
  } catch(e) {}
}
async function loadBadgeCounts() {
  try { taskCount.value = ((await api.get('/events/tasks', { params: { status: 'pending' } })).data || []).length } catch(e) {}
  try { approvalCount.value = ((await api.get('/events/approvals', { params: { status: 'pending' } })).data || []).length } catch(e) {}
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
    ElMessageBox.prompt('请输入新密码', '修改密码', { inputType: 'password', confirmButtonText: '确定', cancelButtonText: '取消' })
      .then(({ value }) => {
        if (!value || value.length < 6) return ElMessage.warning('密码至少6位')
        api.put('/auth/password', { old_password: 'admin123', new_password: value })
          .then(() => ElMessage.success('密码修改成功'))
      }).catch(() => {})
  } else if (cmd === 'about') {
    ElMessageBox.alert('KVM Cloud 虚拟化管理平台 v0.3.0\n基于 KVM 的桌面云与服务器虚拟化解决方案\n对标: KSVD V7', '关于', { confirmButtonText: '确定' })
  }
}

// 点击其他地方关闭用户菜单
document.addEventListener('click', () => { showUserMenu.value = false })

onMounted(() => {
  loadAlertCount()
  loadBadgeCounts()
  loadRecentTasks()
})
</script>

<style scoped>
/* ========== KSVD风格顶部导航 ========== */
.ksvd-layout {
  height: 100vh;
  display: flex;
  flex-direction: column;
  overflow: hidden;
}

.ksvd-navbar {
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
  position: relative;
}

.nav-item:hover, .nav-item.active {
  color: #fff;
  background: rgba(66, 151, 251, 0.15);
  border-bottom-color: #4297fb;
}

.nav-item.active {
  font-weight: 600;
}

/* 下拉菜单 */
.nav-dropdown {
  position: relative;
}

.nav-dropdown .dropdown-menu {
  display: none;
  position: absolute;
  top: 100%;
  left: 0;
  min-width: 140px;
  background: #1a2744;
  border: 1px solid rgba(66, 151, 251, 0.3);
  border-radius: 4px;
  box-shadow: 0 4px 12px rgba(0,0,0,0.4);
  z-index: 200;
  padding: 4px 0;
}

.nav-dropdown:hover .dropdown-menu {
  display: block;
}

.dropdown-menu .dropdown-item {
  display: block;
  color: #b8c7db;
  padding: 8px 16px;
  text-decoration: none;
  font-size: 13px;
  transition: all 0.15s;
}

.dropdown-menu .dropdown-item:hover {
  color: #fff;
  background: rgba(66, 151, 251, 0.2);
}

/* 右侧图标区 */
.navbar-right {
  display: flex;
  align-items: center;
  gap: 16px;
  margin-left: auto;
  flex-shrink: 0;
}

.navbar-icon {
  position: relative;
  cursor: pointer;
  width: 32px;
  height: 32px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 4px;
  transition: background 0.2s;
}

.navbar-icon:hover {
  background: rgba(255,255,255,0.1);
}

.icon-task::before { content: '📋'; font-size: 16px; }
.icon-approval::before { content: '✅'; font-size: 16px; }
.icon-alarm::before { content: '🔔'; font-size: 16px; }

.badge {
  position: absolute;
  top: -4px;
  right: -6px;
  min-width: 16px;
  height: 16px;
  border-radius: 8px;
  font-size: 10px;
  line-height: 16px;
  text-align: center;
  padding: 0 4px;
  color: #fff;
}

.badge-warning { background: #e6a23c; }
.badge-info { background: #409eff; }
.badge-danger { background: #f56c6c; }

.navbar-user {
  display: flex;
  align-items: center;
  cursor: pointer;
  padding: 4px 8px;
  border-radius: 4px;
  position: relative;
  transition: background 0.2s;
}

.navbar-user:hover {
  background: rgba(255,255,255,0.1);
}

.username {
  color: #fff;
  font-size: 13px;
  margin-right: 4px;
}

.arrow-down {
  display: inline-block;
  width: 0;
  height: 0;
  border-left: 4px solid transparent;
  border-right: 4px solid transparent;
  border-top: 5px solid #b8c7db;
}

.user-dropdown {
  position: absolute;
  top: 100%;
  right: 0;
  min-width: 120px;
  background: #1a2744;
  border: 1px solid rgba(66, 151, 251, 0.3);
  border-radius: 4px;
  box-shadow: 0 4px 12px rgba(0,0,0,0.4);
  z-index: 200;
  padding: 4px 0;
  margin-top: 4px;
}

.user-dropdown .dropdown-item {
  color: #b8c7db;
  padding: 8px 16px;
  font-size: 13px;
  cursor: pointer;
  transition: all 0.15s;
}

.user-dropdown .dropdown-item:hover {
  color: #fff;
  background: rgba(66, 151, 251, 0.2);
}

/* ========== 主内容区 ========== */
.ksvd-main {
  flex: 1;
  overflow-y: auto;
  background: #f0f2f5;
  padding: 16px;
}

.ksvd-main.dark-bg {
  background: #0c1530;
  padding: 12px;
}

/* ========== 底部任务台 (对标KSVD) ========== */
.task-platform {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  height: 280px;
  background: rgba(8, 14, 35, 0.98);
  border-top: 1px solid rgba(66, 151, 251, 0.4);
  transform: translateY(100%);
  transition: transform 0.3s ease;
  z-index: 101;
}

.task-platform.show {
  transform: translateY(0);
}

.task-header {
  height: 40px;
  display: flex;
  align-items: center;
  background: rgba(63, 81, 147, 1);
  padding: 0 20px;
  gap: 16px;
}

.task-title {
  color: #fff;
  font-size: 14px;
}

.task-link {
  color: #fff;
  font-size: 13px;
  cursor: pointer;
  text-decoration: none;
}

.task-link:hover {
  text-decoration: underline;
}

.task-refresh, .task-close {
  color: #fff;
  font-size: 16px;
  cursor: pointer;
  margin-left: auto;
}

.task-close {
  margin-left: 12px;
}

.task-body {
  height: calc(100% - 40px);
  overflow-y: auto;
  padding: 8px 16px;
}

.task-table {
  width: 100%;
  border-collapse: collapse;
  color: #b8c7db;
  font-size: 12px;
}

.task-table th {
  background: rgba(66, 151, 251, 0.15);
  padding: 6px 10px;
  text-align: left;
  color: #8ba7c7;
  font-weight: 500;
  border-bottom: 1px solid rgba(66, 151, 251, 0.2);
}

.task-table td {
  padding: 6px 10px;
  border-bottom: 1px solid rgba(255,255,255,0.05);
}

.status-completed { color: #67c23a; }
.status-failed { color: #f56c6c; }
.status-pending { color: #409eff; }

.task-empty {
  color: #5a7089;
  text-align: center;
  padding: 40px;
}

.task-trigger {
  position: fixed;
  bottom: 0;
  left: 50%;
  transform: translateX(-50%);
  background: rgba(63, 81, 147, 0.95);
  color: #fff;
  padding: 4px 20px;
  border-radius: 6px 6px 0 0;
  font-size: 12px;
  cursor: pointer;
  z-index: 100;
  transition: background 0.2s;
}

.task-trigger:hover {
  background: rgba(63, 81, 147, 1);
}
</style>
