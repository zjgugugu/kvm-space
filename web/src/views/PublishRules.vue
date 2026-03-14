<template>
  <div>
    <div class="page-header">
      <h2>发布规则</h2>
      <el-button type="primary" @click="showDialog()"><el-icon><Plus /></el-icon>创建规则</el-button>
    </div>
    <el-table :data="rules" v-loading="loading" border stripe>
      <el-table-column prop="name" label="规则名称" width="160" />
      <el-table-column prop="template_name" label="关联模板" width="160" />
      <el-table-column prop="spec_name" label="桌面规格" width="140" />
      <el-table-column prop="desktop_type" label="桌面类型" width="100">
        <template #default="{ row }">{{ row.desktop_type === 'static' ? '静态' : '动态' }}</template>
      </el-table-column>
      <el-table-column prop="target_name" label="目标" width="120" />
      <el-table-column prop="status" label="状态" width="80">
        <template #default="{ row }">
          <el-tag :type="row.status === 'active' ? 'success' : 'info'" size="small">{{ row.status === 'active' ? '启用' : '停用' }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="created_at" label="创建时间" min-width="160" />
      <el-table-column label="操作" width="200" fixed="right">
        <template #default="{ row }">
          <el-button size="small" @click="showDialog(row)">编辑</el-button>
          <el-button size="small" :type="row.status === 'active' ? 'warning' : 'success'" @click="toggle(row)">{{ row.status === 'active' ? '停用' : '启用' }}</el-button>
          <el-button size="small" type="danger" @click="del(row)">删除</el-button>
        </template>
      </el-table-column>
    </el-table>

    <el-dialog v-model="dialogVisible" :title="editing ? '编辑规则' : '创建规则'" width="550px">
      <el-form :model="form" label-width="90px">
        <el-form-item label="名称"><el-input v-model="form.name" /></el-form-item>
        <el-form-item label="关联模板">
          <el-select v-model="form.template_id" style="width: 100%;">
            <el-option v-for="t in tplList" :key="t.id" :label="t.name" :value="t.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="桌面规格">
          <el-select v-model="form.spec_id" style="width: 100%;">
            <el-option v-for="s in specList" :key="s.id" :label="s.name" :value="s.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="桌面类型">
          <el-select v-model="form.desktop_type" style="width: 100%;"><el-option label="动态" value="dynamic" /><el-option label="静态" value="static" /></el-select>
        </el-form-item>
        <el-form-item label="目标用户"><el-input v-model="form.target_name" /></el-form-item>
        <el-form-item label="自动开机"><el-switch v-model="form.auto_start" :active-value="1" :inactive-value="0" /></el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="saving" @click="save">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import api from '../api'
import { ElMessage, ElMessageBox } from 'element-plus'

const loading = ref(false), saving = ref(false), dialogVisible = ref(false), editing = ref(null)
const rules = ref([]), tplList = ref([]), specList = ref([])
const form = reactive({ name: '', template_id: '', spec_id: '', desktop_type: 'dynamic', target_name: '', auto_start: 0 })

async function load() { loading.value = true; try { rules.value = (await api.get('/publish-rules')).data } finally { loading.value = false } }

async function showDialog(r) {
  editing.value = r || null
  if (!tplList.value.length) tplList.value = (await api.get('/templates')).data
  if (!specList.value.length) specList.value = (await api.get('/specs')).data
  if (r) Object.assign(form, { name: r.name, template_id: r.template_id, spec_id: r.spec_id, desktop_type: r.desktop_type, target_name: r.target_name, auto_start: r.auto_start })
  else Object.assign(form, { name: '', template_id: '', spec_id: '', desktop_type: 'dynamic', target_name: '', auto_start: 0 })
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
  await api.put(`/publish-rules/${r.id}`, { status: ns }); ElMessage.success('操作成功'); load()
}

async function del(r) {
  await ElMessageBox.confirm(`确认删除规则 ${r.name}?`, '警告', { type: 'warning' })
  await api.delete(`/publish-rules/${r.id}`); ElMessage.success('已删除'); load()
}

onMounted(load)
</script>
