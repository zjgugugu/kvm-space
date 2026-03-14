<template>
  <div>
    <div class="page-header">
      <h2>黄金镜像</h2>
      <el-button type="primary" @click="showDialog()"><el-icon><Plus /></el-icon>创建镜像</el-button>
    </div>
    <el-table :data="templates" v-loading="loading" border stripe>
      <el-table-column prop="name" label="名称" width="200" />
      <el-table-column prop="os_type" label="系统类型" width="100">
        <template #default="{ row }">{{ row.os_type === 'windows' ? 'Windows' : 'Linux' }}</template>
      </el-table-column>
      <el-table-column prop="os_version" label="系统版本" width="150" />
      <el-table-column prop="arch" label="架构" width="80" />
      <el-table-column label="配置" width="150">
        <template #default="{ row }">{{ row.cpu }}核 / {{ (row.memory / 1024).toFixed(0) }}GB / {{ row.disk }}GB</template>
      </el-table-column>
      <el-table-column prop="status" label="状态" width="100">
        <template #default="{ row }">
          <el-tag :type="statusType(row.status)" size="small">{{ statusText(row.status) }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="run_mode" label="运行模式" width="80" />
      <el-table-column prop="created_at" label="创建时间" min-width="160" />
      <el-table-column label="操作" width="280" fixed="right">
        <template #default="{ row }">
          <el-button size="small" @click="showDialog(row)">编辑</el-button>
          <el-button size="small" type="success" v-if="row.status === 'draft' || row.status === 'maintaining'" @click="publishTpl(row)">发布</el-button>
          <el-button size="small" type="warning" v-if="row.status === 'published'" @click="maintainTpl(row)">维护</el-button>
          <el-button size="small" type="danger" @click="deleteTpl(row)">删除</el-button>
        </template>
      </el-table-column>
    </el-table>

    <el-dialog v-model="dialogVisible" :title="editing ? '编辑镜像' : '创建镜像'" width="550px">
      <el-form :model="form" label-width="90px">
        <el-form-item label="名称"><el-input v-model="form.name" /></el-form-item>
        <el-form-item label="系统类型">
          <el-select v-model="form.os_type" style="width: 100%;">
            <el-option label="Linux" value="linux" /><el-option label="Windows" value="windows" />
          </el-select>
        </el-form-item>
        <el-form-item label="系统版本"><el-input v-model="form.os_version" /></el-form-item>
        <el-form-item label="架构">
          <el-select v-model="form.arch" style="width: 100%;">
            <el-option label="x86_64" value="x86_64" /><el-option label="aarch64" value="aarch64" />
          </el-select>
        </el-form-item>
        <el-form-item label="CPU(核)"><el-input-number v-model="form.cpu" :min="1" :max="64" /></el-form-item>
        <el-form-item label="内存(MB)"><el-input-number v-model="form.memory" :min="512" :max="131072" :step="512" /></el-form-item>
        <el-form-item label="磁盘(GB)"><el-input-number v-model="form.disk" :min="10" :max="2048" /></el-form-item>
        <el-form-item label="运行模式">
          <el-select v-model="form.run_mode" style="width: 100%;">
            <el-option label="VDI" value="VDI" /><el-option label="VOI" value="VOI" /><el-option label="IDV" value="IDV" />
          </el-select>
        </el-form-item>
        <el-form-item label="描述"><el-input v-model="form.description" type="textarea" :rows="2" /></el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="saving" @click="saveTpl">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import api from '../api'
import { ElMessage, ElMessageBox } from 'element-plus'

const loading = ref(false), saving = ref(false), dialogVisible = ref(false), editing = ref(null)
const templates = ref([])
const form = reactive({ name: '', os_type: 'linux', os_version: '', arch: 'x86_64', cpu: 2, memory: 2048, disk: 40, run_mode: 'VDI', description: '' })

function statusType(s) { return { draft: 'info', published: 'success', maintaining: 'warning' }[s] || 'info' }
function statusText(s) { return { draft: '草稿', published: '已发布', maintaining: '维护中' }[s] || s }

async function load() {
  loading.value = true
  try { templates.value = (await api.get('/templates')).data } finally { loading.value = false }
}

function showDialog(tpl) {
  editing.value = tpl || null
  if (tpl) Object.assign(form, { name: tpl.name, os_type: tpl.os_type, os_version: tpl.os_version, arch: tpl.arch, cpu: tpl.cpu, memory: tpl.memory, disk: tpl.disk, run_mode: tpl.run_mode, description: tpl.description || '' })
  else Object.assign(form, { name: '', os_type: 'linux', os_version: '', arch: 'x86_64', cpu: 2, memory: 2048, disk: 40, run_mode: 'VDI', description: '' })
  dialogVisible.value = true
}

async function saveTpl() {
  saving.value = true
  try {
    if (editing.value) await api.put(`/templates/${editing.value.id}`, form)
    else await api.post('/templates', form)
    ElMessage.success('保存成功'); dialogVisible.value = false; load()
  } finally { saving.value = false }
}

async function publishTpl(tpl) { await api.post(`/templates/${tpl.id}/publish`); ElMessage.success('已发布'); load() }
async function maintainTpl(tpl) { await api.post(`/templates/${tpl.id}/maintain`); ElMessage.success('已进入维护模式'); load() }
async function deleteTpl(tpl) {
  await ElMessageBox.confirm(`确认删除镜像 ${tpl.name}?`, '警告', { type: 'warning' })
  await api.delete(`/templates/${tpl.id}`); ElMessage.success('已删除'); load()
}

onMounted(load)
</script>
