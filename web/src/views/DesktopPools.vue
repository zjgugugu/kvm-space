<template>
  <div>
    <div class="page-header">
      <h2>桌面池</h2>
      <el-button type="primary" @click="showDialog()"><el-icon><Plus /></el-icon>创建桌面池</el-button>
    </div>
    <el-table :data="pools" v-loading="loading" border stripe size="small">
      <el-table-column prop="name" label="桌面池名称" width="180" />
      <el-table-column prop="type" label="类型" width="100">
        <template #default="{ row }"><el-tag size="small">{{ typeText(row.type) }}</el-tag></template>
      </el-table-column>
      <el-table-column prop="template_name" label="黄金镜像" width="150" />
      <el-table-column prop="spec_name" label="会话设置" width="120" />
      <el-table-column label="虚拟机数" width="180">
        <template #default="{ row }">
          <span>已创建: {{ row.vm_count || 0 }}</span>
          <span style="margin-left:8px;color:#909399;">/ 最大: {{ row.max_size || '-' }}</span>
        </template>
      </el-table-column>
      <el-table-column prop="status" label="状态" width="80">
        <template #default="{ row }"><el-tag :type="row.status === 'active' ? 'success' : 'info'" size="small">{{ row.status === 'active' ? '启用' : '停用' }}</el-tag></template>
      </el-table-column>
      <el-table-column prop="created_at" label="创建时间" width="160" />
      <el-table-column label="操作" width="200" fixed="right">
        <template #default="{ row }">
          <el-button size="small" @click="showDialog(row)">编辑</el-button>
          <el-button size="small" :type="row.status === 'active' ? 'warning' : 'success'" @click="togglePool(row)">{{ row.status === 'active' ? '停用' : '启用' }}</el-button>
          <el-button size="small" type="danger" @click="remove(row)">删除</el-button>
        </template>
      </el-table-column>
    </el-table>

    <el-dialog v-model="dialogVisible" :title="editing ? '编辑桌面池' : '创建桌面池'" width="550px">
      <el-form :model="form" label-width="100px">
        <el-form-item label="池名称" required><el-input v-model="form.name" /></el-form-item>
        <el-form-item label="池类型">
          <el-radio-group v-model="form.type">
            <el-radio value="static">静态池</el-radio>
            <el-radio value="dynamic">动态池</el-radio>
            <el-radio value="manual">手动池</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="黄金镜像">
          <el-select v-model="form.template_id" placeholder="选择镜像" style="width:100%">
            <el-option v-for="t in templates" :key="t.id" :label="t.name" :value="t.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="会话设置">
          <el-select v-model="form.spec_id" placeholder="选择设置" style="width:100%">
            <el-option v-for="s in specs" :key="s.id" :label="s.name" :value="s.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="最大数量" v-if="form.type === 'dynamic'"><el-input-number v-model="form.max_size" :min="1" :max="1000" /></el-form-item>
        <el-form-item label="预创建数" v-if="form.type === 'dynamic'"><el-input-number v-model="form.pre_create" :min="0" :max="100" /></el-form-item>
        <el-form-item label="命名前缀"><el-input v-model="form.name_prefix" placeholder="如: VDI-" /></el-form-item>
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
const pools = ref([]), templates = ref([]), specs = ref([])
const dialogVisible = ref(false), editing = ref(null)
const form = reactive({ name: '', type: 'static', template_id: '', spec_id: '', max_size: 10, pre_create: 0, name_prefix: 'VDI-', description: '' })

function typeText(t) { return { static: '静态池', dynamic: '动态池', manual: '手动池' }[t] || t }

async function load() {
  loading.value = true
  try {
    // Desktop pools use publish-rules API concept
    const [tpl, sp] = await Promise.all([api.get('/templates'), api.get('/specs')])
    templates.value = tpl.data || []
    specs.value = sp.data || []
    // Load pools from publish rules or dedicated endpoint
    try { pools.value = (await api.get('/publish-rules')).data || [] } catch(e) { pools.value = [] }
  } catch(e) {}
  finally { loading.value = false }
}

function showDialog(p) {
  editing.value = p || null
  if (p) Object.assign(form, { name: p.name, type: p.type || 'static', template_id: p.template_id, spec_id: p.spec_id, max_size: p.max_size || 10, pre_create: p.pre_create || 0, name_prefix: p.name_prefix || 'VDI-', description: p.description || '' })
  else Object.assign(form, { name: '', type: 'static', template_id: '', spec_id: '', max_size: 10, pre_create: 0, name_prefix: 'VDI-', description: '' })
  dialogVisible.value = true
}

async function save() {
  if (editing.value) await api.put(`/publish-rules/${editing.value.id}`, form)
  else await api.post('/publish-rules', form)
  ElMessage.success('保存成功'); dialogVisible.value = false; load()
}

async function togglePool(p) {
  const status = p.status === 'active' ? 'disabled' : 'active'
  await api.put(`/publish-rules/${p.id}`, { ...p, status })
  ElMessage.success('操作成功'); load()
}

async function remove(p) {
  await ElMessageBox.confirm(`确认删除桌面池 ${p.name}?`, '删除', { type: 'warning' })
  await api.delete(`/publish-rules/${p.id}`); ElMessage.success('已删除'); load()
}

onMounted(load)
</script>
