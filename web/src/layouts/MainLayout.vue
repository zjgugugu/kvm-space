<template>
  <el-container style="height: 100vh">
    <el-aside :width="isCollapse ? '64px' : '220px'" style="transition: width .3s; background: #1d1e2c;">
      <div style="height: 56px; display: flex; align-items: center; justify-content: center; color: #fff; font-size: 16px; font-weight: 700; white-space: nowrap; overflow: hidden;">
        <el-icon :size="24" style="margin-right: 6px;"><Monitor /></el-icon>
        <span v-show="!isCollapse">KVM Cloud</span>
      </div>
      <el-menu :default-active="$route.path" :collapse="isCollapse" background-color="#1d1e2c" text-color="#bbb" active-text-color="#409eff" router unique-opened>
        <el-menu-item index="/dashboard"><el-icon><Odometer /></el-icon><span>仪表板</span></el-menu-item>
        <el-sub-menu index="desktop-publish">
          <template #title><el-icon><PictureFilled /></el-icon><span>桌面发布</span></template>
          <el-menu-item index="/templates">黄金镜像</el-menu-item>
          <el-menu-item index="/specs">桌面规格</el-menu-item>
          <el-menu-item index="/publish-rules">发布规则</el-menu-item>
          <el-menu-item index="/desktop-users">用户管理</el-menu-item>
        </el-sub-menu>
        <el-menu-item index="/vms"><el-icon><Monitor /></el-icon><span>桌面虚拟机</span></el-menu-item>
        <el-sub-menu index="hosts-group">
          <template #title><el-icon><Platform /></el-icon><span>一体机</span></template>
          <el-menu-item index="/hosts">服务器管理</el-menu-item>
        </el-sub-menu>
        <el-menu-item index="/networks"><el-icon><Connection /></el-icon><span>网络池</span></el-menu-item>
        <el-menu-item index="/storage"><el-icon><Coin /></el-icon><span>存储池</span></el-menu-item>
        <el-sub-menu index="logs-alerts">
          <template #title><el-icon><Notebook /></el-icon><span>日志告警</span></template>
          <el-menu-item index="/events">日志</el-menu-item>
          <el-menu-item index="/alerts">告警事件</el-menu-item>
        </el-sub-menu>
        <el-menu-item index="/reports"><el-icon><DataAnalysis /></el-icon><span>统计报表</span></el-menu-item>
        <el-menu-item index="/system"><el-icon><Setting /></el-icon><span>系统管理</span></el-menu-item>
      </el-menu>
    </el-aside>
    <el-container>
      <el-header style="display: flex; align-items: center; justify-content: space-between; border-bottom: 1px solid #e4e7ed; background: #fff;">
        <div style="display: flex; align-items: center; gap: 12px;">
          <el-icon :size="20" style="cursor: pointer;" @click="isCollapse = !isCollapse"><Fold v-if="!isCollapse" /><Expand v-else /></el-icon>
          <el-breadcrumb separator="/">
            <el-breadcrumb-item :to="{ path: '/' }">首页</el-breadcrumb-item>
            <el-breadcrumb-item v-if="$route.meta.parent">{{ $route.meta.parent }}</el-breadcrumb-item>
            <el-breadcrumb-item v-if="$route.meta.title">{{ $route.meta.title }}</el-breadcrumb-item>
          </el-breadcrumb>
        </div>
        <div style="display: flex; align-items: center; gap: 16px;">
          <el-badge :value="alertCount" :hidden="!alertCount" type="danger">
            <el-icon :size="20" style="cursor: pointer;" @click="$router.push('/alerts')"><Bell /></el-icon>
          </el-badge>
          <el-dropdown @command="handleCmd">
            <span style="cursor: pointer; display: flex; align-items: center; gap: 6px;">
              <el-avatar :size="32" style="background: #409eff;">{{ auth.user?.display_name?.[0] || 'U' }}</el-avatar>
              <span>{{ auth.user?.display_name || auth.user?.username }}</span>
              <el-icon><ArrowDown /></el-icon>
            </span>
            <template #dropdown>
              <el-dropdown-menu>
                <el-dropdown-item command="password">修改密码</el-dropdown-item>
                <el-dropdown-item command="about">关于</el-dropdown-item>
                <el-dropdown-item command="logout" divided>退出登录</el-dropdown-item>
              </el-dropdown-menu>
            </template>
          </el-dropdown>
        </div>
      </el-header>
      <el-main style="background: #f0f2f5; overflow-y: auto;">
        <router-view />
      </el-main>
    </el-container>
  </el-container>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '../store/auth'
import { ElMessageBox, ElMessage } from 'element-plus'
import api from '../api'

const router = useRouter()
const auth = useAuthStore()
const isCollapse = ref(false)
const alertCount = ref(0)

async function loadAlertCount() {
  try {
    const res = await api.get('/alerts', { params: { status: 'active' } })
    alertCount.value = res.data?.length || 0
  } catch(e) {}
}

function handleCmd(cmd) {
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
    ElMessageBox.alert('KVM Cloud 虚拟化管理平台 v0.2.0\n基于 KVM 的桌面云与服务器虚拟化解决方案', '关于', { confirmButtonText: '确定' })
  }
}

onMounted(loadAlertCount)
</script>
