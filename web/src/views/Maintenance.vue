<template>
  <div>
    <div class="page-header">
      <h2>维护实用程序</h2>
    </div>
    <el-row :gutter="16">
      <el-col :span="12">
        <el-card shadow="hover">
          <template #header><span style="font-weight:bold;">系统检测</span></template>
          <el-descriptions :column="1" border size="small">
            <el-descriptions-item label="CPU使用率"><el-progress :percentage="sysInfo.cpu" :stroke-width="14" /></el-descriptions-item>
            <el-descriptions-item label="内存使用率"><el-progress :percentage="sysInfo.memory" :stroke-width="14" :color="sysInfo.memory > 80 ? '#f56c6c' : ''" /></el-descriptions-item>
            <el-descriptions-item label="磁盘使用率"><el-progress :percentage="sysInfo.disk" :stroke-width="14" /></el-descriptions-item>
            <el-descriptions-item label="系统负载">{{ sysInfo.load }}</el-descriptions-item>
            <el-descriptions-item label="运行时间">{{ sysInfo.uptime }}</el-descriptions-item>
          </el-descriptions>
          <div style="margin-top:12px"><el-button type="primary" @click="refresh">刷新</el-button></div>
        </el-card>
      </el-col>
      <el-col :span="12">
        <el-card shadow="hover">
          <template #header><span style="font-weight:bold;">快捷操作</span></template>
          <div style="display:flex;flex-direction:column;gap:12px;">
            <el-button @click="doAction('清理临时文件')">清理临时文件</el-button>
            <el-button @click="doAction('数据库优化')">数据库优化 (VACUUM)</el-button>
            <el-button @click="doAction('重建索引')">重建索引</el-button>
            <el-button @click="doAction('清理日志')">清理历史日志</el-button>
            <el-button type="warning" @click="doAction('重启服务')">重启管理服务</el-button>
          </div>
        </el-card>
      </el-col>
    </el-row>
    <el-card shadow="hover" style="margin-top:16px;">
      <template #header><span style="font-weight:bold;">服务状态</span></template>
      <el-table :data="services" border stripe size="small">
        <el-table-column prop="name" label="服务名称" width="200" />
        <el-table-column prop="status" label="状态" width="100">
          <template #default="{ row }"><el-tag :type="row.status === 'running' ? 'success' : 'danger'" size="small">{{ row.status === 'running' ? '运行中' : '已停止' }}</el-tag></template>
        </el-table-column>
        <el-table-column prop="pid" label="PID" width="80" />
        <el-table-column prop="port" label="端口" width="80" />
        <el-table-column prop="uptime" label="运行时间" width="150" />
        <el-table-column prop="memory" label="内存占用" width="100" />
      </el-table>
    </el-card>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import api from '../api'
import { ElMessage } from 'element-plus'

const sysInfo = reactive({ cpu: 0, memory: 0, disk: 0, load: '-', uptime: '-' })
const services = ref([])

async function refresh() {
  try {
    const info = await api.get('/maintenance/system-info')
    Object.assign(sysInfo, info)
    ElMessage.success('已刷新')
  } catch (e) {
    ElMessage.error('获取系统信息失败')
  }
}

async function loadServices() {
  try {
    services.value = (await api.get('/maintenance/services')).data || []
  } catch (e) {
    services.value = []
  }
}

async function doAction(name) {
  try {
    const res = await api.post('/maintenance/action', { action: name })
    ElMessage.success(res.message || `${name} 已执行`)
  } catch (e) {
    ElMessage.error(e.response?.data?.error || `${name} 执行失败`)
  }
}

onMounted(async () => {
  await Promise.all([refresh(), loadServices()])
})
</script>
