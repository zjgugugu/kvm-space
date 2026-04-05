<template>
  <div>
    <div class="page-header">
      <h2>回收站</h2>
      <div style="display:flex;gap:8px;">
        <el-button type="primary" @click="restoreAll" :disabled="!selected.length"><el-icon><RefreshRight /></el-icon>批量恢复 ({{ selected.length }})</el-button>
        <el-button type="danger" @click="purgeAll" :disabled="!selected.length"><el-icon><Delete /></el-icon>彻底删除 ({{ selected.length }})</el-button>
      </div>
    </div>
    <el-table :data="items" v-loading="loading" border stripe size="small" @selection-change="onSelect">
      <el-table-column type="selection" width="40" />
      <el-table-column prop="name" label="资源名称" width="200" />
      <el-table-column prop="type" label="资源类型" width="120">
        <template #default="{ row }"><el-tag size="small">{{ typeText(row.type) }}</el-tag></template>
      </el-table-column>
      <el-table-column prop="deleted_by" label="删除用户" width="120" />
      <el-table-column prop="deleted_at" label="删除时间" width="160" />
      <el-table-column prop="expire_at" label="过期时间" width="160" />
      <el-table-column label="操作" width="160" fixed="right">
        <template #default="{ row }">
          <el-button size="small" type="primary" @click="restoreItem(row)">恢复</el-button>
          <el-button size="small" type="danger" @click="purgeItem(row)">彻底删除</el-button>
        </template>
      </el-table-column>
    </el-table>
    <el-empty v-if="!loading && !items.length" description="回收站为空" />
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'

const loading = ref(false)
const items = ref([])
const selected = ref([])

function typeText(t) { return { vm: '虚拟机', template: '模板', network: '网络', storage: '存储' }[t] || t }
function onSelect(rows) { selected.value = rows }

// Demo data - no backend API for recycle bin yet
const demoItems = [
  { id: 1, name: 'test-vm-old', type: 'vm', deleted_by: 'admin', deleted_at: '2024-01-10 14:30:00', expire_at: '2024-02-10 14:30:00' },
  { id: 2, name: 'unused-network', type: 'network', deleted_by: 'admin', deleted_at: '2024-01-12 09:00:00', expire_at: '2024-02-12 09:00:00' },
]

async function load() {
  loading.value = true
  items.value = demoItems
  loading.value = false
}

async function restoreItem(item) {
  await ElMessageBox.confirm(`确认恢复 ${item.name}?`, '恢复', { type: 'info' })
  items.value = items.value.filter(i => i.id !== item.id)
  ElMessage.success(`${item.name} 已恢复`)
}

async function purgeItem(item) {
  await ElMessageBox.confirm(`彻底删除 ${item.name}？此操作不可恢复!`, '警告', { type: 'warning' })
  items.value = items.value.filter(i => i.id !== item.id)
  ElMessage.success(`${item.name} 已彻底删除`)
}

async function restoreAll() {
  await ElMessageBox.confirm(`确认恢复选中的 ${selected.value.length} 项?`)
  const ids = selected.value.map(s => s.id)
  items.value = items.value.filter(i => !ids.includes(i.id))
  ElMessage.success('批量恢复完成')
}

async function purgeAll() {
  await ElMessageBox.confirm(`确认彻底删除选中的 ${selected.value.length} 项?`, '警告', { type: 'warning' })
  const ids = selected.value.map(s => s.id)
  items.value = items.value.filter(i => !ids.includes(i.id))
  ElMessage.success('批量删除完成')
}

onMounted(load)
</script>
