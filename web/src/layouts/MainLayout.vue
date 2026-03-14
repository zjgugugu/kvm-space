<template>
  <el-container style="height: 100vh">
    <el-aside :width="isCollapse ? '64px' : '220px'" style="transition: width .3s; background: #1d1e2c;">
      <div style="height: 56px; display: flex; align-items: center; justify-content: center; color: #fff; font-size: 16px; font-weight: 700; white-space: nowrap; overflow: hidden;">
        <el-icon :size="24" style="margin-right: 6px;"><Monitor /></el-icon>
        <span v-show="!isCollapse">KVM Cloud</span>
      </div>
      <el-menu :default-active="$route.path" :collapse="isCollapse" background-color="#1d1e2c" text-color="#bbb" active-text-color="#409eff" router unique-opened>
        <el-menu-item index="/dashboard"><el-icon><Odometer /></el-icon><span>总览</span></el-menu-item>
        <el-sub-menu index="resource">
          <template #title><el-icon><Cpu /></el-icon><span>资源管理</span></template>
          <el-menu-item index="/hosts"><el-icon><Platform /></el-icon>主机管理</el-menu-item>
          <el-menu-item index="/templates"><el-icon><PictureFilled /></el-icon>黄金镜像</el-menu-item>
          <el-menu-item index="/specs"><el-icon><Tickets /></el-icon>桌面规格</el-menu-item>
          <el-menu-item index="/publish-rules"><el-icon><Share /></el-icon>发布规则</el-menu-item>
        </el-sub-menu>
        <el-menu-item index="/vms"><el-icon><Monitor /></el-icon><span>虚拟机管理</span></el-menu-item>
        <el-sub-menu index="infra">
          <template #title><el-icon><Connection /></el-icon><span>基础设施</span></template>
          <el-menu-item index="/networks"><el-icon><Cloudy /></el-icon>网络管理</el-menu-item>
          <el-menu-item index="/storage"><el-icon><Coin /></el-icon>存储管理</el-menu-item>
        </el-sub-menu>
        <el-sub-menu index="admin">
          <template #title><el-icon><Setting /></el-icon><span>系统管理</span></template>
          <el-menu-item index="/users"><el-icon><User /></el-icon>用户管理</el-menu-item>
          <el-menu-item index="/events"><el-icon><Notebook /></el-icon>操作日志</el-menu-item>
          <el-menu-item index="/alerts"><el-icon><Bell /></el-icon>告警管理</el-menu-item>
          <el-menu-item index="/system"><el-icon><Tools /></el-icon>系统设置</el-menu-item>
        </el-sub-menu>
      </el-menu>
    </el-aside>
    <el-container>
      <el-header style="display: flex; align-items: center; justify-content: space-between; border-bottom: 1px solid #e4e7ed; background: #fff;">
        <div style="display: flex; align-items: center; gap: 12px;">
          <el-icon :size="20" style="cursor: pointer;" @click="isCollapse = !isCollapse"><Fold v-if="!isCollapse" /><Expand v-else /></el-icon>
          <el-breadcrumb separator="/">
            <el-breadcrumb-item :to="{ path: '/' }">首页</el-breadcrumb-item>
            <el-breadcrumb-item v-if="$route.meta.title">{{ $route.meta.title }}</el-breadcrumb-item>
          </el-breadcrumb>
        </div>
        <el-dropdown @command="handleCmd">
          <span style="cursor: pointer; display: flex; align-items: center; gap: 6px;">
            <el-avatar :size="32" style="background: #409eff;">{{ auth.user?.display_name?.[0] || 'U' }}</el-avatar>
            <span>{{ auth.user?.display_name || auth.user?.username }}</span>
            <el-icon><ArrowDown /></el-icon>
          </span>
          <template #dropdown>
            <el-dropdown-menu>
              <el-dropdown-item command="password">修改密码</el-dropdown-item>
              <el-dropdown-item command="logout" divided>退出登录</el-dropdown-item>
            </el-dropdown-menu>
          </template>
        </el-dropdown>
      </el-header>
      <el-main style="background: #f0f2f5; overflow-y: auto;">
        <router-view />
      </el-main>
    </el-container>
  </el-container>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '../store/auth'
import { ElMessageBox, ElMessage } from 'element-plus'
import api from '../api'

const router = useRouter()
const auth = useAuthStore()
const isCollapse = ref(false)

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
  }
}
</script>
