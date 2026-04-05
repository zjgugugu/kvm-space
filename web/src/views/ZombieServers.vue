<template>
  <div>
    <div class="page-header">
      <h2>僵尸云服务器</h2>
      <div>
        <el-button type="danger" :disabled="!selected.length" @click="batchClean">
          批量清理 ({{ selected.length }})
        </el-button>
        <el-button @click="loadData">
          <el-icon><Refresh /></el-icon> 刷新
        </el-button>
        <el-button type="primary" @click="scanZombies">扫描僵尸服务器</el-button>
      </div>
    </div>

    <el-alert type="warning" :closable="false" style="margin-bottom: 16px;">
      僵尸云服务器是指底层资源已不存在但数据库中仍有记录的虚拟机。建议定期清理以释放数据库空间。
    </el-alert>

    <el-card shadow="hover">
      <el-table :data="tableData" border stripe v-loading="loading" @selection-change="sel => selected = sel">
        <el-table-column type="selection" width="50" />
        <el-table-column prop="name" label="虚拟机名称" min-width="150" />
        <el-table-column prop="uuid" label="UUID" min-width="250" />
        <el-table-column prop="host" label="原宿主机" width="140" />
        <el-table-column prop="last_seen" label="最后活跃" width="160" />
        <el-table-column prop="reason" label="原因" width="140">
          <template #default="{ row }">
            <el-tag type="danger">{{ row.reason }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="140">
          <template #default="{ row }">
            <el-button size="small" type="danger" @click="cleanOne(row)">清理</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { Refresh } from '@element-plus/icons-vue'
import api from '../api'
import { ElMessage, ElMessageBox } from 'element-plus'

const loading = ref(false)
const selected = ref([])
const tableData = ref([])

async function loadData() {
  loading.value = true
  try { tableData.value = (await api.get('/system-extra/zombie-servers')).data || [] }
  catch (e) { tableData.value = [] }
  finally { loading.value = false }
}

async function scanZombies() {
  loading.value = true
  try {
    const res = await api.post('/system-extra/zombie-servers/scan')
    ElMessage.success(res.data?.message || '扫描完成')
    await loadData()
  } catch (e) { ElMessage.error('扫描失败'); loading.value = false }
}

async function cleanOne(row) {
  await ElMessageBox.confirm(`确定清理僵尸虚拟机 "${row.vm_name || row.name}" ?`, '确认清理')
  await api.delete(`/system-extra/zombie-servers/${row.id}`)
  ElMessage.success('已清理'); loadData()
}

async function batchClean() {
  await ElMessageBox.confirm(`确定清理选中的 ${selected.value.length} 台僵尸虚拟机?`, '确认批量清理')
  for (const r of selected.value) { await api.delete(`/system-extra/zombie-servers/${r.id}`) }
  selected.value = []
  ElMessage.success('批量清理完成'); loadData()
}

onMounted(loadData)
</script>
