<template>
  <div>
    <div class="page-header">
      <h2>服务器管理</h2>
      <div style="display: flex; gap: 8px; align-items: center;">
        <el-input v-model="search" placeholder="搜索名称/IP" clearable style="width: 200px;" @clear="loadHosts" @keyup.enter="loadHosts">
          <template #prefix><el-icon><Search /></el-icon></template>
        </el-input>
        <el-select v-model="statusFilter" placeholder="状态" clearable @change="loadHosts" style="width: 100px;">
          <el-option label="在线" value="online" /><el-option label="离线" value="offline" />
        </el-select>
        <el-button type="primary" @click="showDialog()"><el-icon><Plus /></el-icon>添加服务器</el-button>
      </div>
    </div>

    <el-row :gutter="12" style="margin-bottom: 12px;">
      <el-col :span="6"><el-statistic title="服务器总数" :value="hosts.length" /></el-col>
      <el-col :span="6"><el-statistic title="在线" :value="hosts.filter(h => h.status === 'online').length"><template #suffix><span style="color: #67c23a;"> 台</span></template></el-statistic></el-col>
      <el-col :span="6"><el-statistic title="离线" :value="hosts.filter(h => h.status !== 'online').length"><template #suffix><span style="color: #f56c6c;"> 台</span></template></el-statistic></el-col>
      <el-col :span="6"><el-statistic title="总虚拟机" :value="hosts.reduce((s, h) => s + (h.vm_count || 0), 0)" /></el-col>
    </el-row>

    <el-table :data="filteredHosts" v-loading="loading" border stripe>
      <el-table-column prop="name" label="服务器名称" width="150">
        <template #default="{ row }">
          <el-button link type="primary" @click="$router.push(`/hosts/${row.id}`)">{{ row.name }}</el-button>
        </template>
      </el-table-column>
      <el-table-column prop="ip" label="IP地址" width="130" />
      <el-table-column prop="role" label="类型" width="90">
        <template #default="{ row }"><el-tag size="small" type="info">{{ row.role || 'VDI' }}</el-tag></template>
      </el-table-column>
      <el-table-column prop="arch" label="架构" width="80" />
      <el-table-column prop="cpu_model" label="CPU型号" width="140" show-overflow-tooltip />
      <el-table-column prop="status" label="状态" width="80">
        <template #default="{ row }">
          <el-tag :type="row.status === 'online' ? 'success' : 'danger'" size="small">{{ row.status === 'online' ? '在线' : '离线' }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column label="CPU" width="150">
        <template #default="{ row }">
          <el-progress :percentage="row.cpu_total ? Math.round(row.cpu_used / row.cpu_total * 100) : 0" :stroke-width="14" />
          <span style="font-size: 12px; color: #909399;">{{ row.cpu_used }}/{{ row.cpu_total }}核</span>
        </template>
      </el-table-column>
      <el-table-column label="内存" width="150">
        <template #default="{ row }">
          <el-progress :percentage="row.mem_total ? Math.round(row.mem_used / row.mem_total * 100) : 0" :stroke-width="14" />
          <span style="font-size: 12px; color: #909399;">{{ (row.mem_used / 1024).toFixed(1) }}/{{ (row.mem_total / 1024).toFixed(1) }}GB</span>
        </template>
      </el-table-column>
      <el-table-column prop="vm_count" label="虚拟机" width="70" />
      <el-table-column prop="os" label="操作系统" min-width="140" show-overflow-tooltip />
      <el-table-column label="操作" width="200" fixed="right">
        <template #default="{ row }">
          <el-button size="small" type="primary" link @click="$router.push(`/hosts/${row.id}`)">详情</el-button>
          <el-button size="small" @click="showDialog(row)">编辑</el-button>
          <el-dropdown trigger="click" @command="c => handleAction(row, c)" style="margin-left: 8px;">
            <el-button size="small">更多<el-icon class="el-icon--right"><ArrowDown /></el-icon></el-button>
            <template #dropdown>
              <el-dropdown-menu>
                <el-dropdown-item command="reboot">重启</el-dropdown-item>
                <el-dropdown-item command="shutdown">关机</el-dropdown-item>
                <el-dropdown-item command="delete" divided style="color: #f56c6c;">删除</el-dropdown-item>
              </el-dropdown-menu>
            </template>
          </el-dropdown>
        </template>
      </el-table-column>
    </el-table>

    <el-dialog v-model="dialogVisible" :title="editingHost ? '编辑服务器' : '添加服务器'" width="520px">
      <el-form :model="form" label-width="90px">
        <el-form-item label="服务器名" required><el-input v-model="form.name" /></el-form-item>
        <el-form-item label="IP地址" required><el-input v-model="form.ip" /></el-form-item>
        <el-form-item label="BMC地址"><el-input v-model="form.bmc_ip" placeholder="远程管理地址" /></el-form-item>
        <el-form-item label="服务器类型">
          <el-select v-model="form.role" style="width: 100%;">
            <el-option label="CM_VDI (管理+计算)" value="CM_VDI" />
            <el-option label="VDI (计算)" value="VDI" />
            <el-option label="CM (管理)" value="CM" />
            <el-option label="Arbiter (仲裁)" value="Arbiter" />
            <el-option label="Gateway (网关)" value="Gateway" />
          </el-select>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="saving" @click="saveHost">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted } from 'vue'
import api from '../api'
import { ElMessage, ElMessageBox } from 'element-plus'

const loading = ref(false), saving = ref(false)
const hosts = ref([])
const dialogVisible = ref(false)
const editingHost = ref(null)
const search = ref(''), statusFilter = ref('')
const form = reactive({ name: '', ip: '', bmc_ip: '', role: 'VDI' })

const filteredHosts = computed(() => {
  let list = hosts.value
  if (search.value) {
    const s = search.value.toLowerCase()
    list = list.filter(h => h.name.toLowerCase().includes(s) || h.ip.includes(s))
  }
  if (statusFilter.value) list = list.filter(h => h.status === statusFilter.value)
  return list
})

async function loadHosts() {
  loading.value = true
  try { hosts.value = (await api.get('/hosts')).data } finally { loading.value = false }
}

function showDialog(host) {
  editingHost.value = host || null
  if (host) { Object.assign(form, { name: host.name, ip: host.ip, bmc_ip: host.bmc_ip || '', role: host.role || 'VDI' }) }
  else { Object.assign(form, { name: '', ip: '', bmc_ip: '', role: 'VDI' }) }
  dialogVisible.value = true
}

async function saveHost() {
  saving.value = true
  try {
    if (editingHost.value) { await api.put(`/hosts/${editingHost.value.id}`, form) }
    else { await api.post('/hosts', form) }
    ElMessage.success('保存成功')
    dialogVisible.value = false
    loadHosts()
  } finally { saving.value = false }
}

async function handleAction(host, action) {
  if (action === 'delete') {
    await ElMessageBox.confirm(`确认删除主机 ${host.name}?`, '警告', { type: 'warning' })
    await api.delete(`/hosts/${host.id}`)
    ElMessage.success('已删除')
    loadHosts()
  } else {
    await api.post(`/hosts/${host.id}/action`, { action })
    ElMessage.success('操作已执行')
    loadHosts()
  }
}

onMounted(loadHosts)
</script>
