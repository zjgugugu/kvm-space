<template>
  <div class="dashboard-grid">
    <!-- 卡片1: 虚拟机使用情况 (左上) -->
    <div class="m-card card-vm">
      <div ref="vmPieRef" style="width: 100%; height: 100%;"></div>
    </div>
    <!-- 卡片2: 在线趋势图 (中上, 大卡片) -->
    <div class="m-card card-trend">
      <div class="card-header-bar">
        <div class="trend-mode">
          <span :class="{ active: trendGranularity === 'minute' }" @click="trendGranularity='minute'; loadTrends()">分</span>
          <span :class="{ active: trendGranularity === 'hour' }" @click="trendGranularity='hour'; loadTrends()">时</span>
          <span :class="{ active: trendGranularity === 'day' }" @click="trendGranularity='day'; loadTrends()">天</span>
        </div>
      </div>
      <div ref="trendChartRef" style="width: 100%; height: calc(100% - 10px);"></div>
    </div>
    <!-- 卡片3: 用户在线情况 (右上) -->
    <div class="m-card card-user-stats">
      <div class="card-title"><i class="dot"></i>用户在线情况</div>
      <table class="stats-table">
        <tbody>
          <tr><td>用户总数</td><td>{{ userStats.data?.totalUserNum || 0 }} 人</td></tr>
          <tr><td><i class="dot green"></i>在线用户数</td><td>{{ userStats.data?.onlineUserNum || 0 }} 人</td></tr>
          <tr><td><i class="dot yellow"></i>当月登录用户总数</td><td>{{ userStats.data?.monthUserNum || 0 }} 人</td></tr>
          <tr><td><i class="dot blue"></i>当年登录用户总数</td><td>{{ userStats.data?.yearUserNum || 0 }} 人</td></tr>
        </tbody>
      </table>
    </div>
    <!-- 卡片4.1: 服务器统计 (中左) -->
    <div class="m-card card-server-stats">
      <div class="card-title"><i class="dot"></i>服务器</div>
      <div class="server-grid">
        <div class="server-box">
          <h3>在线</h3>
          <p class="num green">{{ overview.server?.online ?? 0 }}台</p>
        </div>
        <div class="server-box">
          <h3>离线</h3>
          <p class="num red">{{ overview.server?.offline ?? 0 }}台</p>
        </div>
      </div>
    </div>
    <!-- 卡片4.2: 终端系统类型 (中右) -->
    <div class="m-card card-system-type">
      <div ref="systemTypeRef" style="width: 100%; height: 100%;"></div>
    </div>
    <!-- 卡片5.1: 集群资源使用情况 (中左) -->
    <div class="m-card card-resource">
      <div ref="resourceRef" style="width: 100%; height: 100%;"></div>
    </div>
    <!-- 卡片5.2: 告警 (中右) -->
    <div class="m-card card-warn">
      <div class="card-title">
        <i class="dot"></i>警告
        <span class="warn-legend"><i class="dot-sm pink"></i>紧急 <i class="dot-sm orange"></i>重要</span>
      </div>
      <table class="warn-table">
        <thead>
          <tr><th style="width:25%">告警时间</th><th style="width:55%">告警详情</th><th style="width:20%">告警等级</th></tr>
        </thead>
        <tbody>
          <tr v-for="a in (recentAlerts.rows || [])" :key="a.id">
            <td>{{ a.cell.date }}</td>
            <td class="ellipsis">{{ a.cell.info }}</td>
            <td><span :class="'level-' + (a.cell.severity === '紧急' ? 'critical' : a.cell.severity === '严重' ? 'warning' : 'info')">{{ a.cell.severity }}</span></td>
          </tr>
          <tr v-if="!(recentAlerts.rows || []).length"><td></td><td style="color:#5a7089;">当前无警告数据</td><td></td></tr>
        </tbody>
      </table>
    </div>
    <!-- 卡片6: 用户在线时长排序 (右下) -->
    <div class="m-card card-user-ranking">
      <div class="card-title"><i class="dot"></i>用户在线时长排序（单位/小时）</div>
      <table class="ranking-table">
        <thead>
          <tr><th style="width:30%">用户</th><th style="width:40%">虚拟机</th><th style="width:30%">当月</th></tr>
        </thead>
        <tbody>
          <tr v-for="u in (userRanking.rows || [])" :key="u.cell.username">
            <td class="ellipsis">{{ u.cell.username }}</td>
            <td class="ellipsis">{{ u.cell.desktopName || '-' }}</td>
            <td>{{ u.cell.total?.toFixed(2) || '0.00' }}</td>
          </tr>
          <tr v-if="!(userRanking.rows || []).length"><td colspan="3" style="text-align:center;color:#5a7089;">暂无数据</td></tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted, nextTick } from 'vue'
import * as echarts from 'echarts'
import api from '../api'

const overview = ref({})
const userStats = ref({})
const userRanking = ref({})
const recentAlerts = ref({})
const trendGranularity = ref('minute')

const vmPieRef = ref(null)
const trendChartRef = ref(null)
const systemTypeRef = ref(null)
const resourceRef = ref(null)
const chartInstances = []
let refreshTimer = null

// ===== 虚拟机饼图 =====
function initVmPie() {
  if (!vmPieRef.value) return
  const chart = echarts.init(vmPieRef.value)
  chartInstances.push(chart)
  const vm = overview.value.vm || {}
  const desktopTotal = (vm.connected || 0) + (vm.disConnected || 0)
  chart.setOption({
    title: {
      left: '7%', top: '7%',
      text: ['{a|}', '{b|虚拟机使用情况}'].join(''),
      textStyle: { rich: { a: { borderRadius: 100, backgroundColor: '#2ea7e0', width: 7, height: 7 }, b: { color: '#fff', fontSize: 14, padding: [0,0,0,8] } } }
    },
    tooltip: { trigger: 'item', formatter: '{a} <br/>{b} : {c} ({d}%)' },
    legend: {
      bottom: '8%', itemWidth: 11, itemHeight: 11, itemGap: 40,
      textStyle: { color: '#fff' },
      data: ['运行', '未运行', '异常']
    },
    series: [{
      name: '云桌面', type: 'pie', radius: ['35%', '55%'], center: ['30%', '50%'],
      label: { show: false },
      labelLine: { show: false },
      itemStyle: { borderWidth: 2, borderColor: '#0c1530' },
      data: [
        { value: vm.connected || 0, name: '运行', itemStyle: { color: '#00c6ff' } },
        { value: vm.disConnected || 0, name: '未运行', itemStyle: { color: '#3f5170' } },
      ]
    }, {
      name: '云服务器', type: 'pie', radius: ['35%', '55%'], center: ['73%', '50%'],
      label: { show: false },
      labelLine: { show: false },
      itemStyle: { borderWidth: 2, borderColor: '#0c1530' },
      data: [
        { value: vm.isRunning || 0, name: '运行', itemStyle: { color: '#00c6ff' } },
        { value: vm.unRun || 0, name: '未运行', itemStyle: { color: '#3f5170' } },
      ]
    }],
    graphic: [{
      type: 'text', left: '22%', top: '44%', style: { text: (vm.connected || 0) + '/' + desktopTotal, fill: '#fff', fontSize: 16, fontWeight: 700, textAlign: 'center' }
    }, {
      type: 'text', left: '24%', top: '54%', style: { text: '云桌面', fill: '#fff', fontSize: 12, textAlign: 'center' }
    }, {
      type: 'text', left: '67%', top: '44%', style: { text: (vm.isRunning || 0) + '/' + (vm.servertotal || 0), fill: '#fff', fontSize: 16, fontWeight: 700, textAlign: 'center' }
    }, {
      type: 'text', left: '67%', top: '54%', style: { text: '云服务器', fill: '#fff', fontSize: 12, textAlign: 'center' }
    }]
  })
}

// ===== 在线趋势图 =====
function initTrendChart() {
  if (!trendChartRef.value) return
  const chart = echarts.init(trendChartRef.value)
  chartInstances.push(chart)

  const granularityParam = trendGranularity.value === 'minute' ? 'MINUTE' : trendGranularity.value === 'hour' ? 'HOUR' : 'DAY'
  api.get('/dashboard/trends', { params: { granularity: granularityParam } }).then(resp => {
    const lines = resp.chart?.lines || []
    const dataTypeMap = resp.dataTypeMap || {}

    // dataType → legend name mapping
    const nameMap = {
      ONLINE_USER_COUNT: '用户', ONLINE_CLINET_COUNT: '终端',
      SESSION_COUNT: '会话', SERVER_VIRTUAL_SESSION_COUNT: '云服务器',
      CONNECTED_SESSION_COUNT: '云桌面'
    }
    const colorMap = {
      SESSION_COUNT: '#409eff', CONNECTED_SESSION_COUNT: '#67c23a',
      SERVER_VIRTUAL_SESSION_COUNT: '#e6a23c', ONLINE_CLINET_COUNT: '#909399',
      ONLINE_USER_COUNT: '#f56c6c'
    }

    // Extract labels from first line's timestamps
    const firstLine = lines[0]
    const labels = firstLine ? firstLine.values.map(v => {
      const d = new Date(v[0])
      return granularityParam === 'DAY'
        ? `${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}`
        : `${String(d.getHours()).padStart(2,'0')}:${String(d.getMinutes()).padStart(2,'0')}`
    }) : []

    const lineStyle = (color) => ({ width: 2, color })
    const areaStyle = (color) => ({
      color: new echarts.graphic.LinearGradient(0, 0, 0, 1, [
        { offset: 0, color: color + '60' }, { offset: 1, color: color + '05' }
      ])
    })

    // Build series
    const legendData = []
    const series = lines.map(line => {
      const dt = line.lineQuery?.dataType?.name || ''
      const name = nameMap[dt] || dataTypeMap[dt] || dt
      const color = colorMap[dt] || '#999'
      legendData.push(name)
      const s = { name, type: 'line', data: line.values.map(v => v[1]), smooth: true, symbol: 'none', lineStyle: lineStyle(color) }
      if (['SESSION_COUNT', 'CONNECTED_SESSION_COUNT', 'ONLINE_USER_COUNT'].includes(dt)) s.areaStyle = areaStyle(color)
      return s
    })

    chart.setOption({
      title: {
        left: '3%', top: '6%',
        text: ['{a|}', '{b|在线趋势图}'].join(''),
        textStyle: { rich: { a: { borderRadius: 100, backgroundColor: '#2ea7e0', width: 7, height: 7 }, b: { color: '#fff', fontSize: 14, padding: [0,0,0,8] } } }
      },
      tooltip: { trigger: 'axis', axisPointer: { lineStyle: { color: '#57617B' } } },
      legend: {
        top: '7%', right: '15%', itemWidth: 20, itemHeight: 4, itemGap: 34, icon: 'roundRect',
        data: legendData,
        textStyle: { color: '#fff', padding: [4,0,0,10] }
      },
      grid: { bottom: '14%', top: '25%', left: '8%', right: '5%' },
      xAxis: [{
        type: 'category', data: labels, boundaryGap: false,
        axisLine: { lineStyle: { color: 'rgba(66,151,251,0.3)' } },
        axisTick: { show: false },
        axisLabel: { color: '#fff', margin: 14 },
        splitLine: { show: false }
      }],
      yAxis: [{
        type: 'value', axisTick: { show: false }, axisLine: { show: false },
        axisLabel: { color: '#fff', margin: 48 },
        splitLine: { lineStyle: { color: 'rgba(66,151,251,0.15)' } }
      }],
      series
    })
  }).catch(() => {})
}

// ===== 终端系统类型 =====
function initSystemType() {
  if (!systemTypeRef.value) return
  const chart = echarts.init(systemTypeRef.value)
  chartInstances.push(chart)
  const st = overview.value.systemType || {}
  const label = { show: true, fontSize: 12, color: '#fff', position: 'top' }
  chart.setOption({
    title: {
      left: '7%', top: '7%',
      text: ['{a|}', '{b|终端}'].join(''),
      textStyle: { rich: { a: { borderRadius: 100, backgroundColor: '#2ea7e0', width: 7, height: 7 }, b: { color: '#fff', fontSize: 14, padding: [0,0,0,8] } } }
    },
    legend: {
      bottom: '10%', itemWidth: 11, itemHeight: 11, itemGap: 48,
      textStyle: { color: '#fff' },
      data: ['VDE', 'PC', 'TC']
    },
    grid: { bottom: '30%', top: '25%', left: '12%', right: '9%' },
    xAxis: [{ type: 'category', data: ['VDE', 'PC', 'TC'], axisLabel: { show: false }, axisLine: { lineStyle: { color: '#439aff' } }, axisTick: { show: false } }],
    yAxis: [{ type: 'value', axisLine: { lineStyle: { color: '#439aff' } }, axisLabel: { color: '#fff' }, splitLine: { lineStyle: { color: 'rgba(66,151,251,0.15)' } } }],
    series: [
      { name: 'VDE', type: 'bar', data: [st.vde || 0], barWidth: 20, label, itemStyle: { color: new echarts.graphic.LinearGradient(0,0,0,1,[{offset:0,color:'#00c6ff'},{offset:1,color:'#0072ff'}]) } },
      { name: 'PC', type: 'bar', data: [st.normal || 0], barWidth: 20, label, itemStyle: { color: new echarts.graphic.LinearGradient(0,0,0,1,[{offset:0,color:'#f7971e'},{offset:1,color:'#ffd200'}]) } },
      { name: 'TC', type: 'bar', data: [st.tc || 0], barWidth: 20, label, itemStyle: { color: new echarts.graphic.LinearGradient(0,0,0,1,[{offset:0,color:'#c471ed'},{offset:1,color:'#f64f59'}]) } },
    ]
  })
}

// ===== 集群资源使用情况 =====
function initResource() {
  if (!resourceRef.value) return
  const chart = echarts.init(resourceRef.value)
  chartInstances.push(chart)
  const cpu = overview.value.cpu || {}
  const mem = overview.value.mem || {}
  const sto = overview.value.storage || {}

  function getText(pct) {
    return ['{a|' + (pct || 0).toFixed(0) + '}{b|%}'].join('')
  }
  function getColor(pct) {
    if (pct > 80) return '#f56c6c'
    if (pct > 60) return '#e6a23c'
    return '#67c23a'
  }
  function pieData(used, notUsed, color) {
    return [
      { value: used || 0, name: '已使用', itemStyle: { color } },
      { value: notUsed || 0, name: '未使用', itemStyle: { color: '#1a2744' } }
    ]
  }
  const cpuPct = cpu.total ? +(cpu.used / cpu.total * 100).toFixed(1) : 0
  const memPct = mem.total ? +(mem.used / mem.total * 100).toFixed(1) : 0
  const stoPct = sto.total ? +(sto.used / sto.total * 100).toFixed(1) : 0

  chart.setOption({
    title: [
      { left: '3%', top: '8%', text: ['{a|}', '{b|集群资源使用情况}'].join(''), textStyle: { rich: { a: { borderRadius: 100, backgroundColor: '#2ea7e0', width: 7, height: 7 }, b: { color: '#fff', fontSize: 14, padding: [0,0,0,8] } } } },
      { left: '17%', top: '50%', text: getText(cpuPct), subtext: 'CPU', textAlign: 'center', subtextStyle: { fontSize: 12, color: '#fff', lineHeight: 18 }, itemGap: 2, textStyle: { color: '#fff', rich: { a: { fontSize: 20 }, b: { fontSize: 10 } } } },
      { left: '50%', top: '50%', text: getText(memPct), subtext: '内存', textAlign: 'center', subtextStyle: { fontSize: 12, color: '#fff', lineHeight: 18 }, itemGap: 2, textStyle: { color: '#fff', rich: { a: { fontSize: 20 }, b: { fontSize: 10 } } } },
      { left: '82%', top: '50%', text: getText(stoPct), subtext: '存储', textAlign: 'center', subtextStyle: { fontSize: 12, color: '#fff', lineHeight: 18 }, itemGap: 2, textStyle: { color: '#fff', rich: { a: { fontSize: 20 }, b: { fontSize: 10 } } } },
    ],
    tooltip: { show: true, trigger: 'item', formatter: (d) => d.seriesName + '<br/>' + d.name + ': ' + d.value + ' (' + d.percent + '%)' },
    legend: {
      bottom: '5%', itemWidth: 11, itemHeight: 11, itemGap: 60,
      textStyle: { color: '#fff' },
      data: ['已使用', '未使用']
    },
    series: [
      { name: 'CPU', type: 'pie', radius: ['30%', '45%'], center: ['17%', '42%'], label: { show: false }, itemStyle: { borderWidth: 1, borderColor: '#0c1530' }, data: pieData(cpu.used, (cpu.total||0) - (cpu.used||0), getColor(cpuPct)) },
      { name: '内存', type: 'pie', radius: ['30%', '45%'], center: ['50%', '42%'], label: { show: false }, itemStyle: { borderWidth: 1, borderColor: '#0c1530' }, data: pieData(mem.used, (mem.total||0) - (mem.used||0), getColor(memPct)) },
      { name: '存储', type: 'pie', radius: ['30%', '45%'], center: ['82%', '42%'], label: { show: false }, itemStyle: { borderWidth: 1, borderColor: '#0c1530' }, data: pieData(sto.used, (sto.total||0) - (sto.used||0), getColor(stoPct)) },
    ]
  })
}

function loadTrends() {
  // 销毁旧趋势图重新绘制
  const idx = chartInstances.findIndex(c => c.getDom() === trendChartRef.value)
  if (idx >= 0) { chartInstances[idx].dispose(); chartInstances.splice(idx, 1) }
  initTrendChart()
}

async function loadDashboard() {
  const results = await Promise.allSettled([
    api.get('/dashboard/overview'),
    api.get('/dashboard/user-stats'),
    api.get('/dashboard/user-ranking'),
    api.get('/dashboard/recent-alerts'),
  ])
  if (results[0].status === 'fulfilled') overview.value = results[0].value
  if (results[1].status === 'fulfilled') userStats.value = results[1].value
  if (results[2].status === 'fulfilled') userRanking.value = results[2].value
  if (results[3].status === 'fulfilled') recentAlerts.value = results[3].value
}

function initAllCharts() {
  initVmPie()
  initTrendChart()
  initSystemType()
  initResource()
}

function handleResize() {
  chartInstances.forEach(c => c.resize())
}

onMounted(async () => {
  await loadDashboard()
  await nextTick()
  initAllCharts()
  window.addEventListener('resize', handleResize)
  refreshTimer = setInterval(async () => {
    await loadDashboard()
    await nextTick()
    // Update charts with new data
    initVmPie()
    initResource()
  }, 30000)
})

onUnmounted(() => {
  window.removeEventListener('resize', handleResize)
  if (refreshTimer) clearInterval(refreshTimer)
  chartInstances.forEach(c => c.dispose())
  chartInstances.length = 0
})
</script>

<style scoped>
/* ===== 深色大屏仪表板 ===== */
.dashboard-grid {
  display: grid;
  grid-template-columns: 1fr 2fr 1fr;
  grid-template-rows: auto auto auto;
  gap: 12px;
  min-height: calc(100vh - 80px);
  color: #fff;
}

.m-card {
  background: linear-gradient(135deg, rgba(16, 28, 52, 0.9) 0%, rgba(12, 21, 48, 0.95) 100%);
  border: 1px solid rgba(66, 151, 251, 0.2);
  border-radius: 6px;
  overflow: hidden;
}

/* 第1行: VM饼图 | 趋势图 | 用户统计 */
.card-vm { grid-column: 1; grid-row: 1; min-height: 280px; }
.card-trend { grid-column: 2; grid-row: 1; min-height: 280px; }
.card-user-stats { grid-column: 3; grid-row: 1; padding: 14px 20px; }

/* 第2行: 服务器统计+终端 | 资源+告警 */
.card-server-stats { grid-column: 1; grid-row: 2; padding: 14px 20px; min-height: 200px; }
.card-system-type { grid-column: 1; grid-row: 3; min-height: 240px; }
.card-resource { grid-column: 2; grid-row: 2; min-height: 200px; }
.card-warn { grid-column: 2; grid-row: 3; padding: 14px 20px; min-height: 240px; }

/* 第3列: 用户排名 */
.card-user-ranking { grid-column: 3; grid-row: 2 / 4; padding: 14px 20px; }

/* ===== 卡片标题 ===== */
.card-title {
  font-size: 14px;
  color: #fff;
  margin-bottom: 14px;
  display: flex;
  align-items: center;
  gap: 8px;
}

.dot {
  display: inline-block;
  width: 7px;
  height: 7px;
  border-radius: 50%;
  background: #2ea7e0;
}

.dot.green { background: #67c23a; }
.dot.yellow { background: #e6a23c; }
.dot.blue { background: #409eff; }

.dot-sm {
  display: inline-block;
  width: 7px;
  height: 7px;
  border-radius: 50%;
  margin-right: 4px;
}

.dot-sm.pink { background: #f56c6c; }
.dot-sm.orange { background: #e6a23c; }

.warn-legend {
  margin-left: auto;
  font-size: 12px;
  color: #8ba7c7;
}

/* ===== 趋势图顶部模式切换 ===== */
.card-header-bar {
  position: absolute;
  top: 8px;
  right: 8px;
  z-index: 10;
}

.card-trend {
  position: relative;
}

.trend-mode {
  display: flex;
  gap: 2px;
  background: rgba(66,151,251,0.15);
  border-radius: 4px;
  padding: 2px;
}

.trend-mode span {
  padding: 3px 12px;
  font-size: 12px;
  color: #8ba7c7;
  cursor: pointer;
  border-radius: 3px;
  transition: all 0.2s;
}

.trend-mode span.active, .trend-mode span:hover {
  background: #4297fb;
  color: #fff;
}

/* ===== 用户统计表 ===== */
.stats-table {
  width: 100%;
  border-collapse: collapse;
}

.stats-table td {
  padding: 10px 4px;
  font-size: 13px;
  color: #b8c7db;
  border-bottom: 1px solid rgba(66,151,251,0.1);
}

.stats-table td:last-child {
  text-align: right;
  color: #fff;
}

/* ===== 服务器统计 ===== */
.server-grid {
  display: flex;
  justify-content: space-around;
  padding: 16px 0;
}

.server-box {
  text-align: center;
}

.server-box h3 {
  font-size: 14px;
  color: #8ba7c7;
  margin-bottom: 8px;
}

.server-box .num {
  font-size: 28px;
  font-weight: 700;
}

.num.green { color: #67c23a; }
.num.red { color: #f56c6c; }

/* ===== 告警表 ===== */
.warn-table, .ranking-table {
  width: 100%;
  border-collapse: collapse;
  font-size: 12px;
}

.warn-table thead th, .ranking-table thead th {
  background: rgba(66,151,251,0.1);
  padding: 6px 8px;
  text-align: left;
  color: #8ba7c7;
  font-weight: 500;
  border-bottom: 1px solid rgba(66,151,251,0.15);
}

.warn-table tbody td, .ranking-table tbody td {
  padding: 6px 8px;
  color: #b8c7db;
  border-bottom: 1px solid rgba(255,255,255,0.04);
}

.ellipsis {
  overflow: hidden;
  white-space: nowrap;
  text-overflow: ellipsis;
  max-width: 200px;
}

.level-critical { color: #f56c6c; font-weight: 600; }
.level-warning { color: #e6a23c; }
.level-info { color: #909399; }
</style>
