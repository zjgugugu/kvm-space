<template>
  <div>
    <div class="page-header">
      <h2>{{ title }}</h2>
      <div style="display:flex;gap:8px;align-items:center;">
        <el-date-picker v-model="dateRange" type="daterange" range-separator="至" start-placeholder="开始日期" end-placeholder="结束日期" value-format="YYYY-MM-DD" size="default" style="width:280px;" @change="load" />
        <el-input v-model="searchUser" placeholder="搜索用户" clearable style="width:160px;" @clear="load" @keyup.enter="load">
          <template #prefix><el-icon><Search /></el-icon></template>
        </el-input>
        <el-button @click="load">查询</el-button>
        <el-button @click="exportCsv"><el-icon><Download /></el-icon>导出</el-button>
      </div>
    </div>
    <el-table :data="events" v-loading="loading" border stripe size="small" max-height="600">
      <el-table-column prop="id" label="ID" width="60" />
      <el-table-column prop="user" label="操作用户" width="100" v-if="showUser" />
      <el-table-column prop="user_ip" label="IP地址" width="130" v-if="showUser" />
      <el-table-column prop="action" label="操作" width="120" v-if="isAudit" />
      <el-table-column prop="resource_type" label="资源类型" width="100" v-if="isAudit" />
      <el-table-column prop="resource_name" label="资源名称" width="140" v-if="isAudit" />
      <el-table-column prop="type" label="事件类型" width="100" v-if="!isAudit">
        <template #default="{ row }"><el-tag size="small">{{ row.type }}</el-tag></template>
      </el-table-column>
      <el-table-column prop="level" label="级别" width="80">
        <template #default="{ row }"><el-tag :type="levelType(row.level || row.result)" size="small">{{ row.level || row.result }}</el-tag></template>
      </el-table-column>
      <el-table-column prop="message" label="详情" min-width="250" show-overflow-tooltip>
        <template #default="{ row }">{{ row.message || row.detail }}</template>
      </el-table-column>
      <el-table-column prop="created_at" label="时间" width="160" />
    </el-table>
    <div style="margin-top:12px;display:flex;justify-content:space-between;align-items:center;">
      <span style="color:#909399;font-size:13px;">共 {{ total }} 条记录</span>
      <el-pagination v-model:current-page="page" :page-size="pageSize" :total="total" layout="prev, pager, next" @current-change="load" />
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import api from '../api'

const route = useRoute()
const loading = ref(false)
const events = ref([])
const total = ref(0), page = ref(1), pageSize = ref(50)
const dateRange = ref(null), searchUser = ref('')

const isAudit = computed(() => route.name === 'AuditEvents' || route.name === 'ClientAuditEvents')
const showUser = computed(() => route.name !== 'ServerEvents')
const title = computed(() => route.meta.title || '事件日志')

function levelType(l) { return { info: 'info', warning: 'warning', error: 'danger', critical: 'danger', success: 'success' }[l] || 'info' }

async function load() {
  loading.value = true
  try {
    const params = { page: page.value, page_size: pageSize.value }
    if (dateRange.value) { params.start = dateRange.value[0]; params.end = dateRange.value[1] }
    if (searchUser.value) params.user = searchUser.value

    let res
    if (isAudit.value) {
      res = await api.get('/stats/audit', { params })
      events.value = res.data || []
      total.value = events.value.length
    } else {
      // Map route to event type filter
      const typeMap = { SessionEvents: 'session', ServerVirtEvents: 'server_virt', ServerEvents: '' }
      const type = typeMap[route.name] || ''
      if (type) params.type = type
      res = await api.get('/events', { params })
      events.value = res.data || []
      total.value = res.total || events.value.length
    }
  } catch(e) { events.value = []; total.value = 0 }
  finally { loading.value = false }
}

function exportCsv() {
  const headers = isAudit.value
    ? ['ID', '用户', 'IP', '操作', '资源类型', '资源名称', '级别', '详情', '时间']
    : ['ID', '类型', '级别', '消息', '时间']
  const rows = events.value.map(e => isAudit.value
    ? [e.id, e.user, e.user_ip, e.action, e.resource_type, e.resource_name, e.level || e.result, e.detail || e.message, e.created_at]
    : [e.id, e.type, e.level, e.message, e.created_at]
  )
  const csv = [headers.join(','), ...rows.map(r => r.map(c => `"${c || ''}"`).join(','))].join('\n')
  const blob = new Blob(['\ufeff' + csv], { type: 'text/csv;charset=utf-8' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a'); a.href = url; a.download = `${title.value}_${new Date().toISOString().slice(0,10)}.csv`; a.click()
  URL.revokeObjectURL(url)
}

onMounted(load)
</script>
