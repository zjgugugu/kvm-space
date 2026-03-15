<template>
  <div>
    <div class="page-header">
      <h2>发布规则</h2>
      <div style="display: flex; gap: 8px; align-items: center;">
        <el-input v-model="search" placeholder="搜索规则名称" clearable style="width: 180px;" @clear="load" @keyup.enter="load">
          <template #prefix><el-icon><Search /></el-icon></template>
        </el-input>
        <el-select v-model="statusFilter" placeholder="状态" clearable @change="load" style="width: 100px;">
          <el-option label="启用" value="active" /><el-option label="停用" value="disabled" />
        </el-select>
        <el-button type="primary" @click="showDialog()"><el-icon><Plus /></el-icon>创建规则</el-button>
      </div>
    </div>

    <el-row :gutter="12" style="margin-bottom: 12px;">
      <el-col :span="6"><el-statistic title="规则总数" :value="rules.length" /></el-col>
      <el-col :span="6"><el-statistic title="已启用" :value="rules.filter(r => r.status === 'active').length" /></el-col>
      <el-col :span="6"><el-statistic title="静态桌面" :value="rules.filter(r => r.desktop_type === 'static').length" /></el-col>
      <el-col :span="6"><el-statistic title="动态桌面" :value="rules.filter(r => r.desktop_type === 'dynamic').length" /></el-col>
    </el-row>

    <el-table :data="filteredRules" v-loading="loading" border stripe>
      <el-table-column prop="name" label="规则名称" width="160" />
      <el-table-column prop="template_name" label="黄金镜像" width="150" />
      <el-table-column prop="spec_name" label="桌面规格" width="130" />
      <el-table-column prop="desktop_type" label="桌面类型" width="90">
        <template #default="{ row }">
          <el-tag :type="row.desktop_type === 'static' ? '' : 'success'" size="small">{{ row.desktop_type === 'static' ? '静态' : '动态' }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="target_type" label="目标类型" width="90">
        <template #default="{ row }"><el-tag type="info" size="small">{{ targetTypeText(row.target_type) }}</el-tag></template>
      </el-table-column>
      <el-table-column prop="target_name" label="目标" width="120" />
      <el-table-column prop="max_count" label="最大桌面数" width="100" />
      <el-table-column prop="auto_start" label="自动开机" width="80">
        <template #default="{ row }"><el-tag :type="row.auto_start ? 'success' : 'info'" size="small">{{ row.auto_start ? '是' : '否' }}</el-tag></template>
      </el-table-column>
      <el-table-column prop="status" label="状态" width="80">
        <template #default="{ row }">
          <el-tag :type="row.status === 'active' ? 'success' : 'info'" size="small">{{ row.status === 'active' ? '启用' : '停用' }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="created_at" label="创建时间" width="155" />
      <el-table-column label="操作" width="210" fixed="right">
        <template #default="{ row }">
          <el-button size="small" @click="showDialog(row)">编辑</el-button>
          <el-button size="small" :type="row.status === 'active' ? 'warning' : 'success'" @click="toggle(row)">{{ row.status === 'active' ? '停用' : '启用' }}</el-button>
          <el-button size="small" type="danger" @click="del(row)">删除</el-button>
        </template>
      </el-table-column>
    </el-table>

    <el-dialog v-model="dialogVisible" :title="editing ? '编辑发布规则' : '创建发布规则'" width="580px">
      <el-form :model="form" label-width="100px">
        <el-form-item label="规则名称" required><el-input v-model="form.name" /></el-form-item>
        <el-form-item label="黄金镜像" required>
          <el-select v-model="form.template_id" style="width: 100%;" filterable placeholder="选择镜像">
            <el-option v-for="t in tplList" :key="t.id" :label="`${t.name} (${t.os_version})`" :value="t.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="桌面规格" required>
          <el-select v-model="form.spec_id" style="width: 100%;" filterable placeholder="选择规格">
            <el-option v-for="s in specList" :key="s.id" :label="`${s.name} (${s.cpu}C/${(s.memory/1024).toFixed(0)}G)`" :value="s.id" />
          </el-select>
        </el-form-item>
        <el-row :gutter="16">
          <el-col :span="12">
            <el-form-item label="桌面类型">
              <el-select v-model="form.desktop_type" style="width: 100%;">
                <el-option label="动态桌面" value="dynamic" /><el-option label="静态桌面" value="static" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="最大桌面数"><el-input-number v-model="form.max_count" :min="1" :max="500" style="width: 100%;" /></el-form-item>
          </el-col>
        </el-row>
        <el-row :gutter="16">
          <el-col :span="12">
            <el-form-item label="目标类型">
              <el-select v-model="form.target_type" style="width: 100%;">
                <el-option label="用户" value="user" /><el-option label="用户组" value="group" /><el-option label="组织单元" value="ou" />
              </el-select>
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="目标名称"><el-input v-model="form.target_name" placeholder="用户名/组名/OU" /></el-form-item>
          </el-col>
        </el-row>
        <el-form-item label="自动开机"><el-switch v-model="form.auto_start" :active-value="1" :inactive-value="0" /><span style="margin-left: 8px; color: #909399;">用户登录时自动启动桌面</span></el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="saving" @click="save">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted } from 'vue'
import api from '../api'
import { ElMessage, ElMessageBox } from 'element-plus'

const loading = ref(false), saving = ref(false), dialogVisible = ref(false), editing = ref(null)
const rules = ref([]), tplList = ref([]), specList = ref([])
const search = ref(''), statusFilter = ref('')
const form = reactive({ name: '', template_id: '', spec_id: '', desktop_type: 'dynamic', target_type: 'user', target_name: '', max_count: 10, auto_start: 0 })

function targetTypeText(t) { return { user: '用户', group: '用户组', ou: '组织单元' }[t] || t || '用户' }

const filteredRules = computed(() => {
  let list = rules.value
  if (search.value) { const s = search.value.toLowerCase(); list = list.filter(r => r.name.toLowerCase().includes(s)) }
  if (statusFilter.value) list = list.filter(r => r.status === statusFilter.value)
  return list
})

async function load() { loading.value = true; try { rules.value = (await api.get('/publish-rules')).data } finally { loading.value = false } }

async function showDialog(r) {
  editing.value = r || null
  if (!tplList.value.length) tplList.value = (await api.get('/templates')).data
  if (!specList.value.length) specList.value = (await api.get('/specs')).data
  if (r) Object.assign(form, { name: r.name, template_id: r.template_id, spec_id: r.spec_id, desktop_type: r.desktop_type, target_type: r.target_type || 'user', target_name: r.target_name, max_count: r.max_count || 10, auto_start: r.auto_start })
  else Object.assign(form, { name: '', template_id: '', spec_id: '', desktop_type: 'dynamic', target_type: 'user', target_name: '', max_count: 10, auto_start: 0 })
  dialogVisible.value = true
}

async function save() {
  saving.value = true
  try {
    if (editing.value) await api.put(`/publish-rules/${editing.value.id}`, form)
    else await api.post('/publish-rules', form)
    ElMessage.success('保存成功'); dialogVisible.value = false; load()
  } finally { saving.value = false }
}

async function toggle(r) {
  const ns = r.status === 'active' ? 'disabled' : 'active'
  await api.put(`/publish-rules/${r.id}/status`, { status: ns }); ElMessage.success('操作成功'); load()
}

async function del(r) {
  await ElMessageBox.confirm(`确认删除规则 ${r.name}?`, '警告', { type: 'warning' })
  await api.delete(`/publish-rules/${r.id}`); ElMessage.success('已删除'); load()
}

onMounted(load)
</script>
