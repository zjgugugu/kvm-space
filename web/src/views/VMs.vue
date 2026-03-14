<template>
  <div>
    <div class="page-header">
      <h2>虚拟机管理</h2>
      <div style="display: flex; gap: 10px;">
        <el-input v-model="search" placeholder="搜索名称/IP/用户" clearable style="width: 220px;" @clear="load" @keyup.enter="load">
          <template #prefix><el-icon><Search /></el-icon></template>
        </el-input>
        <el-select v-model="statusFilter" placeholder="状态筛选" clearable @change="load" style="width: 120px;">
          <el-option label="运行中" value="running" /><el-option label="已关机" value="stopped" />
          <el-option label="已挂起" value="suspended" />
        </el-select>
        <el-button type="primary" @click="showCreate"><el-icon><Plus /></el-icon>创建虚拟机</el-button>
      </div>
    </div>

    <el-table :data="vms" v-loading="loading" border stripe @row-click="r => $router.push(`/vms/${r.id}`)">
      <el-table-column prop="name" label="名称" width="160" />
      <el-table-column prop="status" label="状态" width="90">
        <template #default="{ row }">
          <el-tag :type="vmStatusType(row.status)" size="small">{{ vmStatusText(row.status) }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column label="配置" width="130">
        <template #default="{ row }">{{ row.cpu }}C/{{ (row.memory/1024).toFixed(0) }}G/{{ row.disk }}G</template>
      </el-table-column>
      <el-table-column prop="ip" label="IP" width="140" />
      <el-table-column prop="os_version" label="操作系统" width="130" />
      <el-table-column prop="host_name" label="所在主机" width="130" />
      <el-table-column prop="owner" label="使用者" width="80" />
      <el-table-column prop="created_at" label="创建时间" min-width="160" />
      <el-table-column label="操作" width="240" fixed="right">
        <template #default="{ row }">
          <el-button-group size="small">
            <el-button v-if="row.status==='stopped'" type="success" @click.stop="doAction(row,'start')">开机</el-button>
            <el-button v-if="row.status==='running'" type="warning" @click.stop="doAction(row,'stop')">关机</el-button>
            <el-button v-if="row.status==='running'" @click.stop="doAction(row,'reboot')">重启</el-button>
            <el-button v-if="row.status==='suspended'" type="info" @click.stop="doAction(row,'resume')">唤醒</el-button>
          </el-button-group>
          <el-dropdown trigger="click" @command="c => doAction(row, c)" style="margin-left: 8px;">
            <el-button size="small" @click.stop>更多<el-icon class="el-icon--right"><ArrowDown /></el-icon></el-button>
            <template #dropdown>
              <el-dropdown-menu>
                <el-dropdown-item command="suspend" v-if="row.status==='running'">挂起</el-dropdown-item>
                <el-dropdown-item command="force_stop">强制关机</el-dropdown-item>
                <el-dropdown-item command="clone">克隆</el-dropdown-item>
                <el-dropdown-item command="migrate">迁移</el-dropdown-item>
                <el-dropdown-item command="delete" divided style="color:#f56c6c;">删除</el-dropdown-item>
              </el-dropdown-menu>
            </template>
          </el-dropdown>
        </template>
      </el-table-column>
    </el-table>

    <!-- 创建VM对话框 -->
    <el-dialog v-model="createVisible" title="创建虚拟机" width="550px">
      <el-form :model="form" label-width="90px">
        <el-form-item label="名称"><el-input v-model="form.name" /></el-form-item>
        <el-form-item label="模板">
          <el-select v-model="form.template_id" style="width: 100%;">
            <el-option v-for="t in tplList" :key="t.id" :label="t.name" :value="t.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="CPU(核)"><el-input-number v-model="form.cpu" :min="1" :max="64" /></el-form-item>
        <el-form-item label="内存(MB)"><el-input-number v-model="form.memory" :min="512" :max="131072" :step="512" /></el-form-item>
        <el-form-item label="磁盘(GB)"><el-input-number v-model="form.disk" :min="10" :max="2048" /></el-form-item>
        <el-form-item label="使用者"><el-input v-model="form.owner" /></el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="createVisible = false">取消</el-button>
        <el-button type="primary" :loading="saving" @click="createVM">确定</el-button>
      </template>
    </el-dialog>

    <!-- 迁移对话框 -->
    <el-dialog v-model="migrateVisible" title="虚拟机迁移" width="400px">
      <el-form label-width="80px">
        <el-form-item label="目标主机">
          <el-select v-model="migrateTarget" style="width: 100%;">
            <el-option v-for="h in hostList" :key="h.id" :label="`${h.name} (${h.ip})`" :value="h.id" />
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
const loading = ref(false), saving = ref(false)
const vms = ref([]), tplList = ref([]), hostList = ref([])
const search = ref(''), statusFilter = ref('')
const createVisible = ref(false), migrateVisible = ref(false)
const migrateTarget = ref(''), migrateVM = ref(null)
const form = reactive({ name: '', template_id: '', cpu: 2, memory: 2048, disk: 40, owner: '' })

function vmStatusType(s) { return { running: 'success', stopped: 'danger', suspended: 'warning', migrating: '' }[s] || 'info' }
function vmStatusText(s) { return { running: '运行中', stopped: '已关机', suspended: '挂起', migrating: '迁移中', creating: '创建中' }[s] || s }

async function load() {
  loading.value = true
  try {
    const params = {}
    if (search.value) params.search = search.value
    if (statusFilter.value) params.status = statusFilter.value
    const res = await api.get('/vms', { params })
    vms.value = res.data
  } finally { loading.value = false }
}

async function showCreate() {
  if (!tplList.value.length) tplList.value = (await api.get('/templates')).data
  if (!hostList.value.length) hostList.value = (await api.get('/hosts')).data
  Object.assign(form, { name: '', template_id: '', cpu: 2, memory: 2048, disk: 40, owner: '' })
  createVisible.value = true
}

async function createVM() {
  saving.value = true
  try { await api.post('/vms', form); ElMessage.success('创建成功'); createVisible.value = false; load() }
  finally { saving.value = false }
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
