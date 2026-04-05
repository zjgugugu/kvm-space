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
import { ElMessage, ElMessageBox } from 'element-plus'

const loading = ref(false)
const selected = ref([])
const tableData = ref([])

function loadData() {
  loading.value = true
  tableData.value = [
    { id: 1, name: 'zombie-vm-001', uuid: 'a1b2c3d4-e5f6-7890-abcd-ef0123456789', host: 'host-01', last_seen: '2025-01-10 14:30', reason: '宿主机下线' },
    { id: 2, name: 'zombie-vm-002', uuid: 'b2c3d4e5-f6a7-8901-bcde-f01234567890', host: 'host-02', last_seen: '2025-01-08 09:15', reason: '存储丢失' },
    { id: 3, name: 'orphan-disk-vm', uuid: 'c3d4e5f6-a7b8-9012-cdef-012345678901', host: 'host-01', last_seen: '2025-01-05 18:00', reason: '磁盘不可达' },
  ]
  loading.value = false
}

async function cleanOne(row) {
  await ElMessageBox.confirm(`确定清理僵尸虚拟机 "${row.name}" ?`, '确认清理')
  tableData.value = tableData.value.filter(r => r.id !== row.id)
  ElMessage.success('已清理')
}

async function batchClean() {
  await ElMessageBox.confirm(`确定清理选中的 ${selected.value.length} 台僵尸虚拟机?`, '确认批量清理')
  const ids = new Set(selected.value.map(r => r.id))
  tableData.value = tableData.value.filter(r => !ids.has(r.id))
  selected.value = []
  ElMessage.success('批量清理完成')
}

onMounted(loadData)
</script>
