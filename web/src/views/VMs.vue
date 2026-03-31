<template>
  <div>
    <div class="page-header">
      <h2>桌面虚拟机</h2>
      <div style="display: flex; gap: 8px; align-items: center;">
        <el-input v-model="search" placeholder="搜索名称/IP/用户/MAC" clearable style="width: 220px;" @clear="load" @keyup.enter="load">
          <template #prefix><el-icon><Search /></el-icon></template>
        </el-input>
        <el-select v-model="statusFilter" placeholder="状态" clearable @change="load" style="width: 110px;">
          <el-option label="运行中" value="running" /><el-option label="已关机" value="stopped" />
          <el-option label="已挂起" value="suspended" /><el-option label="创建中" value="creating" />
        </el-select>
        <el-select v-model="hostFilter" placeholder="所在主机" clearable @change="load" style="width: 140px;">
          <el-option v-for="h in hostList" :key="h.id" :label="h.name" :value="h.id" />
        </el-select>
        <el-button type="primary" @click="showCreate"><el-icon><Plus /></el-icon>创建虚拟机</el-button>
        <el-button :disabled="!selected.length" @click="batchAction('start')"><el-icon><VideoPlay /></el-icon>批量开机</el-button>
        <el-button :disabled="!selected.length" @click="batchAction('stop')"><el-icon><VideoPause /></el-icon>批量关机</el-button>
        <el-button :disabled="!selected.length" type="danger" @click="batchAction('delete')"><el-icon><Delete /></el-icon>批量删除</el-button>
      </div>
    </div>

    <el-tabs v-model="tab" @tab-change="onTabChange">
      <el-tab-pane label="虚拟机列表" name="list">
        <el-table :data="vms" v-loading="loading" border stripe @selection-change="onSelect" @row-click="r => $router.push(`/vms/${r.id}`)" row-class-name="clickable-row">
          <el-table-column type="selection" width="40" @click.stop />
          <el-table-column prop="name" label="名称" width="150">
            <template #default="{ row }">
              <el-button link type="primary" @click.stop="$router.push(`/vms/${row.id}`)">{{ row.name }}</el-button>
            </template>
          </el-table-column>
          <el-table-column prop="status" label="状态" width="85">
            <template #default="{ row }">
              <el-tag :type="vmStatusType(row.status)" size="small">{{ vmStatusText(row.status) }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="publish_rule" label="发布规则" width="110" />
          <el-table-column label="CPU" width="80">
            <template #default="{ row }">{{ row.cpu }}核</template>
          </el-table-column>
          <el-table-column label="内存" width="80">
            <template #default="{ row }">{{ (row.memory/1024).toFixed(0) }}GB</template>
          </el-table-column>
          <el-table-column label="磁盘" width="70">
            <template #default="{ row }">{{ row.disk }}G</template>
          </el-table-column>
          <el-table-column prop="ip" label="IP" width="130" />
          <el-table-column prop="mac" label="MAC" width="140" />
          <el-table-column prop="protocol" label="协议" width="70" />
          <el-table-column prop="os_version" label="操作系统" width="120" />
          <el-table-column prop="host_name" label="所在主机" width="120">
            <template #default="{ row }">
              <el-button link type="primary" v-if="row.host_id" @click.stop="$router.push(`/hosts/${row.host_id}`)">{{ row.host_name }}</el-button>
              <span v-else>-</span>
            </template>
          </el-table-column>
          <el-table-column prop="owner" label="使用者" width="80" />
          <el-table-column prop="created_at" label="创建时间" width="155" />
          <el-table-column label="操作" width="250" fixed="right">
            <template #default="{ row }">
              <el-button-group size="small">
                <el-button v-if="row.status==='stopped'" type="success" @click.stop="doAction(row,'start')">开机</el-button>
                <el-button v-if="row.status==='running'" type="warning" @click.stop="doAction(row,'stop')">关机</el-button>
                <el-button v-if="row.status==='running'" @click.stop="doAction(row,'reboot')">重启</el-button>
                <el-button v-if="row.status==='running'" type="primary" @click.stop="openConsole(row)">远程</el-button>
                <el-button v-if="row.status==='suspended'" type="info" @click.stop="doAction(row,'resume')">唤醒</el-button>
              </el-button-group>
              <el-dropdown trigger="click" @command="c => doAction(row, c)" style="margin-left: 8px;">
                <el-button size="small" @click.stop>更多<el-icon class="el-icon--right"><ArrowDown /></el-icon></el-button>
                <template #dropdown>
                  <el-dropdown-menu>
                    <el-dropdown-item command="suspend" v-if="row.status==='running'">挂起</el-dropdown-item>
                    <el-dropdown-item command="force_stop">强制关机</el-dropdown-item>
                    <el-dropdown-item command="force_reboot">强制重启</el-dropdown-item>
                    <el-dropdown-item command="clone" divided>克隆</el-dropdown-item>
                    <el-dropdown-item command="migrate">迁移</el-dropdown-item>
                    <el-dropdown-item command="restore_template">还原镜像</el-dropdown-item>
                    <el-dropdown-item command="delete" divided style="color:#f56c6c;">删除</el-dropdown-item>
                  </el-dropdown-menu>
                </template>
              </el-dropdown>
            </template>
          </el-table-column>
        </el-table>
      </el-tab-pane>

      <el-tab-pane name="recycle">
        <template #label><el-icon><Delete /></el-icon> 回收站 <el-badge :value="recycleBin.length" :hidden="!recycleBin.length" /></template>
        <el-table :data="recycleBin" v-loading="recycleLoading" border stripe size="small">
          <el-table-column prop="name" label="名称" width="160" />
          <el-table-column prop="owner" label="使用者" width="100" />
          <el-table-column prop="deleted_at" label="删除时间" width="170" />
          <el-table-column label="配置" width="130">
            <template #default="{ row }">{{ row.cpu }}C/{{ (row.memory/1024).toFixed(0) }}G/{{ row.disk }}G</template>
          </el-table-column>
          <el-table-column label="操作" width="180">
            <template #default="{ row }">
              <el-button size="small" type="primary" @click="restoreVM(row)">恢复</el-button>
              <el-button size="small" type="danger" @click="permanentDelete(row)">彻底删除</el-button>
            </template>
          </el-table-column>
        </el-table>
      </el-tab-pane>
    </el-tabs>

    <!-- 创建VM对话框 -->
    <el-dialog v-model="createVisible" title="创建虚拟机" width="600px">
      <el-form :model="form" label-width="100px">
        <el-form-item label="名称" required><el-input v-model="form.name" placeholder="输入虚拟机名称" /></el-form-item>
        <el-form-item label="黄金镜像">
          <el-select v-model="form.template_id" style="width: 100%;" placeholder="选择镜像模板">
            <el-option v-for="t in tplList" :key="t.id" :label="`${t.name} (${t.os_version})`" :value="t.id" />
          </el-select>
        </el-form-item>
        <el-row :gutter="16">
          <el-col :span="8"><el-form-item label="CPU(核)"><el-input-number v-model="form.cpu" :min="1" :max="64" style="width: 100%;" /></el-form-item></el-col>
          <el-col :span="8"><el-form-item label="内存(MB)"><el-input-number v-model="form.memory" :min="512" :max="131072" :step="512" style="width: 100%;" /></el-form-item></el-col>
          <el-col :span="8"><el-form-item label="磁盘(GB)"><el-input-number v-model="form.disk" :min="10" :max="2048" style="width: 100%;" /></el-form-item></el-col>
        </el-row>
        <el-form-item label="使用者"><el-input v-model="form.owner" placeholder="分配给指定用户" /></el-form-item>
        <el-form-item label="桌面协议">
          <el-select v-model="form.protocol" style="width: 100%;">
            <el-option label="UDAP" value="UDAP" /><el-option label="SPICE" value="SPICE" /><el-option label="VNC" value="VNC" />
          </el-select>
        </el-form-item>
        <el-divider content-position="left">高级配置</el-divider>
        <el-row :gutter="16">
          <el-col :span="12">
            <el-form-item label="CPU模式">
              <el-select v-model="form.cpu_mode" style="width: 100%;">
                <el-option label="host-passthrough" value="host-passthrough" />
                <el-option label="host-model" value="host-model" />
                <el-option label="custom" value="custom" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="BIOS类型">
              <el-select v-model="form.bios_type" style="width: 100%;">
                <el-option label="SeaBIOS" value="seabios" />
                <el-option label="UEFI (OVMF)" value="uefi" />
              </el-select>
            </el-form-item>
          </el-col>
        </el-row>
        <el-row :gutter="16">
          <el-col :span="12">
            <el-form-item label="显卡类型">
              <el-select v-model="form.video_type" style="width: 100%;">
                <el-option label="QXL" value="qxl" />
                <el-option label="VGA" value="vga" />
                <el-option label="Virtio" value="virtio" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="显存(MB)"><el-input-number v-model="form.video_ram" :min="8" :max="256" style="width: 100%;" /></el-form-item>
          </el-col>
        </el-row>
        <el-row :gutter="16">
          <el-col :span="12"><el-form-item label="CPU 热添加"><el-switch v-model="form.cpu_hotplug" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="内存热添加"><el-switch v-model="form.mem_hotplug" /></el-form-item></el-col>
        </el-row>
        <el-row :gutter="16">
          <el-col :span="12"><el-form-item label="大页内存"><el-switch v-model="form.hugepages" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="HA 高可用"><el-switch v-model="form.ha_enabled" /></el-form-item></el-col>
        </el-row>
        <el-form-item label="启动顺序"><el-input v-model="form.boot_order" placeholder="hd,cdrom,network" /></el-form-item>
        <el-form-item label="磁盘缓存">
          <el-select v-model="form.disk_cache" style="width: 100%;">
            <el-option label="none" value="none" /><el-option label="writethrough" value="writethrough" /><el-option label="writeback" value="writeback" /><el-option label="unsafe" value="unsafe" />
          </el-select>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="createVisible = false">取消</el-button>
        <el-button type="primary" :loading="saving" @click="createVM">确定</el-button>
      </template>
    </el-dialog>

    <!-- 迁移对话框 -->
    <el-dialog v-model="migrateVisible" title="虚拟机迁移" width="420px">
      <el-form label-width="80px">
        <el-form-item label="虚拟机"><el-tag>{{ migrateVM?.name }}</el-tag></el-form-item>
        <el-form-item label="当前主机"><span>{{ migrateVM?.host_name || '-' }}</span></el-form-item>
        <el-form-item label="目标主机">
          <el-select v-model="migrateTarget" style="width: 100%;" placeholder="选择目标主机">
            <el-option v-for="h in hostList.filter(h => h.id !== migrateVM?.host_id)" :key="h.id" :label="`${h.name} (${h.ip})`" :value="h.id" />
          </el-select>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="migrateVisible = false">取消</el-button>
        <el-button type="primary" @click="doMigrate">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import api from '../api'
import { ElMessage, ElMessageBox } from 'element-plus'

const router = useRouter()
const loading = ref(false), saving = ref(false), recycleLoading = ref(false)
const vms = ref([]), tplList = ref([]), hostList = ref([]), recycleBin = ref([])
const search = ref(''), statusFilter = ref(''), hostFilter = ref('')
const createVisible = ref(false), migrateVisible = ref(false)
const migrateTarget = ref(''), migrateVM = ref(null)
const selected = ref([])
const tab = ref('list')
const form = reactive({
  name: '', template_id: '', cpu: 2, memory: 2048, disk: 40, owner: '', protocol: 'UDAP',
  cpu_mode: 'host-passthrough', bios_type: 'seabios', video_type: 'qxl', video_ram: 32,
  cpu_hotplug: false, mem_hotplug: false, hugepages: false, ha_enabled: false,
  boot_order: 'hd,cdrom,network', disk_cache: 'none'
})

function vmStatusType(s) { return { running: 'success', stopped: 'danger', suspended: 'warning', migrating: '', creating: 'info' }[s] || 'info' }
function vmStatusText(s) { return { running: '运行中', stopped: '已关机', suspended: '挂起', migrating: '迁移中', creating: '创建中' }[s] || s }
function onSelect(rows) { selected.value = rows }

async function load() {
  loading.value = true
  try {
    const params = {}
    if (search.value) params.search = search.value
    if (statusFilter.value) params.status = statusFilter.value
    if (hostFilter.value) params.host_id = hostFilter.value
    const res = await api.get('/vms', { params })
    vms.value = res.data
    if (!hostList.value.length) hostList.value = (await api.get('/hosts')).data
  } finally { loading.value = false }
}

async function loadRecycleBin() {
  recycleLoading.value = true
  try { recycleBin.value = (await api.get('/vms/recycle-bin')).data || [] }
  catch(e) { recycleBin.value = [] }
  finally { recycleLoading.value = false }
}

function onTabChange(name) { if (name === 'recycle') loadRecycleBin() }

async function restoreVM(vm) {
  await api.post(`/vms/${vm.id}/restore`)
  ElMessage.success('已恢复'); loadRecycleBin(); load()
}

async function permanentDelete(vm) {
  await ElMessageBox.confirm(`彻底删除 ${vm.name}? 此操作不可恢复!`, '警告', { type: 'error' })
  await api.delete(`/vms/${vm.id}`, { params: { permanent: true } })
  ElMessage.success('已彻底删除'); loadRecycleBin()
}

async function showCreate() {
  if (!tplList.value.length) tplList.value = (await api.get('/templates')).data
  if (!hostList.value.length) hostList.value = (await api.get('/hosts')).data
  Object.assign(form, { name: '', template_id: '', cpu: 2, memory: 2048, disk: 40, owner: '', protocol: 'UDAP' })
  createVisible.value = true
}

async function createVM() {
  saving.value = true
  try { await api.post('/vms', form); ElMessage.success('创建成功'); createVisible.value = false; load() }
  finally { saving.value = false }
}

async function batchAction(action) {
  if (!selected.value.length) return
  if (action === 'delete') {
    await ElMessageBox.confirm(`确认删除 ${selected.value.length} 台虚拟机?`, '批量删除', { type: 'warning' })
    await Promise.all(selected.value.map(vm => api.delete(`/vms/${vm.id}`)))
  } else {
    await Promise.all(selected.value.map(vm => api.post(`/vms/${vm.id}/action`, { action })))
  }
  ElMessage.success('批量操作完成'); load()
}

function openConsole(vm) {
  ElMessage.info(`正在连接 ${vm.name} 的远程桌面 (${vm.protocol || 'UDAP'})...`)
}

async function doAction(vm, action) {
  if (action === 'delete') {
    await ElMessageBox.confirm(`确认删除虚拟机 ${vm.name}?`, '警告', { type: 'warning' })
    await api.delete(`/vms/${vm.id}`); ElMessage.success('已删除'); load()
  } else if (action === 'clone') {
    const { value } = await ElMessageBox.prompt('请输入克隆名称', '克隆虚拟机', { inputValue: `${vm.name}-clone` })
    await api.post(`/vms/${vm.id}/clone`, { name: value }); ElMessage.success('克隆成功'); load()
  } else if (action === 'migrate') {
    if (!hostList.value.length) hostList.value = (await api.get('/hosts')).data
    migrateVM.value = vm; migrateTarget.value = ''; migrateVisible.value = true
  } else {
    await api.post(`/vms/${vm.id}/action`, { action }); ElMessage.success('操作成功'); load()
  }
}

async function doMigrate() {
  await api.post(`/vms/${migrateVM.value.id}/migrate`, { target_host: migrateTarget.value })
  ElMessage.success('迁移成功'); migrateVisible.value = false; load()
}

onMounted(load)
</script>
