<template>
  <div v-loading="loading">
    <div class="page-header">
      <div style="display: flex; align-items: center; gap: 12px;">
        <el-button @click="$router.push('/hosts')" :icon="ArrowLeft" circle size="small" />
        <h2 style="margin: 0;">{{ host.name || '服务器详情' }}</h2>
        <el-tag :type="host.status === 'online' ? 'success' : 'danger'" size="large">{{ host.status === 'online' ? '在线' : host.status === 'rebooting' ? '重启中' : '离线' }}</el-tag>
      </div>
      <div style="display: flex; gap: 8px;">
        <el-button v-if="host.status === 'online'" type="warning" @click="doAction('reboot')"><el-icon><RefreshRight /></el-icon>重启</el-button>
        <el-button v-if="host.status === 'online'" type="danger" @click="doAction('shutdown')"><el-icon><SwitchButton /></el-icon>关机</el-button>
        <el-button v-if="host.status === 'offline'" type="success" @click="doAction('reboot')"><el-icon><VideoPlay /></el-icon>开机</el-button>
      </div>
    </div>

    <el-tabs v-model="activeTab" type="border-card">
      <!-- 概要 -->
      <el-tab-pane label="概要" name="overview">
        <el-row :gutter="20">
          <el-col :span="12">
            <el-descriptions :column="1" border size="default" title="基本信息">
              <el-descriptions-item label="服务器名称">{{ host.name }}</el-descriptions-item>
              <el-descriptions-item label="IP地址">{{ host.ip }}</el-descriptions-item>
              <el-descriptions-item label="BMC地址">{{ host.bmc_ip || '-' }}</el-descriptions-item>
              <el-descriptions-item label="服务器类型">{{ host.role }}</el-descriptions-item>
              <el-descriptions-item label="架构">{{ host.arch }}</el-descriptions-item>
              <el-descriptions-item label="CPU型号">{{ host.cpu_model }}</el-descriptions-item>
              <el-descriptions-item label="操作系统">{{ host.os }}</el-descriptions-item>
              <el-descriptions-item label="内核版本">{{ host.kernel || '-' }}</el-descriptions-item>
              <el-descriptions-item label="运行时间">{{ formatUptime(host.uptime) }}</el-descriptions-item>
            </el-descriptions>
          </el-col>
          <el-col :span="12">
            <el-descriptions :column="1" border size="default" title="资源概况">
              <el-descriptions-item label="CPU">
                <el-progress :percentage="host.cpu_total ? Math.round(host.cpu_used / host.cpu_total * 100) : 0" :stroke-width="16" />
                <span style="font-size: 12px; color: #909399;">{{ host.cpu_used }}/{{ host.cpu_total }} 核</span>
              </el-descriptions-item>
              <el-descriptions-item label="内存">
                <el-progress :percentage="host.mem_total ? Math.round(host.mem_used / host.mem_total * 100) : 0" :stroke-width="16" />
                <span style="font-size: 12px; color: #909399;">{{ (host.mem_used / 1024).toFixed(1) }}/{{ (host.mem_total / 1024).toFixed(1) }} GB</span>
              </el-descriptions-item>
              <el-descriptions-item label="存储">
                <el-progress :percentage="host.disk_total ? Math.round(host.disk_used / host.disk_total * 100) : 0" :stroke-width="16" />
                <span style="font-size: 12px; color: #909399;">{{ host.disk_used }}/{{ host.disk_total }} GB</span>
              </el-descriptions-item>
              <el-descriptions-item label="网络带宽">{{ host.net_speed ? (host.net_speed / 1000).toFixed(0) + ' Gbps' : '-' }}</el-descriptions-item>
              <el-descriptions-item label="运行虚拟机">{{ host.vm_count }} 台</el-descriptions-item>
            </el-descriptions>
          </el-col>
        </el-row>
      </el-tab-pane>

      <!-- 监控 -->
      <el-tab-pane label="监控" name="monitor">
        <el-row :gutter="16">
          <el-col :span="12">
            <el-card shadow="never"><template #header>CPU使用率</template><div ref="cpuChartRef" style="height: 250px;"></div></el-card>
          </el-col>
          <el-col :span="12">
            <el-card shadow="never"><template #header>内存使用率</template><div ref="memChartRef" style="height: 250px;"></div></el-card>
          </el-col>
        </el-row>
      </el-tab-pane>

      <!-- 虚拟机 -->
      <el-tab-pane label="虚拟机列表" name="vms">
        <el-table :data="hostVMs" size="small" border stripe>
          <el-table-column prop="name" label="名称" width="160">
            <template #default="{ row }">
              <el-button link type="primary" @click="$router.push(`/vms/${row.id}`)">{{ row.name }}</el-button>
            </template>
          </el-table-column>
          <el-table-column prop="status" label="状态" width="90">
            <template #default="{ row }">
              <el-tag :type="row.status === 'running' ? 'success' : row.status === 'stopped' ? 'danger' : 'warning'" size="small">{{ statusText[row.status] || row.status }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column label="配置" width="120">
            <template #default="{ row }">{{ row.cpu }}C/{{ (row.memory/1024).toFixed(0) }}G</template>
          </el-table-column>
          <el-table-column prop="ip" label="IP" width="140" />
          <el-table-column prop="owner" label="使用者" width="100" />
          <el-table-column prop="os_version" label="操作系统" min-width="120" />
        </el-table>
      </el-tab-pane>

      <!-- 配置 -->
      <el-tab-pane label="配置" name="config">
        <el-form :model="configForm" label-width="120px" style="max-width: 500px;">
          <el-form-item label="服务器类型">
            <el-select v-model="configForm.role" style="width: 100%;">
              <el-option label="CM_VDI (管理+计算)" value="CM_VDI" />
              <el-option label="VDI (计算)" value="VDI" />
              <el-option label="CM (管理)" value="CM" />
              <el-option label="Arbiter (仲裁)" value="Arbiter" />
              <el-option label="Gateway (网关)" value="Gateway" />
            </el-select>
          </el-form-item>
          <el-form-item label="BMC地址">
            <el-input v-model="configForm.bmc_ip" />
          </el-form-item>
          <el-form-item>
            <el-button type="primary" @click="saveConfig">保存</el-button>
          </el-form-item>
        </el-form>
      </el-tab-pane>
    </el-tabs>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted, nextTick } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ArrowLeft } from '@element-plus/icons-vue'
import * as echarts from 'echarts'
import api from '../api'
import { ElMessage, ElMessageBox } from 'element-plus'

const route = useRoute()
const router = useRouter()
const loading = ref(true)
const host = ref({})
const hostVMs = ref([])
const activeTab = ref('overview')
const configForm = reactive({ role: '', bmc_ip: '' })
const cpuChartRef = ref(null)
const memChartRef = ref(null)
const statusText = { running: '运行中', stopped: '已关机', suspended: '已挂起', migrating: '迁移中' }

const cpuHistory = ref([])
const memHistory = ref([])
let chartTimer = null

function formatUptime(seconds) {
  if (!seconds) return '-'
  const d = Math.floor(seconds / 86400)
  const h = Math.floor((seconds % 86400) / 3600)
  return d > 0 ? `${d}天${h}小时` : `${h}小时`
}

async function loadData() {
  loading.value = true
  try {
    host.value = await api.get(`/hosts/${route.params.id}`)
    configForm.role = host.value.role
    configForm.bmc_ip = host.value.bmc_ip || ''
    // Load VMs on this host
    const res = await api.get('/vms', { params: { host_id: route.params.id } })
    hostVMs.value = res.data || []
  } finally { loading.value = false }
}

async function doAction(action) {
  if (action === 'shutdown') {
    await ElMessageBox.confirm(`确认关闭服务器 ${host.value.name}?`, '警告', { type: 'warning' })
  }
  await api.post(`/hosts/${route.params.id}/action`, { action })
  ElMessage.success('操作已执行')
  loadData()
}

async function saveConfig() {
  await api.put(`/hosts/${route.params.id}`, configForm)
  ElMessage.success('配置已保存')
  loadData()
}

function initMonitorCharts() {
  if (!cpuChartRef.value || !memChartRef.value) return
  const cpuChart = echarts.init(cpuChartRef.value)
  const memChart = echarts.init(memChartRef.value)
  const timeLabels = cpuHistory.value.map((_, i) => `${i * 5}s`)
  const lineOpt = (title, data, color) => ({
    tooltip: { trigger: 'axis', formatter: '{b}: {c}%' },
    grid: { top: 10, right: 20, bottom: 30, left: 50 },
    xAxis: { type: 'category', data: timeLabels, boundaryGap: false },
    yAxis: { type: 'value', min: 0, max: 100, axisLabel: { formatter: '{value}%' } },
    series: [{ type: 'line', data, smooth: true, areaStyle: { color: color + '30' }, lineStyle: { color }, itemStyle: { color } }]
  })
  cpuChart.setOption(lineOpt('CPU', cpuHistory.value, '#409eff'))
  memChart.setOption(lineOpt('内存', memHistory.value, '#67c23a'))
}

async function fetchStats() {
  try {
    const stats = await api.get(`/hosts/${route.params.id}/stats`)
    cpuHistory.value.push(+stats.cpu_usage.toFixed(1))
    memHistory.value.push(+stats.mem_usage.toFixed(1))
    if (cpuHistory.value.length > 20) { cpuHistory.value.shift(); memHistory.value.shift() }
    if (activeTab.value === 'monitor') initMonitorCharts()
  } catch(e) {}
}

onMounted(async () => {
  await loadData()
  // Pre-fill some history
  for (let i = 0; i < 10; i++) await fetchStats()
  await nextTick()
  initMonitorCharts()
  chartTimer = setInterval(fetchStats, 5000)
})

import { onUnmounted } from 'vue'
onUnmounted(() => { if (chartTimer) clearInterval(chartTimer) })
</script>
