<template>
  <div>
    <div class="page-header">
      <h2>告警管理</h2>
      <div style="display: flex; gap: 8px; align-items: center;">
        <el-input v-model="search" placeholder="搜索告警信息/资源" clearable style="width: 200px;">
          <template #prefix><el-icon><Search /></el-icon></template>
        </el-input>
        <el-select v-model="levelFilter" placeholder="级别" clearable style="width: 110px;">
          <el-option label="严重" value="critical" /><el-option label="警告" value="warning" /><el-option label="信息" value="info" />
        </el-select>
        <el-button @click="batchAck" :disabled="!selectedAlerts.length">批量确认</el-button>
      </div>
    </div>
    <el-row :gutter="12" style="margin-bottom: 12px;">
      <el-col :span="6"><el-statistic title="活跃告警" :value="alerts.filter(a=>a.status==='active').length"><template #suffix><el-icon style="color:#F56C6C"><WarningFilled /></el-icon></template></el-statistic></el-col>
      <el-col :span="6"><el-statistic title="严重告警" :value="alerts.filter(a=>a.level==='critical'&&a.status==='active').length" /></el-col>
      <el-col :span="6"><el-statistic title="已确认" :value="alerts.filter(a=>a.status==='acknowledged').length" /></el-col>
      <el-col :span="6"><el-statistic title="历史总计" :value="history.length + alerts.length" /></el-col>
    </el-row>
    <el-tabs v-model="tab">
      <el-tab-pane label="活跃告警" name="active">
        <el-table :data="filteredAlerts" v-loading="loading" border stripe size="small" @selection-change="sel => selectedAlerts = sel">
          <el-table-column type="selection" width="40" />
          <el-table-column prop="created_at" label="时间" width="155" />
          <el-table-column prop="level" label="级别" width="70">
            <template #default="{ row }"><el-tag :type="row.level === 'critical' ? 'danger' : row.level === 'warning' ? 'warning' : 'info'" size="small">{{ levelText(row.level) }}</el-tag></template>
          </el-table-column>
          <el-table-column prop="type" label="类型" width="90" />
          <el-table-column prop="message" label="告警信息" min-width="200" show-overflow-tooltip />
          <el-table-column prop="resource_name" label="资源" width="120" />
          <el-table-column prop="status" label="状态" width="70">
            <template #default="{ row }"><el-tag :type="row.status === 'active' ? 'danger' : 'success'" size="small">{{ row.status === 'active' ? '活跃' : '已确认' }}</el-tag></template>
          </el-table-column>
          <el-table-column label="操作" width="100" fixed="right">
            <template #default="{ row }">
              <el-button v-if="row.status === 'active'" size="small" type="primary" @click="ack(row)">确认</el-button>
            </template>
          </el-table-column>
        </el-table>
      </el-tab-pane>
      <el-tab-pane label="历史记录" name="history">
        <el-table :data="history" border stripe size="small">
          <el-table-column prop="created_at" label="触发时间" width="155" />
          <el-table-column prop="level" label="级别" width="70">
            <template #default="{ row }"><el-tag :type="row.level === 'critical' ? 'danger' : row.level === 'warning' ? 'warning' : 'info'" size="small">{{ levelText(row.level) }}</el-tag></template>
          </el-table-column>
          <el-table-column prop="type" label="类型" width="90" />
          <el-table-column prop="message" label="告警信息" min-width="200" show-overflow-tooltip />
          <el-table-column prop="resource_name" label="资源" width="120" />
          <el-table-column prop="acknowledged_at" label="确认时间" width="155" />
          <el-table-column prop="resolved_at" label="恢复时间" width="155" />
        </el-table>
      </el-tab-pane>
      <el-tab-pane label="告警设置" name="settings">
        <div style="margin-bottom: 10px;"><el-button type="primary" size="small" @click="showSettingDialog()"><el-icon><Plus /></el-icon>添加规则</el-button></div>
        <el-table :data="settings" border stripe size="small">
          <el-table-column prop="name" label="监控项" width="150" />
          <el-table-column prop="type" label="类型" width="90" />
          <el-table-column prop="threshold" label="阈值" width="70" />
          <el-table-column prop="level" label="级别" width="70">
            <template #default="{ row }"><el-tag :type="row.level==='critical'?'danger':row.level==='warning'?'warning':'info'" size="small">{{ levelText(row.level) }}</el-tag></template>
          </el-table-column>
          <el-table-column prop="enabled" label="启用" width="70">
            <template #default="{ row }"><el-switch :model-value="!!row.enabled" @change="v => toggleSetting(row, v)" /></template>
          </el-table-column>
          <el-table-column prop="notify_method" label="通知方式" width="100">
            <template #default="{ row }">{{ row.notify_method || '站内' }}</template>
          </el-table-column>
          <el-table-column prop="description" label="描述" min-width="180" />
          <el-table-column label="操作" width="120">
            <template #default="{ row }">
              <el-button size="small" @click="showSettingDialog(row)">编辑</el-button>
              <el-button size="small" type="danger" @click="delSetting(row)">删除</el-button>
            </template>
          </el-table-column>
        </el-table>
      </el-tab-pane>
      <el-tab-pane label="通知规则" name="notify">
        <el-card shadow="never" style="max-width: 500px;">
          <template #header>通知渠道配置</template>
          <el-form :model="notifyConfig" label-width="90px">
            <el-form-item label="邮件通知"><el-switch v-model="notifyConfig.email" /></el-form-item>
            <el-form-item label="收件人" v-if="notifyConfig.email"><el-input v-model="notifyConfig.email_to" placeholder="admin@example.com" /></el-form-item>
            <el-form-item label="站内消息"><el-switch v-model="notifyConfig.internal" /></el-form-item>
            <el-form-item label="触发间隔">
              <el-select v-model="notifyConfig.interval" style="width: 100%;">
                <el-option label="立即" value="immediate" /><el-option label="5分钟" value="5m" /><el-option label="15分钟" value="15m" /><el-option label="1小时" value="1h" />
              </el-select>
            </el-form-item>
            <el-form-item><el-button type="primary" @click="saveNotify">保存</el-button></el-form-item>
          </el-form>
        </el-card>
      </el-tab-pane>
    </el-tabs>

    <!-- 告警设置对话框 -->
    <el-dialog v-model="settingDialogVisible" :title="editingSetting ? '编辑告警规则' : '添加告警规则'" width="450px">
      <el-form :model="settingForm" label-width="80px">
        <el-form-item label="名称"><el-input v-model="settingForm.name" /></el-form-item>
        <el-form-item label="类型">
          <el-select v-model="settingForm.type" style="width: 100%;">
            <el-option label="CPU" value="cpu" /><el-option label="内存" value="memory" /><el-option label="磁盘" value="disk" /><el-option label="网络" value="network" />
          </el-select>
        </el-form-item>
        <el-form-item label="阈值(%)"><el-input-number v-model="settingForm.threshold" :min="1" :max="100" style="width: 100%;" /></el-form-item>
        <el-form-item label="级别">
          <el-radio-group v-model="settingForm.level"><el-radio value="critical">严重</el-radio><el-radio value="warning">警告</el-radio><el-radio value="info">信息</el-radio></el-radio-group>
        </el-form-item>
        <el-form-item label="通知方式">
          <el-select v-model="settingForm.notify_method" style="width: 100%;">
            <el-option label="站内消息" value="internal" /><el-option label="邮件" value="email" /><el-option label="全部" value="all" />
          </el-select>
        </el-form-item>
        <el-form-item label="描述"><el-input v-model="settingForm.description" type="textarea" :rows="2" /></el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="settingDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="saveSetting">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted } from 'vue'
import api from '../api'
import { ElMessage, ElMessageBox } from 'element-plus'

const loading = ref(false), tab = ref('active'), search = ref(''), levelFilter = ref('')
const selectedAlerts = ref([])
const settingDialogVisible = ref(false), editingSetting = ref(null)
const settingForm = reactive({ name: '', type: 'cpu', threshold: 80, level: 'warning', notify_method: 'internal', description: '' })
const alerts = ref([]), settings = ref([]), history = ref([])
const notifyConfig = reactive({ email: false, email_to: '', internal: true, interval: 'immediate' })

function levelText(l) { return { critical: '严重', warning: '警告', info: '信息' }[l] || l }

const filteredAlerts = computed(() => {
  let list = alerts.value
  if (search.value) { const s = search.value.toLowerCase(); list = list.filter(a => (a.message || '').toLowerCase().includes(s) || (a.resource_name || '').toLowerCase().includes(s)) }
  if (levelFilter.value) list = list.filter(a => a.level === levelFilter.value)
  return list
})

async function load() {
  loading.value = true
  try {
    alerts.value = (await api.get('/alerts')).data || []
    settings.value = (await api.get('/alerts/settings')).data || []
    history.value = alerts.value.filter(a => a.status !== 'active')
    try {
      const nc = (await api.get('/system/notify-config')).data || {}
      if (nc.email !== undefined) notifyConfig.email = nc.email === 'true'
      if (nc.email_to) notifyConfig.email_to = nc.email_to
      if (nc.internal !== undefined) notifyConfig.internal = nc.internal !== 'false'
      if (nc.interval) notifyConfig.interval = nc.interval
    } catch(e) {}
  } catch(e) { alerts.value = []; settings.value = [] } finally { loading.value = false }
}

async function ack(a) {
  await api.post(`/alerts/${a.id}/acknowledge`); ElMessage.success('已确认'); load()
}

async function batchAck() {
  for (const a of selectedAlerts.value) { if (a.status === 'active') await api.post(`/alerts/${a.id}/acknowledge`) }
  ElMessage.success('批量确认完成'); load()
}

async function toggleSetting(s, v) {
  await api.put(`/alerts/settings/${s.id}`, { enabled: v ? 1 : 0 }); ElMessage.success('已更新'); load()
}

function showSettingDialog(s) {
  editingSetting.value = s || null
  if (s) Object.assign(settingForm, { name: s.name, type: s.type, threshold: s.threshold, level: s.level, notify_method: s.notify_method || 'internal', description: s.description || '' })
  else Object.assign(settingForm, { name: '', type: 'cpu', threshold: 80, level: 'warning', notify_method: 'internal', description: '' })
  settingDialogVisible.value = true
}
async function saveSetting() {
  if (editingSetting.value) {
    await api.put(`/alerts/settings/${editingSetting.value.id}`, settingForm)
  } else {
    await api.post('/alerts/settings', settingForm)
  }
  ElMessage.success('告警规则已保存'); settingDialogVisible.value = false; load()
}
async function delSetting(s) {
  await ElMessageBox.confirm(`确认删除规则 ${s.name}?`)
  await api.delete(`/alerts/settings/${s.id}`)
  ElMessage.success('已删除'); load()
}
async function saveNotify() {
  await api.put('/system/notify-config', { ...notifyConfig })
  ElMessage.success('通知配置已保存')
}

onMounted(load)
</script>
