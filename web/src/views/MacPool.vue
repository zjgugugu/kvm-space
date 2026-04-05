<template>
  <div>
    <div class="page-header">
      <h2>MAC地址池</h2>
      <el-button type="primary" @click="showDialog()"><el-icon><Plus /></el-icon>创建地址池</el-button>
    </div>
    <el-table :data="pools" v-loading="loading" border stripe size="small">
      <el-table-column prop="name" label="名称" width="160" />
      <el-table-column prop="range_start" label="起始地址" width="150" />
      <el-table-column prop="range_end" label="结束地址" width="150" />
      <el-table-column prop="total" label="总数" width="80" />
      <el-table-column prop="used" label="已用" width="80" />
      <el-table-column prop="description" label="描述" min-width="200" />
      <el-table-column label="操作" width="140" fixed="right">
        <template #default="{ row }">
          <el-button size="small" @click="showDialog(row)">编辑</el-button>
          <el-button size="small" type="danger" @click="remove(row)">删除</el-button>
        </template>
      </el-table-column>
    </el-table>

    <el-dialog v-model="dialogVisible" :title="editing ? '编辑MAC地址池' : '创建MAC地址池'" width="450px">
      <el-form :model="form" label-width="90px">
        <el-form-item label="名称" required><el-input v-model="form.name" /></el-form-item>
        <el-form-item label="起始地址"><el-input v-model="form.range_start" placeholder="52:54:00:00:00:01" /></el-form-item>
        <el-form-item label="结束地址"><el-input v-model="form.range_end" placeholder="52:54:00:FF:FF:FF" /></el-form-item>
        <el-form-item label="描述"><el-input v-model="form.description" /></el-form-item>
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
const pools = ref([])
const dialogVisible = ref(false), editing = ref(null)
const form = reactive({ name: '', range_start: '', range_end: '', description: '' })

async function load() {
  loading.value = true
  try { pools.value = (await api.get('/networks/mac-pools')).data || [] }
  catch(e) { pools.value = [] }
  finally { loading.value = false }
}

function showDialog(p) {
  editing.value = p || null
  if (p) Object.assign(form, { name: p.name, range_start: p.range_start, range_end: p.range_end, description: p.description || '' })
  else Object.assign(form, { name: '', range_start: '52:54:00:00:00:01', range_end: '52:54:00:FF:FF:FF', description: '' })
  dialogVisible.value = true
}

async function save() {
  if (editing.value) await api.put(`/networks/mac-pools/${editing.value.id}`, form)
  else await api.post('/networks/mac-pools', form)
  ElMessage.success('保存成功'); dialogVisible.value = false; load()
}

async function remove(p) {
  await ElMessageBox.confirm(`确认删除地址池 ${p.name}?`, '删除', { type: 'warning' })
  await api.delete(`/networks/mac-pools/${p.id}`); ElMessage.success('已删除'); load()
}

onMounted(load)
</script>
