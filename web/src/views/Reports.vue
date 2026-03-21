<template>
  <div>
    <div class="page-header">
      <h2 style="margin: 0;">统计报表</h2>
      <div style="display: flex; gap: 8px; align-items: center;">
        <el-date-picker v-model="dateRange" type="daterange" start-placeholder="开始日期" end-placeholder="结束日期" value-format="YYYY-MM-DD" size="default" style="width: 280px;" />
        <el-button type="primary" @click="loadData"><el-icon><Refresh /></el-icon>刷新</el-button>
        <el-button @click="exportCSV"><el-icon><Download /></el-icon>导出</el-button>
      </div>
    </div>

    <el-tabs v-model="activeTab" @tab-change="onTabChange">
      <!-- 虚拟机统计 -->
      <el-tab-pane label="虚拟机统计" name="vm">
        <el-row :gutter="16" style="margin-bottom: 16px;">
          <el-col :span="6" v-for="s in vmSummary" :key="s.label">
            <el-card shadow="never" class="stat-card">
              <div class="stat-value" :style="{ color: s.color }">{{ s.value }}</div>
              <div class="stat-label">{{ s.label }}</div>
            </el-card>
          </el-col>
        </el-row>
        <el-row :gutter="16">
          <el-col :span="12">
            <el-card shadow="never"><template #header>虚拟机状态分布</template><div ref="vmPieRef" style="height: 300px;"></div></el-card>
          </el-col>
          <el-col :span="12">
            <el-card shadow="never"><template #header>资源使用趋势</template><div ref="vmTrendRef" style="height: 300px;"></div></el-card>
          </el-col>
        </el-row>
      </el-tab-pane>

      <!-- 服务器统计 -->
      <el-tab-pane label="服务器统计" name="host">
        <el-row :gutter="16" style="margin-bottom: 16px;">
          <el-col :span="6" v-for="s in hostSummary" :key="s.label">
            <el-card shadow="never" class="stat-card">
              <div class="stat-value" :style="{ color: s.color }">{{ s.value }}</div>
              <div class="stat-label">{{ s.label }}</div>
            </el-card>
          </el-col>
        </el-row>
        <el-row :gutter="16">
          <el-col :span="12">
            <el-card shadow="never"><template #header>服务器状态</template><div ref="hostPieRef" style="height: 300px;"></div></el-card>
          </el-col>
          <el-col :span="12">
            <el-card shadow="never"><template #header>CPU/内存负载分布</template><div ref="hostBarRef" style="height: 300px;"></div></el-card>
          </el-col>
        </el-row>
      </el-tab-pane>

      <!-- 用户统计 -->
      <el-tab-pane label="用户统计" name="user">
        <el-row :gutter="16" style="margin-bottom: 16px;">
          <el-col :span="6" v-for="s in userSummary" :key="s.label">
            <el-card shadow="never" class="stat-card">
              <div class="stat-value" :style="{ color: s.color }">{{ s.value }}</div>
              <div class="stat-label">{{ s.label }}</div>
            </el-card>
          </el-col>
        </el-row>
        <el-table :data="userLoginStats" size="small" border stripe style="margin-top: 16px;">
          <el-table-column prop="username" label="用户名" width="120" />
          <el-table-column prop="display_name" label="姓名" width="120" />
          <el-table-column prop="role" label="角色" width="100">
            <template #default="{ row }"><el-tag size="small">{{ row.role }}</el-tag></template>
          </el-table-column>
          <el-table-column prop="vm_count" label="使用虚拟机" width="100" />
          <el-table-column prop="login_count" label="登录次数" width="100" />
          <el-table-column prop="last_login" label="最近登录" min-width="160" />
        </el-table>
      </el-tab-pane>

      <!-- 存储统计 -->
      <el-tab-pane label="存储统计" name="storage">
        <el-row :gutter="16">
          <el-col :span="12">
            <el-card shadow="never"><template #header>存储池容量</template><div ref="storagePieRef" style="height: 300px;"></div></el-card>
          </el-col>
          <el-col :span="12">
            <el-card shadow="never"><template #header>存储使用详情</template>
              <el-table :data="storagePools" size="small" border stripe>
                <el-table-column prop="name" label="存储池" width="140" />
                <el-table-column prop="type" label="类型" width="80" />
                <el-table-column label="已用/总量" min-width="120">
                  <template #default="{ row }">{{ row.used_gb }}/{{ row.total_gb }} GB</template>
                </el-table-column>
                <el-table-column label="使用率" width="200">
                  <template #default="{ row }"><el-progress :percentage="row.total_gb ? Math.round(row.used_gb / row.total_gb * 100) : 0" /></template>
                </el-table-column>
              </el-table>
            </el-card>
          </el-col>
        </el-row>
      </el-tab-pane>
    </el-tabs>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted, nextTick } from 'vue'
import * as echarts from 'echarts'
import api from '../api'

const chartInstances = []

const activeTab = ref('vm')
const dateRange = ref([])

// Data holders
const vmSummary = ref([])
const hostSummary = ref([])
const userSummary = ref([])
const userLoginStats = ref([])
const storagePools = ref([])

const vmPieRef = ref(null)
const vmTrendRef = ref(null)
const hostPieRef = ref(null)
const hostBarRef = ref(null)
const storagePieRef = ref(null)

async function loadData() {
  try {
    // Load stats + all resources
    const [stats, vmRes, hostRes, userRes, storageRes] = await Promise.all([
      api.get('/stats'),
      api.get('/vms'),
      api.get('/hosts'),
      api.get('/users'),
      api.get('/storage/pools')
    ])

    const vms = vmRes.data || []
    const hosts = hostRes.data || []
    const users = userRes.data || []
    const pools = storageRes.data || []

    // VM summary
    const running = vms.filter(v => v.status === 'running').length
    const stopped = vms.filter(v => v.status === 'stopped').length
    vmSummary.value = [
      { label: '虚拟机总数', value: vms.length, color: '#409eff' },
      { label: '运行中', value: running, color: '#67c23a' },
      { label: '已关机', value: stopped, color: '#f56c6c' },
      { label: '其他状态', value: vms.length - running - stopped, color: '#e6a23c' }
    ]

    // Host summary
    const online = hosts.filter(h => h.status === 'online').length
    hostSummary.value = [
      { label: '服务器总数', value: hosts.length, color: '#409eff' },
      { label: '在线', value: online, color: '#67c23a' },
      { label: '离线', value: hosts.length - online, color: '#f56c6c' },
      { label: '平均CPU', value: (stats.cpu_usage || 0).toFixed(0) + '%', color: '#e6a23c' }
    ]

    // User summary
    userSummary.value = [
      { label: '用户总数', value: users.length, color: '#409eff' },
      { label: '管理员', value: users.filter(u => u.role === 'admin').length, color: '#e6a23c' },
      { label: '普通用户', value: users.filter(u => u.role === 'user').length, color: '#67c23a' },
      { label: '禁用用户', value: users.filter(u => u.status === 'disabled').length, color: '#f56c6c' }
    ]
    userLoginStats.value = users.map(u => ({
      ...u,
      vm_count: vms.filter(v => v.owner === u.username).length,
      login_count: u.login_count || 0
    }))

    // Storage
    storagePools.value = pools.map(p => ({
      name: p.name, type: p.type,
      used_gb: Math.round((p.used || 0) / 1024),
      total_gb: Math.round((p.capacity || 0) / 1024)
    }))

    await nextTick()
    renderCharts(vms, hosts, pools, stats)
  } catch(e) { console.error(e) }
}

function renderCharts(vms, hosts, pools, stats) {
  chartInstances.forEach(c => c.dispose())
  chartInstances.length = 0
  // VM Pie
  if (vmPieRef.value) {
    const chart = echarts.init(vmPieRef.value)
    chartInstances.push(chart)
    const statusMap = {}
    vms.forEach(v => { statusMap[v.status] = (statusMap[v.status] || 0) + 1 })
    chart.setOption({
      tooltip: { trigger: 'item' },
      legend: { bottom: 0 },
      series: [{ type: 'pie', radius: ['40%', '70%'], data: Object.entries(statusMap).map(([k, v]) => ({ name: k, value: v })),
        label: { formatter: '{b}: {c}' }
      }]
    })
  }

  // VM Trend (simulated)
  if (vmTrendRef.value) {
    const chart = echarts.init(vmTrendRef.value)
    chartInstances.push(chart)
    const days = ['周一','周二','周三','周四','周五','周六','周日']
    chart.setOption({
      tooltip: { trigger: 'axis' },
      legend: { bottom: 0 },
      grid: { top: 10, right: 20, bottom: 40, left: 50 },
      xAxis: { type: 'category', data: days },
      yAxis: { type: 'value', axisLabel: { formatter: '{value}%' } },
      series: [
        { name: 'CPU', type: 'line', smooth: true, data: days.map(() => Math.round(stats.cpu_usage * (0.8 + Math.random() * 0.4))) },
        { name: '内存', type: 'line', smooth: true, data: days.map(() => Math.round(stats.mem_usage * (0.8 + Math.random() * 0.4))) }
      ]
    })
  }

  // Host Pie
  if (hostPieRef.value) {
    const chart = echarts.init(hostPieRef.value)
    chartInstances.push(chart)
    const online = hosts.filter(h => h.status === 'online').length
    chart.setOption({
      tooltip: { trigger: 'item' },
      series: [{ type: 'pie', radius: ['40%', '70%'], data: [
        { name: '在线', value: online, itemStyle: { color: '#67c23a' } },
        { name: '离线', value: hosts.length - online, itemStyle: { color: '#f56c6c' } }
      ], label: { formatter: '{b}: {c}台' } }]
    })
  }

  // Host Bar
  if (hostBarRef.value) {
    const chart = echarts.init(hostBarRef.value)
    chartInstances.push(chart)
    chart.setOption({
      tooltip: { trigger: 'axis' },
      grid: { top: 10, right: 20, bottom: 30, left: 50 },
      xAxis: { type: 'category', data: hosts.map(h => h.name), axisLabel: { rotate: 30 } },
      yAxis: { type: 'value', max: 100, axisLabel: { formatter: '{value}%' } },
      series: [
        { name: 'CPU', type: 'bar', data: hosts.map(h => h.cpu_total ? Math.round(h.cpu_used / h.cpu_total * 100) : 0), itemStyle: { color: '#409eff' } },
        { name: '内存', type: 'bar', data: hosts.map(h => h.mem_total ? Math.round(h.mem_used / h.mem_total * 100) : 0), itemStyle: { color: '#67c23a' } }
      ]
    })
  }

  // Storage Pie
  if (storagePieRef.value) {
    const chart = echarts.init(storagePieRef.value)
    chartInstances.push(chart)
    chart.setOption({
      tooltip: { trigger: 'item', formatter: '{b}: {c} GB' },
      series: [{ type: 'pie', radius: ['40%', '70%'], data: pools.map(p => ({
        name: p.name, value: Math.round((p.capacity || 0) / 1024)
      })), label: { formatter: '{b}\n{c}GB' } }]
    })
  }
}

function onTabChange() { nextTick(() => loadData()) }

function exportCSV() {
  let csv = ''
  if (activeTab.value === 'user') {
    csv = 'username,display_name,role,vm_count,login_count\n'
    userLoginStats.value.forEach(u => { csv += `${u.username},${u.display_name || ''},${u.role},${u.vm_count},${u.login_count}\n` })
  } else if (activeTab.value === 'storage') {
    csv = 'name,type,used_gb,total_gb\n'
    storagePools.value.forEach(s => { csv += `${s.name},${s.type},${s.used_gb},${s.total_gb}\n` })
  } else return
  const blob = new Blob(['\ufeff' + csv], { type: 'text/csv;charset=utf-8;' })
  const a = document.createElement('a')
  a.href = URL.createObjectURL(blob)
  a.download = `report_${activeTab.value}_${new Date().toISOString().slice(0,10)}.csv`
  a.click()
}

function handleResize() {
  chartInstances.forEach(c => c.resize())
}

onMounted(() => {
  loadData()
  window.addEventListener('resize', handleResize)
})

onUnmounted(() => {
  window.removeEventListener('resize', handleResize)
  chartInstances.forEach(c => c.dispose())
  chartInstances.length = 0
})
</script>

<style scoped>
.stat-card { text-align: center; }
.stat-value { font-size: 28px; font-weight: 700; line-height: 40px; }
.stat-label { font-size: 13px; color: #909399; margin-top: 4px; }
</style>
