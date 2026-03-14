<template>
  <div>
    <div class="page-header"><h2>平台总览</h2></div>
    <!-- 资源统计卡片 -->
    <el-row :gutter="16" style="margin-bottom: 20px;">
      <el-col :span="4" v-for="s in statCards" :key="s.label">
        <el-card shadow="hover">
          <div class="stat-card">
            <div class="value" :style="{ color: s.color }">{{ s.value }}</div>
            <div class="label">{{ s.label }}</div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 资源使用率 -->
    <el-row :gutter="16" style="margin-bottom: 20px;">
      <el-col :span="8" v-for="r in resources" :key="r.label">
        <el-card shadow="hover">
          <div style="font-size: 14px; font-weight: 600; margin-bottom: 12px;">{{ r.label }}</div>
          <el-progress :percentage="r.usage" :stroke-width="18" :color="r.usage > 80 ? '#f56c6c' : r.usage > 60 ? '#e6a23c' : '#409eff'" />
          <div style="margin-top: 8px; color: #909399; font-size: 12px;">
            已用 {{ r.used }} / 总计 {{ r.total }} {{ r.unit }}
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 近期事件 -->
    <el-card shadow="hover">
      <template #header><span style="font-weight: 600;">近期事件</span></template>
      <el-table :data="overview.recent_events || []" size="small" max-height="300">
        <el-table-column prop="created_at" label="时间" width="170" />
        <el-table-column prop="message" label="事件" />
        <el-table-column prop="resource_name" label="资源" width="160" />
        <el-table-column prop="user" label="用户" width="100" />
        <el-table-column prop="level" label="级别" width="80">
          <template #default="{ row }">
            <el-tag :type="row.level === 'error' ? 'danger' : row.level === 'warning' ? 'warning' : 'info'" size="small">{{ row.level }}</el-tag>
          </template>
        </el-table-column>
      </el-table>
    </el-card>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import api from '../api'

const overview = ref({})

const statCards = computed(() => {
  const o = overview.value
  return [
    { label: '主机总数', value: o.hosts?.total ?? '-', color: '#409eff' },
    { label: '在线主机', value: o.hosts?.online ?? '-', color: '#67c23a' },
    { label: '虚拟机总数', value: o.vms?.total ?? '-', color: '#409eff' },
    { label: '运行中', value: o.vms?.running ?? '-', color: '#67c23a' },
    { label: '模板数', value: o.templates?.total ?? '-', color: '#e6a23c' },
    { label: '用户数', value: o.users?.total ?? '-', color: '#909399' }
  ]
})

const resources = computed(() => {
  const c = overview.value.cluster || {}
  return [
    { label: 'CPU', used: c.cpu?.used ?? 0, total: c.cpu?.total ?? 0, usage: c.cpu?.usage ?? 0, unit: '核' },
    { label: '内存', used: ((c.memory?.used ?? 0) / 1024).toFixed(1), total: ((c.memory?.total ?? 0) / 1024).toFixed(1), usage: c.memory?.usage ?? 0, unit: 'GB' },
    { label: '存储', used: ((c.storage?.used ?? 0) / 1024).toFixed(1), total: ((c.storage?.total ?? 0) / 1024).toFixed(1), usage: c.storage?.usage ?? 0, unit: 'TB' }
  ]
})

onMounted(async () => {
  overview.value = await api.get('/dashboard/overview')
})
</script>
