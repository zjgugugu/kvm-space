<template>
  <div>
    <div style="display: flex; justify-content: space-between; margin-bottom: 16px;">
      <el-radio-group v-model="statusFilter" @change="load">
        <el-radio-button label="">全部</el-radio-button>
        <el-radio-button label="pending">待审批</el-radio-button>
        <el-radio-button label="approved">已通过</el-radio-button>
        <el-radio-button label="rejected">已拒绝</el-radio-button>
      </el-radio-group>
      <el-button @click="load" :icon="Refresh">刷新</el-button>
    </div>

    <el-table :data="approvals" v-loading="loading" stripe>
      <el-table-column prop="type" label="审批类型" width="140">
        <template #default="{ row }">
          <el-tag size="small">{{ approvalTypeText(row.type) }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="resource_type" label="资源类型" width="100">
        <template #default="{ row }">{{ resourceTypeText(row.resource_type) }}</template>
      </el-table-column>
      <el-table-column prop="resource_name" label="资源名称" width="180" show-overflow-tooltip />
      <el-table-column prop="requester" label="申请人" width="100" />
      <el-table-column prop="status" label="状态" width="100">
        <template #default="{ row }">
          <el-tag :type="statusTag(row.status)" size="small">{{ statusText(row.status) }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="approver" label="审批人" width="100" />
      <el-table-column prop="reason" label="审批意见" min-width="180" show-overflow-tooltip />
      <el-table-column prop="created_at" label="申请时间" width="170" />
      <el-table-column prop="resolved_at" label="处理时间" width="170" />
      <el-table-column label="操作" width="160" fixed="right">
        <template #default="{ row }">
          <template v-if="row.status === 'pending'">
            <el-button size="small" type="success" @click="handleApproval(row, 'approve')">通过</el-button>
            <el-button size="small" type="danger" @click="handleApproval(row, 'reject')">拒绝</el-button>
          </template>
          <el-tag v-else :type="statusTag(row.status)" size="small">{{ statusText(row.status) }}</el-tag>
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
import { ElMessage, ElMessageBox } from 'element-plus'
import { Refresh } from '@element-plus/icons-vue'
import api from '../api'

const approvals = ref([])
const loading = ref(false)
const total = ref(0)
const page = ref(1)
const pageSize = 20
const statusFilter = ref('')

function statusTag(s) { return { pending: 'warning', approved: 'success', rejected: 'danger' }[s] || 'info' }
function statusText(s) { return { pending: '待审批', approved: '已通过', rejected: '已拒绝' }[s] || s }
function approvalTypeText(t) {
  const m = { create_vm: '创建虚拟机', delete_vm: '删除虚拟机', clone_vm: '克隆虚拟机',
    create_template: '创建模板', resource_request: '资源申请', config_change: '配置变更' }
  return m[t] || t
}
function resourceTypeText(t) {
  const m = { vm: '虚拟机', template: '模板', network: '网络', storage: '存储', host: '主机' }
  return m[t] || t
}

async function load() {
  loading.value = true
  try {
    const params = { page: page.value, page_size: pageSize }
    if (statusFilter.value) params.status = statusFilter.value
    const res = await api.get('/events/approvals', { params })
    approvals.value = res.data || []
    total.value = res.total || 0
  } catch (e) { ElMessage.error('加载失败') }
  loading.value = false
}

async function handleApproval(row, action) {
  try {
    const prompt = action === 'approve' ? '审批通过意见（选填）' : '拒绝原因'
    const { value } = await ElMessageBox.prompt(prompt, action === 'approve' ? '审批通过' : '审批拒绝', {
      confirmButtonText: '确定', cancelButtonText: '取消',
      inputPlaceholder: action === 'approve' ? '同意' : '请输入拒绝原因',
      type: action === 'approve' ? 'success' : 'warning'
    })
    await api.post(`/events/approvals/${row.id}/${action}`, { reason: value || (action === 'approve' ? '同意' : '') })
    ElMessage.success(action === 'approve' ? '已批准' : '已拒绝')
    load()
  } catch (e) {
    if (e !== 'cancel' && e?.message !== 'cancel') {
      ElMessage.error(e.response?.data?.error || '操作失败')
    }
  }
}

onMounted(load)
</script>
