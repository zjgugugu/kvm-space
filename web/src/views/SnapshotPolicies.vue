<template>
  <div>
    <div class="page-header">
      <h2>快照策略</h2>
      <el-button type="primary" @click="showDialog()"><el-icon><Plus /></el-icon>新建</el-button>
    </div>
    <el-table :data="policies" v-loading="loading" border stripe size="small">
      <el-table-column prop="name" label="策略名称" width="180" />
      <el-table-column prop="description" label="描述" min-width="120" show-overflow-tooltip />
      <el-table-column prop="schedule" label="快照时间" width="150">
        <template #default="{ row }">{{ scheduleText(row) }}</template>
      </el-table-column>
      <el-table-column prop="max_snapshots" label="保留个数" width="100" />
      <el-table-column prop="vm_count" label="发布规则数" width="100" />
      <el-table-column prop="next_run" label="下次开始时间" width="160" />
      <el-table-column prop="enabled" label="生效" width="80">
        <template #default="{ row }">
          <el-tag :type="row.enabled ? 'success' : 'info'" size="small">{{ row.enabled ? '生效' : '失效' }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column label="操作" width="200" fixed="right">
        <template #default="{ row }">
          <el-button size="small" :type="row.enabled ? 'warning' : 'success'" @click="toggle(row)">{{ row.enabled ? '失效' : '生效' }}</el-button>
          <el-button size="small" type="danger" @click="remove(row)">删除</el-button>
        </template>
      </el-table-column>
    </el-table>

    <el-dialog v-model="dialogVisible" title="创建快照策略" width="500px">
      <el-form :model="form" label-width="100px">
        <el-form-item label="策略名称" required><el-input v-model="form.name" /></el-form-item>
        <el-form-item label="执行频率">
          <el-select v-model="form.frequency" style="width:100%">
            <el-option label="每天" value="daily" /><el-option label="每周" value="weekly" /><el-option label="每月" value="monthly" />
          </el-select>
        </el-form-item>
        <el-form-item label="执行时间"><el-time-picker v-model="form.time" format="HH:mm" value-format="HH:mm" /></el-form-item>
        <el-form-item label="最大快照数"><el-input-number v-model="form.max_snapshots" :min="1" :max="100" /></el-form-item>
        <el-form-item label="描述"><el-input v-model="form.description" type="textarea" :rows="2" /></el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="save">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import api from '../api'
import { ElMessage, ElMessageBox } from 'element-plus'

const loading = ref(false)
const policies = ref([])
const dialogVisible = ref(false)
const form = reactive({ name: '', frequency: 'daily', time: '02:00', max_snapshots: 10, description: '' })

function scheduleText(p) {
  const freq = { daily: '每天', weekly: '每周', monthly: '每月' }[p.frequency || p.schedule] || p.schedule || '未知'
  return `${freq} ${p.time || ''}`
}

async function load() {
  loading.value = true
  try { policies.value = (await api.get('/snapshot-policies')).data || [] }
  catch(e) { policies.value = [] }
  finally { loading.value = false }
}

function showDialog() {
  Object.assign(form, { name: '', frequency: 'daily', time: '02:00', max_snapshots: 10, description: '' })
  dialogVisible.value = true
}

async function save() {
  await api.post('/snapshot-policies', form)
  ElMessage.success('策略已创建'); dialogVisible.value = false; load()
}

async function toggle(p) {
  await api.post(`/snapshot-policies/${p.id}/toggle`, { enabled: !p.enabled })
  ElMessage.success(p.enabled ? '已禁用' : '已启用'); load()
}

async function remove(p) {
  await ElMessageBox.confirm(`确认删除策略 ${p.name}?`, '删除', { type: 'warning' })
  await api.delete(`/snapshot-policies/${p.id}`); ElMessage.success('已删除'); load()
}

onMounted(load)
</script>
