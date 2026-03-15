<template>
  <div>
    <div class="page-header">
      <h2>日志告警</h2>
      <div style="display: flex; gap: 8px; align-items: center;">
        <el-date-picker v-model="dateRange" type="daterange" start-placeholder="开始" end-placeholder="结束" value-format="YYYY-MM-DD" size="default" style="width: 260px;" @change="load" />
        <el-select v-model="filter.type" placeholder="事件类型" clearable @change="load" style="width: 110px;">
          <el-option label="系统" value="system" /><el-option label="服务器" value="host" /><el-option label="虚拟机" value="vm" /><el-option label="用户" value="user" />
        </el-select>
        <el-select v-model="filter.level" placeholder="级别" clearable @change="load" style="width: 90px;">
          <el-option label="信息" value="info" /><el-option label="警告" value="warning" /><el-option label="错误" value="error" />
        </el-select>
        <el-input v-model="filter.search" placeholder="搜索关键字" clearable style="width: 160px;" @keyup.enter="load" />
        <el-button @click="load"><el-icon><Refresh /></el-icon></el-button>
        <el-button @click="exportCSV"><el-icon><Download /></el-icon>导出</el-button>
      </div>
    </div>

    <el-tabs v-model="tab" @tab-change="load">
      <el-tab-pane name="events">
        <template #label><el-icon><Document /></el-icon> 事件日志</template>
        <el-table :data="events" v-loading="loading" border stripe size="small" max-height="600">
          <el-table-column prop="created_at" label="时间" width="160" sortable />
          <el-table-column prop="type" label="类型" width="80">
            <template #default="{ row }">
              <el-tag size="small" :type="typeColor(row.type)">{{ typeText(row.type) }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="level" label="级别" width="75">
            <template #default="{ row }"><el-tag :type="row.level === 'error' ? 'danger' : row.level === 'warning' ? 'warning' : 'info'" size="small">{{ levelText(row.level) }}</el-tag></template>
          </el-table-column>
          <el-table-column prop="message" label="事件描述" width="180" show-overflow-tooltip />
          <el-table-column prop="resource_name" label="资源" width="130" />
          <el-table-column prop="detail" label="详情" min-width="200" show-overflow-tooltip />
          <el-table-column prop="user" label="操作者" width="90" />
        </el-table>
      </el-tab-pane>

      <el-tab-pane name="alerts">
        <template #label><el-icon><Warning /></el-icon> 告警事件 <el-badge :value="alerts.length" :hidden="!alerts.length" /></template>
        <el-table :data="alerts" border stripe size="small">
          <el-table-column prop="created_at" label="时间" width="160" />
          <el-table-column prop="level" label="级别" width="80">
            <template #default="{ row }"><el-tag :type="row.level === 'error' ? 'danger' : 'warning'" size="small">{{ row.level === 'error' ? '严重' : '警告' }}</el-tag></template>
          </el-table-column>
          <el-table-column prop="message" label="告警内容" min-width="200" />
          <el-table-column prop="resource_name" label="资源" width="130" />
          <el-table-column label="状态" width="90">
            <template #default="{ row }">
              <el-tag :type="row.acknowledged ? 'info' : 'danger'" size="small">{{ row.acknowledged ? '已确认' : '未确认' }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column label="操作" width="100">
            <template #default="{ row }">
              <el-button size="small" v-if="!row.acknowledged" @click="acknowledgeAlert(row)">确认</el-button>
            </template>
          </el-table-column>
        </el-table>
      </el-tab-pane>

      <el-tab-pane name="tasks">
        <template #label><el-icon><List /></el-icon> 任务列表</template>
        <el-table :data="tasks" border stripe size="small">
          <el-table-column prop="created_at" label="时间" width="160" />
          <el-table-column prop="type" label="类型" width="100">
            <template #default="{ row }"><el-tag size="small">{{ row.type }}</el-tag></template>
          </el-table-column>
          <el-table-column prop="description" label="描述" min-width="200" />
          <el-table-column prop="status" label="状态" width="90">
            <template #default="{ row }"><el-tag :type="row.status === 'completed' ? 'success' : row.status === 'failed' ? 'danger' : row.status === 'running' ? '' : 'info'" size="small">{{ taskStatusText(row.status) }}</el-tag></template>
          </el-table-column>
          <el-table-column prop="progress" label="进度" width="120">
            <template #default="{ row }"><el-progress :percentage="row.progress || 0" :stroke-width="12" :status="row.status === 'failed' ? 'exception' : row.status === 'completed' ? 'success' : ''" /></template>
          </el-table-column>
          <el-table-column prop="duration" label="耗时" width="80">
            <template #default="{ row }">{{ row.duration ? row.duration + 's' : '-' }}</template>
          </el-table-column>
        </el-table>
      </el-tab-pane>
    </el-tabs>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import api from '../api'
import { ElMessage } from 'element-plus'

const loading = ref(false)
const tab = ref('events')
const events = ref([]), tasks = ref([]), alerts = ref([])
const dateRange = ref([])
const filter = reactive({ type: '', level: '', search: '' })

function typeColor(t) { return { system: '', host: 'warning', vm: 'success', user: 'info' }[t] || '' }
function typeText(t) { return { system: '系统', host: '服务器', vm: '虚拟机', user: '用户' }[t] || t }
function levelText(l) { return { info: '信息', warning: '警告', error: '错误' }[l] || l }
function taskStatusText(s) { return { completed: '完成', failed: '失败', running: '运行中', pending: '等待中' }[s] || s }

async function load() {
  loading.value = true
  try {
    const params = {}
    if (filter.type) params.type = filter.type
    if (filter.level) params.level = filter.level
    if (filter.search) params.search = filter.search
    if (dateRange.value?.length === 2) { params.start_date = dateRange.value[0]; params.end_date = dateRange.value[1] }
    events.value = (await api.get('/events', { params })).data || []
    tasks.value = (await api.get('/events/tasks', { params })).data || []
    alerts.value = events.value.filter(e => e.level === 'warning' || e.level === 'error')
  } catch(e) { events.value = []; tasks.value = []; alerts.value = [] }
  finally { loading.value = false }
}

function acknowledgeAlert(row) {
  row.acknowledged = true
  ElMessage.success('告警已确认')
}

function exportCSV() {
  let data = tab.value === 'tasks' ? tasks.value : events.value
  let csv = 'time,type,level,message,resource,detail,user\n'
  data.forEach(e => { csv += `"${e.created_at}","${e.type || ''}","${e.level || ''}","${(e.message || e.description || '').replace(/"/g, '""')}","${e.resource_name || ''}","${(e.detail || '').replace(/"/g, '""')}","${e.user || ''}"\n` })
  const blob = new Blob(['\ufeff' + csv], { type: 'text/csv;charset=utf-8;' })
  const a = document.createElement('a')
  a.href = URL.createObjectURL(blob)
  a.download = `${tab.value}_${new Date().toISOString().slice(0,10)}.csv`
  a.click()
}

onMounted(load)
</script>
