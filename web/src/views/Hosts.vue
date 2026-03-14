<template>
  <div>
    <div class="page-header">
      <h2>主机管理</h2>
      <el-button type="primary" @click="showDialog()"><el-icon><Plus /></el-icon>添加主机</el-button>
    </div>
    <el-table :data="hosts" v-loading="loading" border stripe>
      <el-table-column prop="name" label="主机名" width="160" />
      <el-table-column prop="ip" label="IP地址" width="140" />
      <el-table-column prop="arch" label="架构" width="80" />
      <el-table-column prop="status" label="状态" width="90">
        <template #default="{ row }">
          <el-tag :type="row.status === 'online' ? 'success' : 'danger'" size="small">{{ row.status === 'online' ? '在线' : '离线' }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column label="CPU" width="160">
        <template #default="{ row }">
          <el-progress :percentage="row.cpu_total ? Math.round(row.cpu_used / row.cpu_total * 100) : 0" :stroke-width="14" />
          <span style="font-size: 12px; color: #909399;">{{ row.cpu_used }}/{{ row.cpu_total }}核</span>
        </template>
      </el-table-column>
      <el-table-column label="内存" width="160">
        <template #default="{ row }">
          <el-progress :percentage="row.mem_total ? Math.round(row.mem_used / row.mem_total * 100) : 0" :stroke-width="14" />
          <span style="font-size: 12px; color: #909399;">{{ (row.mem_used / 1024).toFixed(1) }}/{{ (row.mem_total / 1024).toFixed(1) }}GB</span>
        </template>
      </el-table-column>
      <el-table-column prop="vm_count" label="虚拟机" width="80" />
      <el-table-column prop="os" label="操作系统" min-width="150" />
      <el-table-column label="操作" width="200" fixed="right">
        <template #default="{ row }">
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

    <el-dialog v-model="dialogVisible" :title="editingHost ? '编辑主机' : '添加主机'" width="500px">
      <el-form :model="form" label-width="80px">
        <el-form-item label="主机名"><el-input v-model="form.name" /></el-form-item>
        <el-form-item label="IP地址"><el-input v-model="form.ip" /></el-form-item>
        <el-form-item label="BMC IP"><el-input v-model="form.bmc_ip" /></el-form-item>
        <el-form-item label="角色">
          <el-select v-model="form.role" style="width: 100%;">
            <el-option label="VDI" value="VDI" /><el-option label="VOI" value="VOI" /><el-option label="IDV" value="IDV" />
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
import { ref, reactive, onMounted } from 'vue'
import api from '../api'
import { ElMessage, ElMessageBox } from 'element-plus'

const loading = ref(false)
const hosts = ref([])
const dialogVisible = ref(false)
const editingHost = ref(null)
const saving = ref(false)
const form = reactive({ name: '', ip: '', bmc_ip: '', role: 'VDI' })

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
