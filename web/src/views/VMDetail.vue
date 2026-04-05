<template>
  <div v-loading="loading">
    <div class="page-header">
      <h2>{{ vm.name || '虚拟机详情' }}</h2>
      <div style="display: flex; gap: 8px;">
        <el-button type="success" v-if="vm.status==='running'" @click="openConsole"><el-icon><Monitor /></el-icon>远程连接</el-button>
        <el-button @click="openEditConfig"><el-icon><Setting /></el-icon>修改配置</el-button>
        <el-button @click="$router.push('/vms')">返回列表</el-button>
      </div>
    </div>

    <!-- 基本信息 -->
    <el-row :gutter="16" style="margin-bottom: 16px;">
      <el-col :span="16">
        <el-card shadow="hover">
          <template #header><span style="font-weight: 600;">基本信息</span></template>
          <el-descriptions :column="3" border size="small">
            <el-descriptions-item label="名称">{{ vm.name }}</el-descriptions-item>
            <el-descriptions-item label="状态">
              <el-tag :type="statusType(vm.status)" size="small">{{ statusText(vm.status) }}</el-tag>
            </el-descriptions-item>
            <el-descriptions-item label="操作系统">{{ vm.os_version }}</el-descriptions-item>
            <el-descriptions-item label="CPU">{{ vm.cpu }} 核 (最大 {{ vm.max_cpu }})</el-descriptions-item>
            <el-descriptions-item label="内存">{{ (vm.memory/1024).toFixed(0) }} GB (最大 {{ (vm.max_memory/1024).toFixed(0) }})</el-descriptions-item>
            <el-descriptions-item label="系统盘">{{ vm.disk }} GB</el-descriptions-item>
            <el-descriptions-item label="IP">{{ vm.ip }}</el-descriptions-item>
            <el-descriptions-item label="MAC">{{ vm.mac }}</el-descriptions-item>
            <el-descriptions-item label="VNC端口">{{ vm.vnc_port || '-' }}</el-descriptions-item>
            <el-descriptions-item label="所在主机">{{ vm.host_name }}</el-descriptions-item>
            <el-descriptions-item label="使用者">{{ vm.owner }}</el-descriptions-item>
            <el-descriptions-item label="创建时间">{{ vm.created_at }}</el-descriptions-item>
            <el-descriptions-item label="CPU模式">{{ vm.cpu_mode || '-' }}</el-descriptions-item>
            <el-descriptions-item label="BIOS">{{ vm.bios_type || '-' }}</el-descriptions-item>
            <el-descriptions-item label="显卡">{{ vm.video_type || '-' }} ({{ vm.video_ram || 0 }}MB)</el-descriptions-item>
            <el-descriptions-item label="启动顺序">{{ vm.boot_order || '-' }}</el-descriptions-item>
            <el-descriptions-item label="HA高可用">
              <el-tag :type="vm.ha_enabled ? 'success' : 'info'" size="small">{{ vm.ha_enabled ? '已启用' : '未启用' }}</el-tag>
            </el-descriptions-item>
            <el-descriptions-item label="磁盘缓存">{{ vm.disk_cache || '-' }}</el-descriptions-item>
          </el-descriptions>
        </el-card>
      </el-col>
      <el-col :span="8">
        <el-card shadow="hover">
          <template #header><span style="font-weight: 600;">快捷操作</span></template>
          <div style="display: flex; flex-wrap: wrap; gap: 8px;">
            <el-button v-if="vm.status==='stopped'" type="success" @click="action('start')">开机</el-button>
            <el-button v-if="vm.status==='running'" type="warning" @click="action('stop')">关机</el-button>
            <el-button v-if="vm.status==='running'" @click="action('reboot')">重启</el-button>
            <el-button v-if="vm.status==='running'" @click="action('suspend')">挂起</el-button>
            <el-button v-if="vm.status==='suspended'" @click="action('resume')">唤醒</el-button>
            <el-button @click="action('force_stop')">强制关机</el-button>
            <el-button type="primary" @click="action('migrate')">迁移</el-button>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 磁盘、网卡、快照、监控、事件 标签页 -->
    <el-card shadow="hover">
      <el-tabs v-model="activeTab">
        <!-- 磁盘 -->
        <el-tab-pane label="磁盘" name="disks">
          <el-button size="small" type="primary" @click="addDiskVisible=true" style="margin-bottom: 10px;"><el-icon><Plus /></el-icon>添加磁盘</el-button>
          <el-table :data="vm.disks || []" border size="small">
            <el-table-column prop="name" label="名称" width="150" />
            <el-table-column prop="size" label="大小(GB)" width="100" />
            <el-table-column prop="type" label="类型" width="100" />
            <el-table-column prop="bus" label="总线" width="100" />
            <el-table-column prop="cache" label="缓存" width="90" />
            <el-table-column label="操作" width="100">
              <template #default="{ row }">
                <el-button size="small" type="danger" @click="removeDisk(row)">移除</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>

        <!-- 网卡 -->
        <el-tab-pane label="网卡" name="nics">
          <el-button size="small" type="primary" @click="addNicVisible=true" style="margin-bottom: 10px;"><el-icon><Plus /></el-icon>添加网卡</el-button>
          <el-table :data="vm.nics || []" border size="small">
            <el-table-column prop="name" label="名称" width="150" />
            <el-table-column prop="mac" label="MAC" width="160" />
            <el-table-column prop="network_name" label="网络" width="140" />
            <el-table-column prop="model" label="型号" width="100" />
            <el-table-column label="操作" width="100">
              <template #default="{ row }">
                <el-button size="small" type="danger" @click="removeNic(row)">移除</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>

        <!-- 快照 -->
        <el-tab-pane label="快照" name="snapshots">
          <el-button size="small" type="primary" @click="createSnap" style="margin-bottom: 10px;"><el-icon><Plus /></el-icon>创建快照</el-button>
          <el-table :data="snapshots" border size="small">
            <el-table-column prop="name" label="名称" width="160" />
            <el-table-column prop="description" label="描述" min-width="180" />
            <el-table-column prop="created_at" label="创建时间" width="155" />
            <el-table-column label="操作" width="160">
              <template #default="{ row }">
                <el-button size="small" type="primary" @click="revertSnap(row)">恢复</el-button>
                <el-button size="small" type="danger" @click="deleteSnap(row)">删除</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>

        <!-- 监控 -->
        <el-tab-pane label="监控" name="monitor">
          <el-row :gutter="16">
            <el-col :span="12"><div ref="cpuChartRef" style="height: 280px;"></div></el-col>
            <el-col :span="12"><div ref="memChartRef" style="height: 280px;"></div></el-col>
          </el-row>
          <el-row :gutter="16" style="margin-top: 12px;">
            <el-col :span="12"><div ref="diskIoRef" style="height: 280px;"></div></el-col>
            <el-col :span="12"><div ref="netIoRef" style="height: 280px;"></div></el-col>
          </el-row>
        </el-tab-pane>

        <!-- 事件 -->
        <el-tab-pane label="事件日志" name="events">
          <el-table :data="vmEvents" border stripe size="small">
            <el-table-column prop="created_at" label="时间" width="155" />
            <el-table-column prop="type" label="事件类型" width="100">
              <template #default="{ row }"><el-tag size="small">{{ row.type }}</el-tag></template>
            </el-table-column>
            <el-table-column prop="message" label="描述" min-width="200" />
            <el-table-column prop="operator" label="操作人" width="100" />
            <el-table-column prop="result" label="结果" width="80">
              <template #default="{ row }"><el-tag :type="row.result==='success'?'success':'danger'" size="small">{{ row.result==='success'?'成功':'失败' }}</el-tag></template>
            </el-table-column>
          </el-table>
        </el-tab-pane>
      </el-tabs>
    </el-card>

    <!-- 添加磁盘 -->
    <el-dialog v-model="addDiskVisible" title="添加磁盘" width="400px">
      <el-form :model="diskForm" label-width="80px">
        <el-form-item label="大小(GB)"><el-input-number v-model="diskForm.size" :min="1" :max="2048" /></el-form-item>
        <el-form-item label="类型">
          <el-select v-model="diskForm.type"><el-option label="数据盘" value="data" /><el-option label="系统盘" value="system" /></el-select>
        </el-form-item>
        <el-form-item label="缓存">
          <el-select v-model="diskForm.cache"><el-option label="none" value="none" /><el-option label="writethrough" value="writethrough" /><el-option label="writeback" value="writeback" /></el-select>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="addDiskVisible=false">取消</el-button>
        <el-button type="primary" @click="doAddDisk">确定</el-button>
      </template>
    </el-dialog>

    <!-- 添加网卡 -->
    <el-dialog v-model="addNicVisible" title="添加网卡" width="400px">
      <el-form :model="nicForm" label-width="80px">
        <el-form-item label="网络">
          <el-select v-model="nicForm.network_id" style="width: 100%;">
            <el-option v-for="n in networkList" :key="n.id" :label="n.name" :value="n.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="型号">
          <el-select v-model="nicForm.model" style="width: 100%;">
            <el-option label="virtio" value="virtio" /><el-option label="e1000" value="e1000" /><el-option label="rtl8139" value="rtl8139" />
          </el-select>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="addNicVisible=false">取消</el-button>
        <el-button type="primary" @click="doAddNic">确定</el-button>
      </template>
    </el-dialog>

    <!-- 修改配置 -->
    <el-dialog v-model="editConfigVisible" title="修改虚拟机配置" width="600px">
      <el-alert type="warning" :closable="false" style="margin-bottom: 12px;">修改CPU/内存需要关机后生效</el-alert>
      <el-form :model="configForm" label-width="110px">
        <el-row :gutter="16">
          <el-col :span="12"><el-form-item label="CPU(核)"><el-input-number v-model="configForm.cpu" :min="1" :max="64" style="width: 100%;" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="内存(MB)"><el-input-number v-model="configForm.memory" :min="512" :step="512" style="width: 100%;" /></el-form-item></el-col>
        </el-row>
        <el-row :gutter="16">
          <el-col :span="12"><el-form-item label="最大CPU"><el-input-number v-model="configForm.max_cpu" :min="configForm.cpu" :max="128" style="width: 100%;" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="最大内存(MB)"><el-input-number v-model="configForm.max_memory" :min="configForm.memory" :step="1024" style="width: 100%;" /></el-form-item></el-col>
        </el-row>
        <el-form-item label="使用者"><el-input v-model="configForm.owner" /></el-form-item>
        <el-form-item label="描述"><el-input v-model="configForm.description" type="textarea" :rows="2" /></el-form-item>
        <el-divider content-position="left">高级配置</el-divider>
        <el-row :gutter="16">
          <el-col :span="12">
            <el-form-item label="CPU模式">
              <el-select v-model="configForm.cpu_mode" style="width: 100%;">
                <el-option label="host-passthrough" value="host-passthrough" />
                <el-option label="host-model" value="host-model" />
                <el-option label="custom" value="custom" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="BIOS类型">
              <el-select v-model="configForm.bios_type" style="width: 100%;">
                <el-option label="SeaBIOS" value="seabios" /><el-option label="UEFI" value="uefi" />
              </el-select>
            </el-form-item>
          </el-col>
        </el-row>
        <el-row :gutter="16">
          <el-col :span="12">
            <el-form-item label="显卡类型">
              <el-select v-model="configForm.video_type" style="width: 100%;">
                <el-option label="QXL" value="qxl" /><el-option label="VGA" value="vga" /><el-option label="Virtio" value="virtio" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12"><el-form-item label="显存(MB)"><el-input-number v-model="configForm.video_ram" :min="8" :max="256" style="width: 100%;" /></el-form-item></el-col>
        </el-row>
        <el-row :gutter="16">
          <el-col :span="8"><el-form-item label="CPU热添加"><el-switch v-model="configForm.cpu_hotplug" /></el-form-item></el-col>
          <el-col :span="8"><el-form-item label="内存热添加"><el-switch v-model="configForm.mem_hotplug" /></el-form-item></el-col>
          <el-col :span="8"><el-form-item label="大页内存"><el-switch v-model="configForm.hugepages" /></el-form-item></el-col>
        </el-row>
        <el-row :gutter="16">
          <el-col :span="8"><el-form-item label="HA高可用"><el-switch v-model="configForm.ha_enabled" /></el-form-item></el-col>
          <el-col :span="16"><el-form-item label="启动顺序"><el-input v-model="configForm.boot_order" placeholder="hd,cdrom,network" /></el-form-item></el-col>
        </el-row>
        <el-form-item label="磁盘缓存">
          <el-select v-model="configForm.disk_cache" style="width: 100%;">
            <el-option label="none" value="none" /><el-option label="writethrough" value="writethrough" /><el-option label="writeback" value="writeback" />
          </el-select>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="editConfigVisible = false">取消</el-button>
        <el-button type="primary" @click="saveConfig">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted, nextTick, watch } from 'vue'
import { useRoute } from 'vue-router'
import api from '../api'
import { ElMessage, ElMessageBox } from 'element-plus'
import * as echarts from 'echarts'

const route = useRoute()
const loading = ref(false)
const vm = ref({})
const snapshots = ref([])
const networkList = ref([])
const vmEvents = ref([])
const activeTab = ref('disks')
const addDiskVisible = ref(false), addNicVisible = ref(false), editConfigVisible = ref(false)
const diskForm = reactive({ size: 20, type: 'data', cache: 'none' })
const nicForm = reactive({ network_id: '', model: 'virtio' })
const configForm = reactive({
  cpu: 2, memory: 2048, max_cpu: 4, max_memory: 4096, owner: '', description: '',
  cpu_mode: 'host-passthrough', bios_type: 'seabios', video_type: 'qxl', video_ram: 32,
  cpu_hotplug: false, mem_hotplug: false, hugepages: false, ha_enabled: false,
  boot_order: 'hd,cdrom,network', disk_cache: 'none'
})

const cpuChartRef = ref(null), memChartRef = ref(null), diskIoRef = ref(null), netIoRef = ref(null)
let cpuChart, memChart, diskIoChart, netIoChart

function statusType(s) { return { running: 'success', stopped: 'danger', suspended: 'warning' }[s] || 'info' }
function statusText(s) { return { running: '运行中', stopped: '已关机', suspended: '挂起' }[s] || s }

async function initCharts() {
  const lineOpt = (title, times, series, yFormat) => ({
    title: { text: title, left: 'center', textStyle: { fontSize: 14 } },
    tooltip: { trigger: 'axis' }, grid: { top: 40, bottom: 30, left: 50, right: 20 },
    xAxis: { type: 'category', data: times, boundaryGap: false },
    yAxis: { type: 'value', axisLabel: { formatter: yFormat || '{value}' } },
    series: series.map(s => ({ ...s, type: 'line', smooth: true, areaStyle: { opacity: 0.15 } }))
  })

  // Fetch real stats from API
  let stats = {}
  try {
    stats = await api.get(`/vms/${route.params.id}/stats`)
  } catch(e) { stats = {} }

  const now = Date.now()
  const times = Array.from({ length: 30 }, (_, i) => { const d = new Date(now - (29 - i) * 60000); return d.getHours().toString().padStart(2,'0') + ':' + d.getMinutes().toString().padStart(2,'0') })

  // Use real data if available, show single-point current value otherwise
  const cpuPct = stats.cpu_percent != null ? stats.cpu_percent : 0
  const memPct = stats.mem_percent != null ? stats.mem_percent : 0
  const diskRd = stats.disk_rd_bytes != null ? +(stats.disk_rd_bytes / 1048576).toFixed(1) : 0
  const diskWr = stats.disk_wr_bytes != null ? +(stats.disk_wr_bytes / 1048576).toFixed(1) : 0
  const netRx = stats.net_rx_bytes != null ? +(stats.net_rx_bytes * 8 / 1048576).toFixed(1) : 0
  const netTx = stats.net_tx_bytes != null ? +(stats.net_tx_bytes * 8 / 1048576).toFixed(1) : 0

  // Fill 30 points: last one is real, rest are 0 (no historical data stored)
  const fillData = (val) => Array.from({ length: 30 }, (_, i) => i === 29 ? val : 0)

  if (cpuChartRef.value) {
    cpuChart = echarts.init(cpuChartRef.value)
    cpuChart.setOption(lineOpt('CPU使用率', times, [{ name: 'CPU', data: fillData(cpuPct), itemStyle: { color: '#409EFF' } }], '{value}%'))
  }
  if (memChartRef.value) {
    memChart = echarts.init(memChartRef.value)
    memChart.setOption(lineOpt('内存使用率', times, [{ name: '内存', data: fillData(memPct), itemStyle: { color: '#67C23A' } }], '{value}%'))
  }
  if (diskIoRef.value) {
    diskIoChart = echarts.init(diskIoRef.value)
    diskIoChart.setOption(lineOpt('磁盘IO (MB/s)', times, [
      { name: '读', data: fillData(diskRd), itemStyle: { color: '#E6A23C' } },
      { name: '写', data: fillData(diskWr), itemStyle: { color: '#F56C6C' } }
    ]))
  }
  if (netIoRef.value) {
    netIoChart = echarts.init(netIoRef.value)
    netIoChart.setOption(lineOpt('网络IO (Mbps)', times, [
      { name: '入', data: fillData(netRx), itemStyle: { color: '#409EFF' } },
      { name: '出', data: fillData(netTx), itemStyle: { color: '#909399' } }
    ]))
  }
}

watch(activeTab, (v) => { if (v === 'monitor') nextTick(initCharts) })

async function loadVM() {
  loading.value = true
  try {
    const res = await api.get(`/vms/${route.params.id}`)
    vm.value = res.data || res
    snapshots.value = ((await api.get(`/vms/${route.params.id}/snapshots`)).data) || []
    // Load real events from API
    try {
      const evtRes = await api.get('/events', { params: { type: 'vm', page_size: 20 } })
      vmEvents.value = (evtRes.data || []).filter(e => e.resource_id === route.params.id || e.resource_name === vm.value.name).slice(0, 20)
      if (!vmEvents.value.length) vmEvents.value = evtRes.data?.slice(0, 10) || []
    } catch(e) { vmEvents.value = [] }
  } finally { loading.value = false }
}

// Removed fake generateEvents function

async function action(act) {
  if (act === 'migrate') { ElMessage.info('迁移功能模拟中...'); return }
  await api.post(`/vms/${route.params.id}/action`, { action: act })
  ElMessage.success('操作成功'); loadVM()
}

function openConsole() {
  ElMessage.info(`正在打开VNC连接: ${vm.value.ip || 'localhost'}:${vm.value.vnc_port || 5900}`)
}

async function doAddDisk() {
  await api.post(`/vms/${route.params.id}/disks`, diskForm)
  ElMessage.success('添加成功'); addDiskVisible.value = false; loadVM()
}
async function removeDisk(d) {
  await ElMessageBox.confirm(`确认移除磁盘 ${d.name}?`)
  await api.delete(`/vms/${route.params.id}/disks/${d.id}`); ElMessage.success('已移除'); loadVM()
}
async function doAddNic() {
  await api.post(`/vms/${route.params.id}/nics`, nicForm)
  ElMessage.success('添加成功'); addNicVisible.value = false; loadVM()
}
async function removeNic(n) {
  await ElMessageBox.confirm(`确认移除网卡 ${n.name}?`)
  await api.delete(`/vms/${route.params.id}/nics/${n.id}`); ElMessage.success('已移除'); loadVM()
}
async function createSnap() {
  const { value } = await ElMessageBox.prompt('快照名称', '创建快照', { inputValue: `snap-${Date.now()}` })
  await api.post(`/vms/${route.params.id}/snapshots`, { name: value }); ElMessage.success('创建成功'); loadVM()
}
async function revertSnap(s) {
  await ElMessageBox.confirm(`确认恢复到快照 ${s.name}?`)
  await api.post(`/vms/${route.params.id}/snapshots/${s.id}/revert`); ElMessage.success('已恢复'); loadVM()
}
async function deleteSnap(s) {
  await ElMessageBox.confirm(`确认删除快照 ${s.name}?`)
  await api.delete(`/vms/${route.params.id}/snapshots/${s.id}`); ElMessage.success('已删除'); loadVM()
}

function openEditConfig() {
  const v = vm.value
  Object.assign(configForm, {
    cpu: v.cpu || 2, memory: v.memory || 2048, max_cpu: v.max_cpu || 4, max_memory: v.max_memory || 4096,
    owner: v.owner || '', description: v.description || '',
    cpu_mode: v.cpu_mode || 'host-passthrough', bios_type: v.bios_type || 'seabios',
    video_type: v.video_type || 'qxl', video_ram: v.video_ram || 32,
    cpu_hotplug: !!v.cpu_hotplug, mem_hotplug: !!v.mem_hotplug, hugepages: !!v.hugepages,
    ha_enabled: !!v.ha_enabled, boot_order: v.boot_order || 'hd,cdrom,network',
    disk_cache: v.disk_cache || 'none'
  })
  editConfigVisible.value = true
}

async function saveConfig() {
  await api.put(`/vms/${route.params.id}`, { ...configForm })
  ElMessage.success('配置已保存，部分更改需关机后生效'); editConfigVisible.value = false; loadVM()
}

onMounted(async () => {
  try { networkList.value = (await api.get('/networks')).data || [] } catch(e) { networkList.value = [] }
  loadVM()
})
</script>
