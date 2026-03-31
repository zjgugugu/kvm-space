<template>
  <div>
    <div style="display: flex; justify-content: space-between; margin-bottom: 16px;">
      <div style="display: flex; gap: 12px;">
        <el-select v-model="statusFilter" placeholder="任务状态" clearable style="width: 130px;" @change="load">
          <el-option label="待处理" value="pending" />
          <el-option label="进行中" value="running" />
          <el-option label="已完成" value="completed" />
          <el-option label="已失败" value="failed" />
        </el-select>
        <el-select v-model="typeFilter" placeholder="任务类型" clearable style="width: 150px;" @change="load">
          <el-option label="创建虚拟机" value="create_vm" />
          <el-option label="启动虚拟机" value="start_vm" />
          <el-option label="迁移虚拟机" value="migrate_vm" />
          <el-option label="克隆虚拟机" value="clone_vm" />
          <el-option label="创建快照" value="create_snapshot" />
          <el-option label="还原快照" value="revert_snapshot" />
          <el-option label="备份" value="backup" />
          <el-option label="还原备份" value="restore_backup" />
          <el-option label="提取模板" value="extract_template" />
          <el-option label="发布模板" value="publish_template" />
          <el-option label="还原虚拟机" value="restore_vm" />
        </el-select>
      </div>
      <el-button @click="load" :icon="Refresh">刷新</el-button>
    </div>

    <el-table :data="tasks" v-loading="loading" stripe>
      <el-table-column prop="type" label="任务类型" width="140">
        <template #default="{ row }">
          <el-tag :type="typeTag(row.type)" size="small">{{ typeText(row.type) }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="resource_name" label="资源名称" width="180" />
      <el-table-column prop="message" label="描述" min-width="200" show-overflow-tooltip />
      <el-table-column prop="status" label="状态" width="100">
        <template #default="{ row }">
          <el-tag :type="statusTag(row.status)" size="small">{{ statusText(row.status) }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="progress" label="进度" width="120">
        <template #default="{ row }">
          <el-progress :percentage="row.progress" :status="row.status === 'failed' ? 'exception' : row.status === 'completed' ? 'success' : ''" :stroke-width="6" />
        </template>
      </el-table-column>
      <el-table-column prop="user" label="执行人" width="100" />
      <el-table-column prop="created_at" label="创建时间" width="170" />
      <el-table-column prop="finished_at" label="完成时间" width="170" />
      <el-table-column label="操作" width="140" fixed="right">
        <template #default="{ row }">
          <el-button v-if="row.status === 'failed'" size="small" type="warning" @click="retryTask(row)">重试</el-button>
          <el-popconfirm title="确定删除此任务记录？" @confirm="deleteTask(row)">
            <template #reference>
              <el-button size="small" type="danger">删除</el-button>
            </template>
          </el-popconfirm>
        </template>
      </el-table-column>
    </el-table>

    <div style="display: flex; justify-content: flex-end; margin-top: 16px;" v-if="total > pageSize">
      <el-pagination background layout="total, prev, pager, next" :total="total" :page-size="pageSize" v-model:current-page="page" @current-change="load" />
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { Refresh } from '@element-plus/icons-vue'
import api from '../api'

const tasks = ref([])
const loading = ref(false)
const total = ref(0)
const page = ref(1)
const pageSize = 20
const statusFilter = ref('')
const typeFilter = ref('')

function statusTag(s) { return { pending: 'warning', running: '', completed: 'success', failed: 'danger' }[s] || 'info' }
function statusText(s) { return { pending: '待处理', running: '进行中', completed: '已完成', failed: '已失败' }[s] || s }
function typeTag(t) {
  if (t.includes('create') || t.includes('clone')) return 'success'
  if (t.includes('delete') || t.includes('restore')) return 'warning'
  if (t.includes('migrate')) return ''
  return 'info'
}
function typeText(t) {
  const m = { create_vm: '创建虚拟机', start_vm: '启动虚拟机', migrate_vm: '迁移虚拟机', clone_vm: '克隆虚拟机',
    create_snapshot: '创建快照', revert_snapshot: '还原快照', backup: '备份', restore_backup: '还原备份',
    extract_template: '提取模板', publish_template: '发布模板', restore_vm: '还原虚拟机' }
  return m[t] || t
}

async function load() {
  loading.value = true
  try {
    const params = { page: page.value, page_size: pageSize }
    if (statusFilter.value) params.status = statusFilter.value
    if (typeFilter.value) params.type = typeFilter.value
    const res = await api.get('/events/tasks', { params })
    tasks.value = res.data || []
    total.value = res.total || 0
  } catch (e) { ElMessage.error('加载失败') }
  loading.value = false
}

async function retryTask(task) {
  try {
    await api.post(`/events/tasks/${task.id}/retry`)
    ElMessage.success('任务已重新提交')
    load()
  } catch (e) { ElMessage.error(e.response?.data?.error || '重试失败') }
}

async function deleteTask(task) {
  try {
    await api.delete(`/events/tasks/${task.id}`)
    ElMessage.success('已删除')
    load()
  } catch (e) { ElMessage.error('删除失败') }
}

onMounted(load)
</script>
