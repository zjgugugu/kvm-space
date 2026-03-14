<template>
  <div>
    <div class="page-header"><h2>告警管理</h2></div>
    <el-tabs v-model="tab">
      <el-tab-pane label="活跃告警" name="active">
        <el-table :data="alerts" v-loading="loading" border stripe>
          <el-table-column prop="created_at" label="时间" width="170" />
          <el-table-column prop="level" label="级别" width="80">
            <template #default="{ row }"><el-tag :type="row.level === 'critical' ? 'danger' : row.level === 'warning' ? 'warning' : 'info'" size="small">{{ row.level }}</el-tag></template>
          </el-table-column>
          <el-table-column prop="type" label="类型" width="100" />
          <el-table-column prop="message" label="告警信息" min-width="200" />
          <el-table-column prop="resource_name" label="资源" width="140" />
          <el-table-column prop="status" label="状态" width="80">
            <template #default="{ row }"><el-tag :type="row.status === 'active' ? 'danger' : 'success'" size="small">{{ row.status === 'active' ? '活跃' : '已确认' }}</el-tag></template>
          </el-table-column>
          <el-table-column label="操作" width="120" fixed="right">
            <template #default="{ row }">
              <el-button v-if="row.status === 'active'" size="small" type="primary" @click="ack(row)">确认</el-button>
            </template>
          </el-table-column>
        </el-table>
      </el-tab-pane>
      <el-tab-pane label="告警设置" name="settings">
        <el-table :data="settings" border stripe size="small">
          <el-table-column prop="name" label="监控项" width="160" />
          <el-table-column prop="type" label="类型" width="100" />
          <el-table-column prop="threshold" label="阈值" width="80" />
          <el-table-column prop="level" label="级别" width="80" />
          <el-table-column prop="enabled" label="启用" width="80">
            <template #default="{ row }"><el-switch :model-value="!!row.enabled" @change="v => toggleSetting(row, v)" /></template>
          </el-table-column>
          <el-table-column prop="description" label="描述" min-width="200" />
        </el-table>
      </el-tab-pane>
    </el-tabs>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import api from '../api'
import { ElMessage } from 'element-plus'

const loading = ref(false), tab = ref('active')
const alerts = ref([]), settings = ref([])

async function load() {
  loading.value = true
  try {
    alerts.value = (await api.get('/alerts')).data
    settings.value = (await api.get('/alerts/settings')).data
  } catch(e) {} finally { loading.value = false }
}

async function ack(a) {
  await api.post(`/alerts/${a.id}/acknowledge`); ElMessage.success('已确认'); load()
}

async function toggleSetting(s, v) {
  await api.put(`/alerts/settings/${s.id}`, { enabled: v ? 1 : 0 }); ElMessage.success('已更新'); load()
}

onMounted(load)
</script>
