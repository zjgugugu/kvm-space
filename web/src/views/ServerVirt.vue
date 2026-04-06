<template>
  <div>
    <div class="page-header">
      <h2>云服务器</h2>
      <div style="display:flex;gap:8px;align-items:center;">
        <el-input v-model="search" placeholder="搜索名称/IP" clearable style="width:200px" @clear="load" @keyup.enter="load">
          <template #prefix><el-icon><Search /></el-icon></template>
        </el-input>
        <el-select v-model="statusFilter" placeholder="状态" clearable @change="load" style="width:120px">
          <el-option label="运行中" value="running" /><el-option label="已关闭" value="stopped" /><el-option label="已挂起" value="suspended" />
        </el-select>
        <el-button type="primary" @click="showCreate"><el-icon><Plus /></el-icon>创建云服务器</el-button>
      </div>
    </div>
    <el-table :data="filteredVms" v-loading="loading" border stripe size="small">
      <el-table-column type="selection" width="40" />
      <el-table-column prop="name" label="名称" width="160">
        <template #default="{ row }"><router-link :to="`/server-virt/${row.id}`" class="link">{{ row.name }}</router-link></template>
      </el-table-column>
      <el-table-column prop="status" label="状态" width="90">
        <template #default="{ row }"><el-tag :type="statusType(row.status)" size="small">{{ statusText(row.status) }}</el-tag></template>
      </el-table-column>
      <el-table-column prop="os_type" label="操作系统" width="120" />
      <el-table-column prop="cpu" label="vCPU" width="70" />
      <el-table-column label="内存" width="90">
        <template #default="{ row }">{{ (row.memory/1024).toFixed(0) }}GB</template>
      </el-table-column>
      <el-table-column prop="host_name" label="所在主机" width="140" />
      <el-table-column prop="ip" label="IP地址" width="130" />
      <el-table-column prop="created_at" label="创建时间" width="160" />
      <el-table-column label="操作" width="250" fixed="right">
        <template #default="{ row }">
          <el-button size="small" type="success" v-if="row.status!=='running'" @click="action(row,'start')">启动</el-button>
          <el-button size="small" type="warning" v-if="row.status==='running'" @click="action(row,'shutdown')">关机</el-button>
          <el-button size="small" v-if="row.status==='running'" @click="action(row,'reboot')">重启</el-button>
          <el-button size="small" type="danger" @click="remove(row)">删除</el-button>
        </template>
      </el-table-column>
    </el-table>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import api from '../api'
import { ElMessage, ElMessageBox } from 'element-plus'

const loading = ref(false)
const vms = ref([])
const search = ref(''), statusFilter = ref('')

function statusType(s) { return { running: 'success', stopped: 'danger', suspended: 'warning', creating: 'info' }[s] || 'info' }
function statusText(s) { return { running: '运行中', stopped: '已关闭', suspended: '已挂起', creating: '创建中' }[s] || s }

const filteredVms = computed(() => {
  let list = vms.value
  if (search.value) {
    const s = search.value.toLowerCase()
    list = list.filter(v => v.name.toLowerCase().includes(s) || (v.ip || '').includes(s))
  }
  if (statusFilter.value) list = list.filter(v => v.status === statusFilter.value)
  return list
})

async function load() {
  loading.value = true
  try {
    const res = await api.get('/vms', { params: { type: 'server' } })
    vms.value = res.data || []
  } catch(e) { vms.value = [] }
  finally { loading.value = false }
}

async function action(vm, act) {
  await api.post(`/vms/${vm.id}/action`, { action: act })
  ElMessage.success(`${act} 操作已执行`); setTimeout(load, 1000)
}

async function remove(vm) {
  await ElMessageBox.confirm(`确认删除云服务器 ${vm.name}?`, '删除', { type: 'warning' })
  await api.delete(`/vms/${vm.id}`); ElMessage.success('已删除'); load()
}

function showCreate() {
  ElMessage.info('创建云服务器功能开发中')
}

onMounted(load)
</script>
