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
import api from '../api'
import { ElMessage, ElMessageBox } from 'element-plus'

const loading = ref(false)
const items = ref([])
const selected = ref([])

function typeText(t) { return { vm: '虚拟机', template: '模板', network: '网络', storage: '存储' }[t] || t }
function onSelect(rows) { selected.value = rows }

async function load() {
  loading.value = true
  try { items.value = (await api.get('/recycle-bin')).data || [] }
  catch (e) { items.value = [] }
  finally { loading.value = false }
}

async function restoreItem(item) {
  await ElMessageBox.confirm(`确认恢复 ${item.name || item.resource_name}?`, '恢复', { type: 'info' })
  await api.post(`/recycle-bin/${item.id}/restore`)
  ElMessage.success('已恢复'); load()
}

async function purgeItem(item) {
  await ElMessageBox.confirm(`彻底删除 ${item.name || item.resource_name}？此操作不可恢复!`, '警告', { type: 'warning' })
  await api.delete(`/recycle-bin/${item.id}`)
  ElMessage.success('已彻底删除'); load()
}

async function restoreAll() {
  await ElMessageBox.confirm(`确认恢复选中的 ${selected.value.length} 项?`)
  for (const s of selected.value) { await api.post(`/recycle-bin/${s.id}/restore`) }
  ElMessage.success('批量恢复完成'); load()
}

async function purgeAll() {
  await ElMessageBox.confirm(`确认彻底删除选中的 ${selected.value.length} 项?`, '警告', { type: 'warning' })
  for (const s of selected.value) { await api.delete(`/recycle-bin/${s.id}`) }
  ElMessage.success('批量删除完成'); load()
}

onMounted(load)
</script>
