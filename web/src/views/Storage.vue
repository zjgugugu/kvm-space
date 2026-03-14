<template>
  <div>
    <div class="page-header">
      <h2>存储管理</h2>
      <el-button type="primary" @click="showPoolDialog()"><el-icon><Plus /></el-icon>添加存储池</el-button>
    </div>
    <el-tabs v-model="tab">
      <el-tab-pane label="存储池" name="pools">
        <el-table :data="pools" v-loading="loading" border stripe>
          <el-table-column prop="name" label="名称" width="160" />
          <el-table-column prop="type" label="类型" width="100" />
          <el-table-column prop="path" label="路径" min-width="200" />
          <el-table-column label="容量" width="180">
            <template #default="{ row }">
              <el-progress :percentage="row.total ? Math.round(row.used / row.total * 100) : 0" :stroke-width="14" />
              <span style="font-size: 12px; color: #909399;">{{ row.used }}GB / {{ row.total }}GB</span>
            </template>
          </el-table-column>
          <el-table-column prop="status" label="状态" width="80">
            <template #default="{ row }"><el-tag :type="row.status === 'active' ? 'success' : 'info'" size="small">{{ row.status === 'active' ? '活跃' : '停用' }}</el-tag></template>
          </el-table-column>
          <el-table-column label="操作" width="120" fixed="right">
            <template #default="{ row }">
              <el-button size="small" @click="showPoolDialog(row)">编辑</el-button>
              <el-button size="small" type="danger" @click="delPool(row)">删除</el-button>
            </template>
          </el-table-column>
        </el-table>
      </el-tab-pane>
      <el-tab-pane label="卷管理" name="volumes">
        <el-table :data="volumes" border stripe size="small">
          <el-table-column prop="name" label="卷名" width="160" />
          <el-table-column prop="pool_name" label="所属池" width="140" />
          <el-table-column prop="size" label="大小(GB)" width="100" />
          <el-table-column prop="format" label="格式" width="80" />
          <el-table-column prop="vm_name" label="挂载VM" width="140" />
          <el-table-column prop="status" label="状态" width="80" />
          <el-table-column prop="created_at" label="创建时间" min-width="160" />
        </el-table>
      </el-tab-pane>
    </el-tabs>

    <el-dialog v-model="poolDialogVisible" :title="editingPool ? '编辑存储池' : '添加存储池'" width="480px">
      <el-form :model="poolForm" label-width="80px">
        <el-form-item label="名称"><el-input v-model="poolForm.name" /></el-form-item>
        <el-form-item label="类型">
          <el-select v-model="poolForm.type" style="width: 100%;"><el-option label="local" value="local" /><el-option label="nfs" value="nfs" /><el-option label="ceph" value="ceph" /><el-option label="iscsi" value="iscsi" /></el-select>
        </el-form-item>
        <el-form-item label="路径"><el-input v-model="poolForm.path" placeholder="/var/lib/libvirt/images" /></el-form-item>
        <el-form-item label="容量(GB)"><el-input-number v-model="poolForm.total" :min="10" /></el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="poolDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="savePool">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import api from '../api'
import { ElMessage, ElMessageBox } from 'element-plus'

const loading = ref(false), poolDialogVisible = ref(false), editingPool = ref(null)
const tab = ref('pools')
const pools = ref([]), volumes = ref([])
const poolForm = reactive({ name: '', type: 'local', path: '', total: 500 })

async function load() {
  loading.value = true
  try {
    pools.value = (await api.get('/storage/pools')).data
    volumes.value = (await api.get('/storage/volumes')).data
  } catch(e) {} finally { loading.value = false }
}

function showPoolDialog(p) {
  editingPool.value = p || null
  if (p) Object.assign(poolForm, { name: p.name, type: p.type, path: p.path, total: p.total })
  else Object.assign(poolForm, { name: '', type: 'local', path: '', total: 500 })
  poolDialogVisible.value = true
}

async function savePool() {
  if (editingPool.value) await api.put(`/storage/pools/${editingPool.value.id}`, poolForm)
  else await api.post('/storage/pools', poolForm)
  ElMessage.success('保存成功'); poolDialogVisible.value = false; load()
}

async function delPool(p) {
  await ElMessageBox.confirm(`确认删除存储池 ${p.name}?`)
  await api.delete(`/storage/pools/${p.id}`); ElMessage.success('已删除'); load()
}

onMounted(load)
</script>
