<template>
  <div>
    <div class="page-header">
      <h2>黄金镜像</h2>
      <div style="display: flex; gap: 8px; align-items: center;">
        <el-input v-model="search" placeholder="搜索镜像名称" clearable style="width: 200px;" @clear="load" @keyup.enter="load">
          <template #prefix><el-icon><Search /></el-icon></template>
        </el-input>
        <el-select v-model="statusFilter" placeholder="状态" clearable @change="load" style="width: 110px;">
          <el-option label="草稿" value="draft" /><el-option label="已发布" value="published" /><el-option label="维护中" value="maintaining" />
        </el-select>
        <el-button type="primary" @click="showDialog()"><el-icon><Plus /></el-icon>创建镜像</el-button>
        <el-button @click="showExtractDialog"><el-icon><DocumentCopy /></el-icon>从虚拟机提取</el-button>
      </div>
    </div>

    <el-tabs v-model="mainTab">
      <el-tab-pane label="镜像列表" name="list">
        <el-table :data="filteredTpls" v-loading="loading" border stripe>
          <el-table-column prop="name" label="镜像名称" width="180" show-overflow-tooltip />
          <el-table-column prop="title" label="显示名称" width="140" show-overflow-tooltip />
          <el-table-column prop="os_type" label="系统类型" width="90">
            <template #default="{ row }">
              <el-tag size="small" :type="row.os_type === 'windows' ? '' : 'success'">{{ row.os_type === 'windows' ? 'Windows' : 'Linux' }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="os_version" label="系统版本" width="140" show-overflow-tooltip />
          <el-table-column prop="arch" label="架构" width="80" />
          <el-table-column label="配置" width="140">
            <template #default="{ row }">{{ row.cpu }}核 / {{ (row.memory / 1024).toFixed(0) }}GB / {{ row.disk }}GB</template>
          </el-table-column>
          <el-table-column prop="version" label="版本" width="70">
            <template #default="{ row }">v{{ row.version || 1 }}</template>
          </el-table-column>
          <el-table-column prop="status" label="状态" width="90">
            <template #default="{ row }">
              <el-tag :type="statusType(row.status)" size="small">{{ statusText(row.status) }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="run_mode" label="运行模式" width="80" />
          <el-table-column prop="vm_count" label="关联VM" width="70" />
          <el-table-column prop="created_at" label="创建时间" width="155" />
          <el-table-column label="操作" width="300" fixed="right">
            <template #default="{ row }">
              <el-button size="small" @click="showDialog(row)">编辑</el-button>
              <el-button size="small" type="info" @click="showVersions(row)">版本</el-button>
              <el-button size="small" type="success" v-if="row.status === 'draft' || row.status === 'maintaining'" @click="publishTpl(row)">发布</el-button>
              <el-button size="small" type="warning" v-if="row.status === 'published'" @click="maintainTpl(row)">维护</el-button>
              <el-button size="small" type="danger" @click="deleteTpl(row)">删除</el-button>
            </template>
          </el-table-column>
        </el-table>
      </el-tab-pane>

      <el-tab-pane label="版本历史" name="versions">
        <div style="margin-bottom: 12px; display: flex; justify-content: space-between; align-items: center;">
          <div v-if="selectedTpl">
            <el-tag type="primary" size="large">{{ selectedTpl.title || selectedTpl.name }}</el-tag>
            <span style="margin-left: 10px; color: #909399;">当前版本: v{{ selectedTpl.version || 1 }}</span>
          </div>
          <div v-else><span style="color: #909399;">请在镜像列表中点击"版本"按钮查看</span></div>
          <el-button type="primary" size="small" @click="showCreateVersion" :disabled="!selectedTpl"><el-icon><Plus /></el-icon>创建版本快照</el-button>
        </div>
        <el-table :data="versions" v-loading="versionsLoading" border stripe size="small" empty-text="暂无版本记录">
          <el-table-column prop="version" label="版本号" width="90">
            <template #default="{ row }"><el-tag>v{{ row.version }}</el-tag></template>
          </el-table-column>
          <el-table-column prop="description" label="描述" min-width="200" show-overflow-tooltip />
          <el-table-column prop="snapshot_name" label="快照名称" width="200" show-overflow-tooltip />
          <el-table-column prop="created_by" label="创建人" width="100" />
          <el-table-column prop="created_at" label="创建时间" width="170" />
          <el-table-column label="操作" width="160" fixed="right">
            <template #default="{ row }">
              <el-button size="small" type="warning" @click="rollbackVersion(row)">回滚</el-button>
              <el-button size="small" type="danger" @click="deleteVersion(row)">删除</el-button>
            </template>
          </el-table-column>
        </el-table>
      </el-tab-pane>
    </el-tabs>

    <!-- 创建/编辑镜像对话框 -->
    <el-dialog v-model="dialogVisible" :title="editing ? '编辑镜像' : '创建黄金镜像'" width="620px">
      <el-steps :active="wizardStep" simple style="margin-bottom: 20px;" v-if="!editing">
        <el-step title="基本信息" /><el-step title="系统配置" /><el-step title="资源配置" /><el-step title="高级选项" />
      </el-steps>

      <el-form :model="form" label-width="100px" v-show="editing || wizardStep === 0">
        <el-form-item label="镜像名称" required><el-input v-model="form.name" placeholder="英文标识名" /></el-form-item>
        <el-form-item label="显示名称"><el-input v-model="form.title" placeholder="中文显示名（可选）" /></el-form-item>
        <el-form-item label="描述"><el-input v-model="form.description" type="textarea" :rows="2" /></el-form-item>
      </el-form>
      <el-form :model="form" label-width="100px" v-show="editing || wizardStep === 1">
        <el-form-item label="系统类型">
          <el-select v-model="form.os_type" style="width: 100%;">
            <el-option label="Linux" value="linux" /><el-option label="Windows" value="windows" />
          </el-select>
        </el-form-item>
        <el-form-item label="系统版本"><el-input v-model="form.os_version" placeholder="如 Kylin V10 SP1" /></el-form-item>
        <el-form-item label="架构">
          <el-select v-model="form.arch" style="width: 100%;">
            <el-option label="x86_64" value="x86_64" /><el-option label="aarch64" value="aarch64" />
          </el-select>
        </el-form-item>
      </el-form>
      <el-form :model="form" label-width="100px" v-show="editing || wizardStep === 2">
        <el-row :gutter="16">
          <el-col :span="8"><el-form-item label="CPU(核)"><el-input-number v-model="form.cpu" :min="1" :max="64" style="width:100%;" /></el-form-item></el-col>
          <el-col :span="8"><el-form-item label="内存(MB)"><el-input-number v-model="form.memory" :min="512" :max="131072" :step="512" style="width:100%;" /></el-form-item></el-col>
          <el-col :span="8"><el-form-item label="磁盘(GB)"><el-input-number v-model="form.disk" :min="10" :max="2048" style="width:100%;" /></el-form-item></el-col>
        </el-row>
      </el-form>
      <el-form :model="form" label-width="100px" v-show="editing || wizardStep === 3">
        <el-form-item label="运行模式">
          <el-select v-model="form.run_mode" style="width: 100%;">
            <el-option label="VDI" value="VDI" /><el-option label="VOI" value="VOI" /><el-option label="IDV" value="IDV" />
          </el-select>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button v-if="!editing && wizardStep > 0" @click="wizardStep--">上一步</el-button>
        <el-button v-if="!editing && wizardStep < 3" type="primary" @click="wizardStep++">下一步</el-button>
        <el-button v-if="editing || wizardStep === 3" type="primary" :loading="saving" @click="saveTpl">{{ editing ? '保存' : '创建' }}</el-button>
      </template>
    </el-dialog>

    <!-- 从VM提取镜像 -->
    <el-dialog v-model="extractVisible" title="从虚拟机提取镜像" width="450px">
      <el-form label-width="90px">
        <el-form-item label="选择虚拟机">
          <el-select v-model="extractVmId" style="width: 100%;" filterable placeholder="搜索虚拟机">
            <el-option v-for="v in vmList" :key="v.id" :label="`${v.name} (${v.ip || '-'})`" :value="v.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="镜像名称"><el-input v-model="extractName" /></el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="extractVisible = false">取消</el-button>
        <el-button type="primary" @click="doExtract">提取</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted } from 'vue'
import api from '../api'
import { ElMessage, ElMessageBox } from 'element-plus'

const loading = ref(false), saving = ref(false), dialogVisible = ref(false), editing = ref(null)
const extractVisible = ref(false), extractVmId = ref(''), extractName = ref('')
const vmList = ref([])
const templates = ref([])
const search = ref(''), statusFilter = ref('')
const wizardStep = ref(0)
const mainTab = ref('list')
const selectedTpl = ref(null), versions = ref([]), versionsLoading = ref(false)
const versionDesc = ref('')
const form = reactive({ name: '', title: '', os_type: 'linux', os_version: '', arch: 'x86_64', cpu: 2, memory: 2048, disk: 40, run_mode: 'VDI', description: '' })

function statusType(s) { return { draft: 'info', published: 'success', maintaining: 'warning' }[s] || 'info' }
function statusText(s) { return { draft: '草稿', published: '已发布', maintaining: '维护中' }[s] || s }

const filteredTpls = computed(() => {
  let list = templates.value
  if (search.value) { const s = search.value.toLowerCase(); list = list.filter(t => t.name.toLowerCase().includes(s) || (t.title || '').toLowerCase().includes(s)) }
  if (statusFilter.value) list = list.filter(t => t.status === statusFilter.value)
  return list
})

async function load() {
  loading.value = true
  try { templates.value = (await api.get('/templates')).data } finally { loading.value = false }
}

function showDialog(tpl) {
  editing.value = tpl || null; wizardStep.value = 0
  if (tpl) Object.assign(form, { name: tpl.name, title: tpl.title || '', os_type: tpl.os_type, os_version: tpl.os_version, arch: tpl.arch, cpu: tpl.cpu, memory: tpl.memory, disk: tpl.disk, run_mode: tpl.run_mode, description: tpl.description || '' })
  else Object.assign(form, { name: '', title: '', os_type: 'linux', os_version: '', arch: 'x86_64', cpu: 2, memory: 2048, disk: 40, run_mode: 'VDI', description: '' })
  dialogVisible.value = true
}

async function showExtractDialog() {
  if (!vmList.value.length) { const res = await api.get('/vms'); vmList.value = res.data }
  extractVmId.value = ''; extractName.value = ''
  extractVisible.value = true
}

async function doExtract() {
  await api.post('/templates/extract-from-vm', { vm_id: extractVmId.value, name: extractName.value })
  ElMessage.success('镜像提取成功'); extractVisible.value = false; load()
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

// 版本管理
async function showVersions(tpl) {
  selectedTpl.value = tpl
  mainTab.value = 'versions'
  await loadVersions()
}

async function loadVersions() {
  if (!selectedTpl.value) return
  versionsLoading.value = true
  try {
    versions.value = (await api.get(`/templates/${selectedTpl.value.id}/versions`)).data || []
  } finally { versionsLoading.value = false }
}

async function showCreateVersion() {
  const { value } = await ElMessageBox.prompt('请输入版本描述', '创建版本快照', { inputPlaceholder: '例如：修复桌面配置问题' })
  await api.post(`/templates/${selectedTpl.value.id}/versions`, { description: value })
  ElMessage.success('版本快照已创建')
  await loadVersions()
  load()
}

async function rollbackVersion(ver) {
  await ElMessageBox.confirm(`确认回滚到版本 v${ver.version}?`, '版本回滚', { type: 'warning' })
  await api.post(`/templates/${selectedTpl.value.id}/versions/${ver.id}/rollback`)
  ElMessage.success(`已回滚到 v${ver.version}`)
  const tpl = await api.get(`/templates/${selectedTpl.value.id}`)
  selectedTpl.value = tpl
  load()
}

async function deleteVersion(ver) {
  await ElMessageBox.confirm(`确认删除版本 v${ver.version}?`, '警告', { type: 'warning' })
  await api.delete(`/templates/${selectedTpl.value.id}/versions/${ver.id}`)
  ElMessage.success('版本已删除')
  await loadVersions()
}

onMounted(load)
</script>
