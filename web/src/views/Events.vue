<template>
  <div>
    <div class="page-header">
      <h2>操作日志</h2>
      <div style="display: flex; gap: 10px;">
        <el-select v-model="filter.type" placeholder="事件类型" clearable @change="load" style="width: 120px;">
          <el-option label="系统" value="system" /><el-option label="主机" value="host" /><el-option label="虚拟机" value="vm" /><el-option label="用户" value="user" />
        </el-select>
        <el-select v-model="filter.level" placeholder="级别" clearable @change="load" style="width: 100px;">
          <el-option label="信息" value="info" /><el-option label="警告" value="warning" /><el-option label="错误" value="error" />
        </el-select>
      </div>
    </div>
    <el-tabs v-model="tab">
      <el-tab-pane label="事件日志" name="events">
        <el-table :data="events" v-loading="loading" border stripe>
          <el-table-column prop="created_at" label="时间" width="170" />
          <el-table-column prop="type" label="类型" width="80" />
          <el-table-column prop="level" label="级别" width="80">
            <template #default="{ row }"><el-tag :type="row.level === 'error' ? 'danger' : row.level === 'warning' ? 'warning' : 'info'" size="small">{{ row.level }}</el-tag></template>
          </el-table-column>
          <el-table-column prop="message" label="事件" width="160" />
          <el-table-column prop="resource_name" label="资源" width="140" />
          <el-table-column prop="detail" label="详情" min-width="200" />
          <el-table-column prop="user" label="操作者" width="100" />
        </el-table>
      </el-tab-pane>
      <el-tab-pane label="任务列表" name="tasks">
        <el-table :data="tasks" border stripe size="small">
          <el-table-column prop="created_at" label="时间" width="170" />
          <el-table-column prop="type" label="类型" width="100" />
          <el-table-column prop="description" label="描述" min-width="200" />
          <el-table-column prop="status" label="状态" width="100">
            <template #default="{ row }"><el-tag :type="row.status === 'completed' ? 'success' : row.status === 'failed' ? 'danger' : ''" size="small">{{ row.status }}</el-tag></template>
          </el-table-column>
          <el-table-column prop="progress" label="进度" width="100">
            <template #default="{ row }"><el-progress :percentage="row.progress || 0" :stroke-width="12" /></template>
          </el-table-column>
        </el-table>
      </el-tab-pane>
    </el-tabs>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import api from '../api'

const loading = ref(false)
const tab = ref('events')
const events = ref([]), tasks = ref([])
const filter = reactive({ type: '', level: '' })

async function load() {
  loading.value = true
  try {
    const params = {}
    if (filter.type) params.type = filter.type
    if (filter.level) params.level = filter.level
    events.value = (await api.get('/events', { params })).data
    tasks.value = (await api.get('/events/tasks', { params })).data
  } catch(e) {} finally { loading.value = false }
}

onMounted(load)
</script>
