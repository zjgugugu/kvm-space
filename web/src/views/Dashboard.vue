<template>
  <div>
    <!-- 顶部统计卡片 -->
    <el-row :gutter="16" style="margin-bottom: 16px;">
      <el-col :span="4" v-for="s in statCards" :key="s.label">
        <el-card shadow="hover" body-style="padding: 16px;">
          <div style="display: flex; align-items: center; gap: 12px;">
            <el-icon :size="36" :style="{ color: s.color, background: s.bg, padding: '8px', borderRadius: '8px' }"><component :is="s.icon" /></el-icon>
            <div>
              <div style="font-size: 22px; font-weight: 700; line-height: 1.2;" :style="{ color: s.color }">{{ s.value }}</div>
              <div style="font-size: 12px; color: #909399;">{{ s.label }}</div>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <el-row :gutter="16" style="margin-bottom: 16px;">
      <!-- 左侧: 虚拟机饼图 + 服务器统计 -->
      <el-col :span="8">
        <el-card shadow="hover" style="margin-bottom: 16px;">
          <template #header><span style="font-weight: 600;">虚拟机使用情况</span></template>
          <div ref="vmPieRef" style="height: 220px;"></div>
        </el-card>
        <el-card shadow="hover">
          <template #header><span style="font-weight: 600;">服务器状态</span></template>
          <div style="display: flex; justify-content: space-around; padding: 16px 0;">
            <div style="text-align: center;">
              <div style="font-size: 28px; font-weight: 700; color: #67c23a;">{{ overview.hosts?.online ?? 0 }}</div>
              <div style="color: #909399; font-size: 13px;">在线</div>
            </div>
            <el-divider direction="vertical" style="height: 50px;" />
            <div style="text-align: center;">
              <div style="font-size: 28px; font-weight: 700; color: #f56c6c;">{{ overview.hosts?.offline ?? 0 }}</div>
              <div style="color: #909399; font-size: 13px;">离线</div>
            </div>
            <el-divider direction="vertical" style="height: 50px;" />
            <div style="text-align: center;">
              <div style="font-size: 28px; font-weight: 700; color: #409eff;">{{ overview.hosts?.total ?? 0 }}</div>
              <div style="color: #909399; font-size: 13px;">总计</div>
            </div>
          </div>
        </el-card>
      </el-col>

      <!-- 中间: 集群资源使用情况 -->
      <el-col :span="8">
        <el-card shadow="hover" style="height: 100%;">
          <template #header><span style="font-weight: 600;">集群资源使用情况</span></template>
          <div style="display: flex; justify-content: space-around;">
            <div v-for="r in resources" :key="r.label" style="text-align: center; flex: 1;">
              <div ref="resourcePieRefs" style="height: 160px;"></div>
              <div style="font-size: 13px; font-weight: 600; margin-top: 4px;">{{ r.label }}</div>
              <div style="font-size: 12px; color: #909399;">{{ r.used }}/{{ r.total }}{{ r.unit }}</div>
            </div>
          </div>
          <!-- 告警信息 -->
          <el-divider />
          <div style="display: flex; align-items: center; gap: 8px;">
            <el-icon :size="18" style="color: #e6a23c;"><WarningFilled /></el-icon>
            <span style="font-size: 13px;">活跃告警: <b style="color: #f56c6c;">{{ overview.alerts?.active ?? 0 }}</b> 条</span>
            <el-button size="small" link type="primary" @click="$router.push('/alerts')">查看</el-button>
          </div>
        </el-card>
      </el-col>

      <!-- 右侧: 用户在线情况 -->
      <el-col :span="8">
        <el-card shadow="hover" style="margin-bottom: 16px;">
          <template #header><span style="font-weight: 600;">用户信息</span></template>
          <div style="display: flex; justify-content: space-around; padding: 12px 0;">
            <div style="text-align: center;">
              <div style="font-size: 28px; font-weight: 700; color: #409eff;">{{ overview.users?.total ?? 0 }}</div>
              <div style="color: #909399; font-size: 13px;">用户总数</div>
            </div>
            <el-divider direction="vertical" style="height: 50px;" />
            <div style="text-align: center;">
              <div style="font-size: 28px; font-weight: 700; color: #67c23a;">{{ overview.templates?.total ?? 0 }}</div>
              <div style="color: #909399; font-size: 13px;">黄金镜像</div>
            </div>
          </div>
        </el-card>
        <el-card shadow="hover">
          <template #header><span style="font-weight: 600;">快速操作</span></template>
          <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 10px;">
            <el-button @click="$router.push('/vms')"><el-icon><Monitor /></el-icon>虚拟机管理</el-button>
            <el-button @click="$router.push('/templates')"><el-icon><PictureFilled /></el-icon>黄金镜像</el-button>
            <el-button @click="$router.push('/hosts')"><el-icon><Platform /></el-icon>服务器管理</el-button>
            <el-button @click="$router.push('/reports')"><el-icon><DataAnalysis /></el-icon>统计报表</el-button>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 底部: 近期事件 + 近期任务 -->
    <el-row :gutter="16">
      <el-col :span="14">
        <el-card shadow="hover">
          <template #header>
            <div style="display: flex; justify-content: space-between; align-items: center;">
              <span style="font-weight: 600;">近期事件</span>
              <el-button size="small" link type="primary" @click="$router.push('/events')">查看全部</el-button>
            </div>
          </template>
          <el-table :data="overview.recent_events || []" size="small" max-height="260">
            <el-table-column prop="created_at" label="时间" width="160" />
            <el-table-column prop="message" label="事件" min-width="200" />
            <el-table-column prop="resource_name" label="资源" width="140" />
            <el-table-column prop="user" label="操作者" width="80" />
            <el-table-column prop="level" label="级别" width="70">
              <template #default="{ row }">
                <el-tag :type="row.level === 'error' ? 'danger' : row.level === 'warning' ? 'warning' : 'info'" size="small">{{ row.level }}</el-tag>
              </template>
            </el-table-column>
          </el-table>
        </el-card>
      </el-col>
      <el-col :span="10">
        <el-card shadow="hover">
          <template #header><span style="font-weight: 600;">近期任务</span></template>
          <el-table :data="overview.recent_tasks || []" size="small" max-height="260">
            <el-table-column prop="resource_name" label="任务" min-width="140" />
            <el-table-column prop="status" label="状态" width="80">
              <template #default="{ row }">
                <el-tag :type="row.status === 'completed' ? 'success' : row.status === 'failed' ? 'danger' : ''" size="small">{{ row.status === 'completed' ? '完成' : row.status === 'failed' ? '失败' : '进行中' }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="message" label="详情" min-width="160" show-overflow-tooltip />
          </el-table>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, nextTick } from 'vue'
import * as echarts from 'echarts'
import api from '../api'

const overview = ref({})
const vmPieRef = ref(null)
const resourcePieRefs = ref([])

const statCards = computed(() => {
  const o = overview.value
  return [
    { label: '服务器总数', value: o.hosts?.total ?? '-', color: '#409eff', bg: '#ecf5ff', icon: 'Platform' },
    { label: '在线服务器', value: o.hosts?.online ?? '-', color: '#67c23a', bg: '#f0f9eb', icon: 'CircleCheck' },
    { label: '虚拟机总数', value: o.vms?.total ?? '-', color: '#409eff', bg: '#ecf5ff', icon: 'Monitor' },
    { label: '运行中', value: o.vms?.running ?? '-', color: '#67c23a', bg: '#f0f9eb', icon: 'VideoPlay' },
    { label: '已关机', value: o.vms?.stopped ?? '-', color: '#909399', bg: '#f4f4f5', icon: 'SwitchButton' },
    { label: '活跃告警', value: o.alerts?.active ?? '-', color: '#f56c6c', bg: '#fef0f0', icon: 'Bell' },
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

function initCharts() {
  // VM状态饼图
  if (vmPieRef.value) {
    const chart = echarts.init(vmPieRef.value)
    const vms = overview.value.vms || {}
    chart.setOption({
      tooltip: { trigger: 'item', formatter: '{b}: {c} ({d}%)' },
      legend: { bottom: 0, itemWidth: 10, itemHeight: 10, textStyle: { fontSize: 12 } },
      series: [{
        type: 'pie', radius: ['40%', '65%'], center: ['50%', '45%'],
        label: { show: false },
        data: [
          { value: vms.running || 0, name: '运行中', itemStyle: { color: '#67c23a' } },
          { value: vms.stopped || 0, name: '已关机', itemStyle: { color: '#909399' } },
          { value: vms.suspended || 0, name: '已挂起', itemStyle: { color: '#e6a23c' } },
        ].filter(d => d.value > 0)
      }]
    })
  }

  // 资源使用率环形图
  const colors = ['#409eff', '#67c23a', '#e6a23c']
  const els = document.querySelectorAll('[style*="height: 160px"]')
  resources.value.forEach((r, i) => {
    if (els[i]) {
      const chart = echarts.init(els[i])
      chart.setOption({
        series: [{
          type: 'gauge', startAngle: 90, endAngle: -270, radius: '90%', center: ['50%', '50%'],
          pointer: { show: false },
          progress: { show: true, overlap: false, roundCap: true, clip: false, width: 12,
            itemStyle: { color: r.usage > 80 ? '#f56c6c' : r.usage > 60 ? '#e6a23c' : colors[i] }
          },
          axisLine: { lineStyle: { width: 12, color: [[1, '#e4e7ed']] } },
          splitLine: { show: false }, axisTick: { show: false }, axisLabel: { show: false },
          title: { show: false },
          detail: { fontSize: 18, fontWeight: 700, offsetCenter: [0, 0], formatter: '{value}%',
            color: r.usage > 80 ? '#f56c6c' : r.usage > 60 ? '#e6a23c' : colors[i]
          },
          data: [{ value: r.usage }]
        }]
      })
    }
  })
}

onMounted(async () => {
  overview.value = await api.get('/dashboard/overview')
  await nextTick()
  initCharts()
})
</script>
