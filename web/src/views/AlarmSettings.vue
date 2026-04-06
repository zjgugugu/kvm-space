<template>
  <div>
    <div class="page-header">
      <h2>告警设置</h2>
      <el-button type="primary" @click="showDialog()"><el-icon><Plus /></el-icon>添加告警规则</el-button>
      <el-button @click="batchSave">保存</el-button>
    </div>
    <el-table :data="settings" v-loading="loading" border stripe size="small">
      <el-table-column prop="name" label="告警名称" width="200">
        <template #default="{ row }">{{ row.name || row.metric || '未命名' }}</template>
      </el-table-column>
      <el-table-column label="紧急阈值(0为禁用)" width="160">
        <template #default="{ row }"><el-input-number v-model="row.threshold_critical" :min="0" :max="100" size="small" style="width:120px" /></template>
      </el-table-column>
      <el-table-column label="严重阈值(0为禁用)" width="160">
        <template #default="{ row }"><el-input-number v-model="row.threshold_major" :min="0" :max="100" size="small" style="width:120px" /></template>
      </el-table-column>
      <el-table-column label="一般阈值(0为禁用)" width="160">
        <template #default="{ row }"><el-input-number v-model="row.threshold_minor" :min="0" :max="100" size="small" style="width:120px" /></template>
      </el-table-column>
      <el-table-column prop="enabled" label="状态" width="80">
        <template #default="{ row }"><el-switch :model-value="row.enabled !== false" size="small" @change="toggleEnabled(row, $event)" /></template>
      </el-table-column>
      <el-table-column label="操作" width="140" fixed="right">
        <template #default="{ row }">
          <el-button size="small" @click="showDialog(row)">编辑</el-button>
          <el-button size="small" type="danger" @click="remove(row)">删除</el-button>
        </template>
      </el-table-column>
    </el-table>

    <el-dialog v-model="dialogVisible" :title="editing ? '编辑告警规则' : '添加告警规则'" width="500px">
      <el-form :model="form" label-width="100px">
        <el-form-item label="规则名称" required><el-input v-model="form.name" /></el-form-item>
        <el-form-item label="监控类型">
          <el-select v-model="form.type" style="width:100%">
            <el-option label="CPU" value="cpu" /><el-option label="内存" value="memory" /><el-option label="磁盘" value="disk" />
            <el-option label="网络" value="network" /><el-option label="服务器" value="host" /><el-option label="虚拟机" value="vm" />
          </el-select>
        </el-form-item>
        <el-form-item label="指标"><el-input v-model="form.metric" placeholder="如: usage, io_wait" /></el-form-item>
        <el-form-item label="阈值"><el-input-number v-model="form.threshold" :min="0" :max="100" /></el-form-item>
        <el-form-item label="告警级别">
          <el-select v-model="form.level" style="width:100%">
            <el-option label="信息" value="info" /><el-option label="警告" value="warning" /><el-option label="严重" value="critical" />
          </el-select>
        </el-form-item>
        <el-form-item label="持续时间(分)"><el-input-number v-model="form.duration" :min="1" :max="60" /></el-form-item>
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
const settings = ref([])
const dialogVisible = ref(false), editing = ref(null)
const form = reactive({ name: '', type: 'cpu', metric: 'usage', threshold: 80, level: 'warning', duration: 5 })
const typeMap = { cpu: 'CPU', memory: '内存', disk: '磁盘', network: '网络', host: '服务器', vm: '虚拟机' }

function levelType(l) { return { info: 'info', warning: 'warning', critical: 'danger' }[l] || 'info' }

async function load() {
  loading.value = true
  try { settings.value = (await api.get('/alerts/settings')).data || [] }
  catch(e) { settings.value = [] }
  finally { loading.value = false }
}

function showDialog(s) {
  editing.value = s || null
  if (s) Object.assign(form, { name: s.name, type: s.type, metric: s.metric, threshold: s.threshold, level: s.level, duration: s.duration || 5 })
  else Object.assign(form, { name: '', type: 'cpu', metric: 'usage', threshold: 80, level: 'warning', duration: 5 })
  dialogVisible.value = true
}

async function save() {
  if (editing.value) await api.put(`/alerts/settings/${editing.value.id}`, form)
  else await api.post('/alerts/settings', form)
  ElMessage.success('保存成功'); dialogVisible.value = false; load()
}

async function remove(s) {
  await ElMessageBox.confirm(`确认删除告警规则 ${s.name}?`, '删除', { type: 'warning' })
  await api.delete(`/alerts/settings/${s.id}`); ElMessage.success('已删除'); load()
}

async function toggleEnabled(s, val) {
  await api.put(`/alerts/settings/${s.id}`, { ...s, enabled: val })
  ElMessage.success(val ? '已启用' : '已禁用'); load()
}

onMounted(load)
async function batchSave() {
  try {
    for (const s of settings.value) {
      await api.put(`/alerts/settings/${s.id}`, {
        threshold_critical: s.threshold_critical || 0,
        threshold_major: s.threshold_major || 0,
        threshold_minor: s.threshold_minor || 0
      })
    }
    ElMessage.success('告警设置已保存')
  } catch(e) { ElMessage.error('保存失败: ' + e.message) }
}

</script>
