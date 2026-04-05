<template>
  <div>
    <div class="page-header">
      <h2>终端管理</h2>
      <div style="display:flex;gap:8px;align-items:center;">
        <el-input v-model="search" placeholder="搜索终端名/IP" clearable style="width:200px" @clear="load" @keyup.enter="load">
          <template #prefix><el-icon><Search /></el-icon></template>
        </el-input>
        <el-select v-model="statusFilter" placeholder="状态" clearable @change="load" style="width:120px">
          <el-option label="在线" value="online" /><el-option label="离线" value="offline" />
        </el-select>
      </div>
    </div>
    <el-tabs v-model="tab">
      <el-tab-pane label="终端列表" name="list">
        <el-table :data="filteredClients" v-loading="loading" border stripe size="small">
          <el-table-column type="selection" width="40" />
          <el-table-column prop="name" label="终端名称" width="160" />
          <el-table-column prop="ip" label="IP地址" width="130" />
          <el-table-column prop="mac" label="MAC地址" width="140" />
          <el-table-column prop="type" label="终端类型" width="100">
            <template #default="{ row }"><el-tag size="small">{{ row.type || 'TC' }}</el-tag></template>
          </el-table-column>
          <el-table-column prop="os" label="操作系统" width="120" />
          <el-table-column prop="status" label="状态" width="80">
            <template #default="{ row }"><el-tag :type="row.status === 'online' ? 'success' : 'info'" size="small">{{ row.status === 'online' ? '在线' : '离线' }}</el-tag></template>
          </el-table-column>
          <el-table-column prop="user" label="当前用户" width="100" />
          <el-table-column prop="last_seen" label="最后活动" width="160" />
          <el-table-column label="操作" width="200" fixed="right">
            <template #default="{ row }">
              <el-button size="small" @click="showDetail(row)">详情</el-button>
              <el-button size="small" @click="sendCommand(row, 'restart')">重启</el-button>
              <el-button size="small" @click="sendCommand(row, 'shutdown')">关机</el-button>
            </template>
          </el-table-column>
        </el-table>
      </el-tab-pane>
      <el-tab-pane label="终端任务" name="tasks">
        <el-table :data="tasks" border stripe size="small">
          <el-table-column prop="id" label="ID" width="60" />
          <el-table-column prop="type" label="任务类型" width="120" />
          <el-table-column prop="target" label="目标终端" width="140" />
          <el-table-column prop="status" label="状态" width="90">
            <template #default="{ row }"><el-tag :type="row.status === 'completed' ? 'success' : row.status === 'failed' ? 'danger' : 'info'" size="small">{{ row.status }}</el-tag></template>
          </el-table-column>
          <el-table-column prop="message" label="描述" min-width="200" />
          <el-table-column prop="created_at" label="创建时间" width="160" />
        </el-table>
      </el-tab-pane>
    </el-tabs>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import api from '../api'
import { ElMessage } from 'element-plus'

const loading = ref(false)
const tab = ref('list')
const clients = ref([]), tasks = ref([])
const search = ref(''), statusFilter = ref('')

const filteredClients = computed(() => {
  let list = clients.value
  if (search.value) {
    const s = search.value.toLowerCase()
    list = list.filter(c => c.name.toLowerCase().includes(s) || c.ip.includes(s))
  }
  if (statusFilter.value) list = list.filter(c => c.status === statusFilter.value)
  return list
})

async function load() {
  loading.value = true
  try {
    const [cRes, tRes] = await Promise.all([
      api.get('/clients'),
      api.get('/clients/tasks/list').catch(() => ({ data: [] }))
    ])
    clients.value = cRes.data || []
    tasks.value = tRes.data || []
  } catch (e) { clients.value = []; tasks.value = [] }
  finally { loading.value = false }
}

function showDetail(c) { ElMessage.info(`终端 ${c.name} 详情页开发中`) }
async function sendCommand(c, cmd) {
  try {
    await api.post(`/clients/${c.id}/action`, { action: cmd })
    ElMessage.success(`已向 ${c.name} 发送 ${cmd} 命令`)
  } catch (e) { ElMessage.error('命令发送失败') }
}

onMounted(load)
</script>
