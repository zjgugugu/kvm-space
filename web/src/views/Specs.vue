<template>
  <div>
    <div class="page-header">
      <h2>桌面规格</h2>
      <el-button type="primary" @click="showDialog()"><el-icon><Plus /></el-icon>创建规格</el-button>
    </div>
    <el-table :data="specs" v-loading="loading" border stripe>
      <el-table-column prop="name" label="名称" width="160" />
      <el-table-column label="CPU" width="120"><template #default="{ row }">{{ row.cpu }}核 (最大{{ row.max_cpu }})</template></el-table-column>
      <el-table-column label="内存" width="150"><template #default="{ row }">{{ (row.memory/1024).toFixed(0) }}GB (最大{{ (row.max_memory/1024).toFixed(0) }})</template></el-table-column>
      <el-table-column prop="system_disk" label="系统盘(GB)" width="100" />
      <el-table-column prop="user_disk" label="数据盘(GB)" width="100" />
      <el-table-column prop="protocol" label="协议" width="80" />
      <el-table-column prop="usb_mode" label="USB模式" width="100" />
      <el-table-column label="GPU" width="100"><template #default="{ row }">{{ row.gpu_type || '无' }}</template></el-table-column>
      <el-table-column prop="description" label="描述" min-width="150" />
      <el-table-column label="操作" width="150" fixed="right">
        <template #default="{ row }">
          <el-button size="small" @click="showDialog(row)">编辑</el-button>
          <el-button size="small" type="danger" @click="del(row)">删除</el-button>
        </template>
      </el-table-column>
    </el-table>

    <el-dialog v-model="dialogVisible" :title="editing ? '编辑规格' : '创建规格'" width="580px">
      <el-form :model="form" label-width="90px">
        <el-form-item label="名称"><el-input v-model="form.name" /></el-form-item>
        <el-row :gutter="16">
          <el-col :span="12"><el-form-item label="CPU(核)"><el-input-number v-model="form.cpu" :min="1" :max="64" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="最大CPU"><el-input-number v-model="form.max_cpu" :min="1" :max="128" /></el-form-item></el-col>
        </el-row>
        <el-row :gutter="16">
          <el-col :span="12"><el-form-item label="内存(MB)"><el-input-number v-model="form.memory" :min="512" :step="512" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="最大内存"><el-input-number v-model="form.max_memory" :min="512" :step="512" /></el-form-item></el-col>
        </el-row>
        <el-row :gutter="16">
          <el-col :span="12"><el-form-item label="系统盘(GB)"><el-input-number v-model="form.system_disk" :min="10" /></el-form-item></el-col>
          <el-col :span="12"><el-form-item label="数据盘(GB)"><el-input-number v-model="form.user_disk" :min="0" /></el-form-item></el-col>
        </el-row>
        <el-form-item label="协议">
          <el-select v-model="form.protocol" style="width: 100%;"><el-option label="UDAP" value="UDAP" /><el-option label="SPICE" value="SPICE" /><el-option label="VNC" value="VNC" /></el-select>
        </el-form-item>
        <el-form-item label="USB模式">
          <el-select v-model="form.usb_mode" style="width: 100%;"><el-option label="本地" value="native" /><el-option label="重定向" value="redirect" /></el-select>
        </el-form-item>
        <el-form-item label="描述"><el-input v-model="form.description" type="textarea" :rows="2" /></el-form-item>
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
const specs = ref([])
const form = reactive({ name: '', cpu: 2, max_cpu: 4, memory: 2048, max_memory: 4096, system_disk: 40, user_disk: 0, protocol: 'UDAP', usb_mode: 'native', description: '' })

async function load() { loading.value = true; try { specs.value = (await api.get('/specs')).data } finally { loading.value = false } }

function showDialog(s) {
  editing.value = s || null
  if (s) Object.assign(form, s)
  else Object.assign(form, { name: '', cpu: 2, max_cpu: 4, memory: 2048, max_memory: 4096, system_disk: 40, user_disk: 0, protocol: 'UDAP', usb_mode: 'native', description: '' })
  dialogVisible.value = true
}

async function save() {
  saving.value = true
  try {
    if (editing.value) await api.put(`/specs/${editing.value.id}`, form)
    else await api.post('/specs', form)
    ElMessage.success('保存成功'); dialogVisible.value = false; load()
  } finally { saving.value = false }
}

async function del(s) {
  await ElMessageBox.confirm(`确认删除规格 ${s.name}?`, '警告', { type: 'warning' })
  await api.delete(`/specs/${s.id}`); ElMessage.success('已删除'); load()
}

onMounted(load)
</script>
