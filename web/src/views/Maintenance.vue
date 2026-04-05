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
import { ElMessage } from 'element-plus'

const sysInfo = reactive({ cpu: 35, memory: 62, disk: 45, load: '0.85 0.72 0.58', uptime: '15天 8小时' })
const services = ref([
  { name: '管理控制台 (MC)', status: 'running', pid: '37380', port: '8444', uptime: '15天 8小时', memory: '128MB' },
  { name: '虚拟化控制台 (Cockpit)', status: 'running', pid: '26056', port: '9091', uptime: '15天 8小时', memory: '64MB' },
  { name: 'libvirtd', status: 'running', pid: '1234', port: '-', uptime: '15天 8小时', memory: '32MB' },
  { name: 'GlusterFS', status: 'running', pid: '2345', port: '24007', uptime: '15天 8小时', memory: '256MB' },
  { name: 'MariaDB/MySQL', status: 'running', pid: '3456', port: '3306', uptime: '15天 8小时', memory: '512MB' },
])

function refresh() {
  sysInfo.cpu = Math.floor(Math.random() * 40 + 20)
  sysInfo.memory = Math.floor(Math.random() * 30 + 50)
  ElMessage.success('已刷新')
}

function doAction(name) { ElMessage.success(`${name} 操作已执行（模拟）`) }

onMounted(() => {})
</script>
