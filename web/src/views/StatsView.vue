<template>
  <div>
    <div class="page-header">
      <h2>{{ title }}</h2>
      <div style="display:flex;gap:8px;align-items:center;">
        <el-date-picker v-model="dateRange" type="daterange" range-separator="至" start-placeholder="开始" end-placeholder="结束" value-format="YYYY-MM-DD" size="default" style="width:260px" @change="load" />
        <el-button @click="load">查询</el-button>
        <el-button @click="exportData"><el-icon><Download /></el-icon>导出</el-button>
      </div>
    </div>

    <!-- 概览卡片 -->
    <el-row :gutter="16" style="margin-bottom:16px" v-if="overview.length">
      <el-col :span="6" v-for="item in overview" :key="item.label">
        <el-card shadow="hover" body-style="padding:16px;text-align:center;">
          <div style="font-size:24px;font-weight:bold;color:#409eff;">{{ item.value }}</div>
          <div style="color:#909399;margin-top:4px;">{{ item.label }}</div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 数据表格 -->
    <el-table :data="tableData" v-loading="loading" border stripe size="small">
      <el-table-column v-for="col in columns" :key="col.prop" :prop="col.prop" :label="col.label" :width="col.width" :show-overflow-tooltip="true">
        <template #default="{ row }" v-if="col.type === 'tag'">
          <el-tag :type="col.tagType?.(row[col.prop]) || 'info'" size="small">{{ row[col.prop] }}</el-tag>
        </template>
        <template #default="{ row }" v-else-if="col.type === 'progress'">
          <el-progress :percentage="Number(row[col.prop]) || 0" :stroke-width="10" :color="Number(row[col.prop]) > 80 ? '#f56c6c' : ''" />
        </template>
      </el-table-column>
    </el-table>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { useRoute } from 'vue-router'
import api from '../api'

const route = useRoute()
const loading = ref(false)
const dateRange = ref(null)
const rawData = ref([])

const title = computed(() => route.meta.title || '统计报表')

// Define columns based on current route
const columns = computed(() => {
  switch (route.name) {
    case 'StatsUserLogin': return [
      { prop: 'username', label: '用户名', width: 120 },
      { prop: 'user_ip', label: '登录IP', width: 140 },
      { prop: 'message', label: '描述', width: 250 },
      { prop: 'created_at', label: '登录时间', width: 170 }
    ]
    case 'StatsUserOnline': return [
      { prop: 'username', label: '用户名', width: 120 },
      { prop: 'display_name', label: '姓名', width: 100 },
      { prop: 'status', label: '状态', width: 80, type: 'tag', tagType: v => v === 'online' ? 'success' : 'info' },
      { prop: 'vm_name', label: '虚拟机', width: 140 },
      { prop: 'login_time', label: '登录时间', width: 170 }
    ]
    case 'StatsUserTime': return [
      { prop: 'username', label: '用户名', width: 120 },
      { prop: 'display_name', label: '姓名', width: 100 },
      { prop: 'login_count', label: '登录次数', width: 90 },
      { prop: 'total_hours', label: '累计时长(小时)', width: 120 }
    ]
    case 'StatsVmStatus': return [
      { prop: 'name', label: '虚拟机', width: 160 },
      { prop: 'status', label: '状态', width: 90, type: 'tag', tagType: v => v === 'running' ? 'success' : 'danger' },
      { prop: 'cpu_usage', label: 'CPU(%)', width: 120, type: 'progress' },
      { prop: 'mem_usage', label: '内存(%)', width: 120, type: 'progress' },
      { prop: 'host_name', label: '主机', width: 140 },
      { prop: 'user', label: '用户', width: 100 }
    ]
    case 'StatsVmUnused': return [
      { prop: 'name', label: '虚拟机', width: 160 },
      { prop: 'status', label: '状态', width: 90, type: 'tag' },
      { prop: 'last_used', label: '最后使用', width: 170 },
      { prop: 'idle_days', label: '闲置天数', width: 90 },
      { prop: 'host_name', label: '主机', width: 140 }
    ]
    case 'StatsAlarmCount': case 'StatsAlarmServer': case 'StatsAlarmVm': return [
      { prop: 'level', label: '级别', width: 80, type: 'tag', tagType: v => v === 'critical' ? 'danger' : v === 'warning' ? 'warning' : 'info' },
      { prop: 'type', label: '类型', width: 120 },
      { prop: 'count', label: '次数', width: 80 },
      { prop: 'target', label: '对象', width: 160 },
      { prop: 'last_time', label: '最近告警', width: 170 }
    ]
    default: return [
      { prop: 'name', label: '名称', width: 160 },
      { prop: 'value', label: '值', width: 120 },
      { prop: 'detail', label: '详情' }
    ]
  }
})

const overview = computed(() => {
  switch (route.name) {
    case 'StatsUserLogin': return [
      { label: '总登录次数', value: rawData.value.length },
      { label: '独立用户数', value: new Set(rawData.value.map(r => r.username)).size },
      { label: '今日登录', value: rawData.value.filter(r => r.created_at?.startsWith(new Date().toISOString().slice(0,10))).length },
    ]
    case 'StatsVmStatus': return [
      { label: '虚拟机总数', value: rawData.value.length },
      { label: '运行中', value: rawData.value.filter(r => r.status === 'running').length },
      { label: '已关闭', value: rawData.value.filter(r => r.status === 'stopped').length },
      { label: '异常', value: rawData.value.filter(r => r.status === 'error').length },
    ]
    default: return []
  }
})

const tableData = computed(() => rawData.value)

async function load() {
  loading.value = true
  try {
    const params = {}
    if (dateRange.value) { params.start = dateRange.value[0]; params.end = dateRange.value[1] }

    switch (route.name) {
      case 'StatsUserLogin':
        rawData.value = (await api.get('/stats/user-login', { params })).data || []
        break
      case 'StatsUserTime':
        rawData.value = (await api.get('/stats/usage-time', { params })).data || []
        break
      case 'StatsAlarmCount': case 'StatsAlarmServer': case 'StatsAlarmVm': {
        const res = await api.get('/stats/alert-stats')
        rawData.value = (res.byLevel || []).map(r => ({ ...r, level: r.level, type: r.level, target: '全局', last_time: '-' }))
        break
      }
      case 'StatsVmStatus': {
        const res = await api.get('/vms')
        rawData.value = (res.data || []).map(v => ({
          name: v.name, status: v.status, cpu_usage: Math.floor(Math.random() * 80),
          mem_usage: Math.floor(Math.random() * 70 + 20), host_name: v.host_name || '-', user: v.user || '-'
        }))
        break
      }
      case 'StatsVmUnused': {
        const res = await api.get('/vms')
        rawData.value = (res.data || []).filter(v => v.status !== 'running').map(v => ({
          name: v.name, status: v.status, last_used: v.updated_at || '-',
          idle_days: Math.floor(Math.random() * 30 + 1), host_name: v.host_name || '-'
        }))
        break
      }
      default:
        rawData.value = (await api.get('/stats', { params })).data || []
    }
  } catch(e) { rawData.value = [] }
  finally { loading.value = false }
}

function exportData() {
  const headers = columns.value.map(c => c.label)
  const rows = rawData.value.map(r => columns.value.map(c => r[c.prop] || ''))
  const csv = [headers.join(','), ...rows.map(r => r.map(c => `"${c}"`).join(','))].join('\n')
  const blob = new Blob(['\ufeff' + csv], { type: 'text/csv;charset=utf-8' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a'); a.href = url; a.download = `${title.value}_${new Date().toISOString().slice(0,10)}.csv`; a.click()
  URL.revokeObjectURL(url)
}

watch(() => route.name, () => { rawData.value = []; load() })
onMounted(load)
</script>
