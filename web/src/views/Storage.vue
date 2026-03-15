<template>
  <div>
    <div class="page-header">
      <h2>存储管理</h2>
      <div style="display: flex; gap: 8px; align-items: center;">
        <el-input v-model="search" placeholder="搜索名称" clearable style="width: 200px;">
          <template #prefix><el-icon><Search /></el-icon></template>
        </el-input>
        <el-button type="primary" @click="showPoolDialog()"><el-icon><Plus /></el-icon>添加存储池</el-button>
      </div>
    </div>
    <!-- 存储概览 -->
    <el-row :gutter="12" style="margin-bottom: 12px;">
      <el-col :span="6"><el-statistic title="存储池总数" :value="pools.length" /></el-col>
      <el-col :span="6"><el-statistic title="总容量(GB)" :value="totalCapacity" /></el-col>
      <el-col :span="6"><el-statistic title="已用(GB)" :value="totalUsed" /></el-col>
      <el-col :span="6"><el-statistic title="卷数量" :value="volumes.length" /></el-col>
    </el-row>
    <el-tabs v-model="tab">
      <el-tab-pane label="存储池" name="pools">
        <el-table :data="filteredPools" v-loading="loading" border stripe size="small">
          <el-table-column prop="name" label="名称" width="140" />
          <el-table-column prop="type" label="类型" width="80">
            <template #default="{ row }"><el-tag size="small">{{ row.type }}</el-tag></template>
          </el-table-column>
          <el-table-column prop="path" label="路径/地址" min-width="180" show-overflow-tooltip />
          <el-table-column label="容量" width="200">
            <template #default="{ row }">
              <el-progress :percentage="row.total ? Math.round(row.used / row.total * 100) : 0" :stroke-width="14" :color="row.total && row.used/row.total > 0.9 ? '#F56C6C' : '#409EFF'" />
              <span style="font-size: 12px; color: #909399;">{{ row.used }}GB / {{ row.total }}GB</span>
            </template>
          </el-table-column>
          <el-table-column prop="volume_count" label="卷数" width="70" />
          <el-table-column prop="status" label="状态" width="70">
            <template #default="{ row }"><el-tag :type="row.status === 'active' ? 'success' : 'info'" size="small">{{ row.status === 'active' ? '活跃' : '停用' }}</el-tag></template>
          </el-table-column>
          <el-table-column label="操作" width="180" fixed="right">
            <template #default="{ row }">
              <el-button size="small" @click="showPoolDialog(row)">编辑</el-button>
              <el-button size="small" :type="row.status==='active' ? 'warning' : 'success'" @click="togglePool(row)">{{ row.status==='active' ? '停用' : '启用' }}</el-button>
              <el-button size="small" type="danger" @click="delPool(row)">删除</el-button>
            </template>
          </el-table-column>
        </el-table>
      </el-tab-pane>
      <el-tab-pane label="卷管理" name="volumes">
        <div style="margin-bottom: 10px;">
          <el-button type="primary" size="small" @click="showVolDialog()"><el-icon><Plus /></el-icon>创建卷</el-button>
          <el-select v-model="volPoolFilter" placeholder="按存储池筛选" clearable style="width: 160px; margin-left: 8px;" size="small">
            <el-option v-for="p in pools" :key="p.id" :label="p.name" :value="p.name" />
          </el-select>
        </div>
        <el-table :data="filteredVolumes" border stripe size="small">
          <el-table-column prop="name" label="卷名" width="150" />
          <el-table-column prop="pool_name" label="所属池" width="120" />
          <el-table-column prop="size" label="大小(GB)" width="90" />
          <el-table-column prop="format" label="格式" width="80">
            <template #default="{ row }"><el-tag size="small" type="info">{{ row.format }}</el-tag></template>
          </el-table-column>
          <el-table-column prop="vm_name" label="挂载VM" width="130">
            <template #default="{ row }"><span :style="{ color: row.vm_name ? '#409EFF' : '#C0C4CC' }">{{ row.vm_name || '未挂载' }}</span></template>
          </el-table-column>
          <el-table-column prop="status" label="状态" width="70">
            <template #default="{ row }"><el-tag :type="row.status==='in-use' ? 'success' : 'info'" size="small">{{ row.status==='in-use' ? '使用中' : '空闲' }}</el-tag></template>
          </el-table-column>
          <el-table-column prop="created_at" label="创建时间" width="155" />
          <el-table-column label="操作" width="120">
            <template #default="{ row }">
              <el-button size="small" @click="showVolDialog(row)">编辑</el-button>
              <el-button size="small" type="danger" @click="delVol(row)" :disabled="row.status==='in-use'">删除</el-button>
            </template>
          </el-table-column>
        </el-table>
      </el-tab-pane>
      <el-tab-pane label="分布式存储" name="distributed">
        <el-empty description="暂未配置分布式存储集群">
          <el-button type="primary" @click="ElMessage.info('分布式存储配置向导开发中')">配置Ceph集群</el-button>
        </el-empty>
      </el-tab-pane>
    </el-tabs>

    <!-- 存储池对话框 -->
    <el-dialog v-model="poolDialogVisible" :title="editingPool ? '编辑存储池' : '添加存储池'" width="500px">
      <el-form :model="poolForm" label-width="90px">
        <el-form-item label="名称" required><el-input v-model="poolForm.name" /></el-form-item>
        <el-form-item label="类型">
          <el-select v-model="poolForm.type" style="width: 100%;">
            <el-option label="本地存储" value="local" /><el-option label="NFS" value="nfs" /><el-option label="Ceph RBD" value="ceph" /><el-option label="iSCSI" value="iscsi" />
          </el-select>
        </el-form-item>
        <el-form-item :label="poolForm.type==='nfs' ? 'NFS地址' : poolForm.type==='ceph' ? 'Pool名称' : '路径'">
          <el-input v-model="poolForm.path" :placeholder="poolForm.type==='nfs' ? '192.168.1.100:/share' : poolForm.type==='ceph' ? 'rbd' : '/var/lib/libvirt/images'" />
        </el-form-item>
        <el-form-item label="容量(GB)"><el-input-number v-model="poolForm.total" :min="10" :step="100" style="width: 100%;" /></el-form-item>
        <el-form-item label="描述"><el-input v-model="poolForm.description" type="textarea" :rows="2" /></el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="poolDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="savePool">确定</el-button>
      </template>
    </el-dialog>

    <!-- 卷创建/编辑对话框 -->
    <el-dialog v-model="volDialogVisible" :title="editingVol ? '编辑卷' : '创建卷'" width="450px">
      <el-form :model="volForm" label-width="80px">
        <el-form-item label="卷名" required><el-input v-model="volForm.name" /></el-form-item>
        <el-form-item label="存储池">
          <el-select v-model="volForm.pool_name" style="width: 100%;">
            <el-option v-for="p in pools" :key="p.id" :label="p.name" :value="p.name" />
          </el-select>
        </el-form-item>
        <el-form-item label="大小(GB)"><el-input-number v-model="volForm.size" :min="1" :max="2000" style="width: 100%;" /></el-form-item>
        <el-form-item label="格式">
          <el-select v-model="volForm.format" style="width: 100%;">
            <el-option label="qcow2" value="qcow2" /><el-option label="raw" value="raw" /><el-option label="vmdk" value="vmdk" />
          </el-select>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="volDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="saveVol">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted } from 'vue'
import api from '../api'
import { ElMessage, ElMessageBox } from 'element-plus'

const loading = ref(false), poolDialogVisible = ref(false), editingPool = ref(null)
const volDialogVisible = ref(false), editingVol = ref(null)
const tab = ref('pools'), search = ref(''), volPoolFilter = ref('')
const pools = ref([]), volumes = ref([])
const poolForm = reactive({ name: '', type: 'local', path: '', total: 500, description: '' })
const volForm = reactive({ name: '', pool_name: '', size: 50, format: 'qcow2' })

const totalCapacity = computed(() => pools.value.reduce((s, p) => s + (p.total || 0), 0))
const totalUsed = computed(() => pools.value.reduce((s, p) => s + (p.used || 0), 0))
const filteredPools = computed(() => {
  if (!search.value) return pools.value
  const s = search.value.toLowerCase()
  return pools.value.filter(p => p.name.toLowerCase().includes(s))
})
const filteredVolumes = computed(() => {
  let list = volumes.value
  if (volPoolFilter.value) list = list.filter(v => v.pool_name === volPoolFilter.value)
  if (search.value) { const s = search.value.toLowerCase(); list = list.filter(v => v.name.toLowerCase().includes(s)) }
  return list
})

async function load() {
  loading.value = true
  try {
    pools.value = (await api.get('/storage/pools')).data || []
    volumes.value = (await api.get('/storage/volumes')).data || []
  } catch(e) { pools.value = []; volumes.value = [] } finally { loading.value = false }
}

function showPoolDialog(p) {
  editingPool.value = p || null
  if (p) Object.assign(poolForm, { name: p.name, type: p.type, path: p.path, total: p.total, description: p.description || '' })
  else Object.assign(poolForm, { name: '', type: 'local', path: '', total: 500, description: '' })
  poolDialogVisible.value = true
}

async function savePool() {
  if (editingPool.value) await api.put(`/storage/pools/${editingPool.value.id}`, poolForm)
  else await api.post('/storage/pools', poolForm)
  ElMessage.success('保存成功'); poolDialogVisible.value = false; load()
}

async function togglePool(p) {
  const ns = p.status === 'active' ? 'inactive' : 'active'
  await api.put(`/storage/pools/${p.id}`, { status: ns }); ElMessage.success('操作成功'); load()
}

async function delPool(p) {
  await ElMessageBox.confirm(`确认删除存储池 ${p.name}?`, '警告', { type: 'warning' })
  await api.delete(`/storage/pools/${p.id}`); ElMessage.success('已删除'); load()
}

function showVolDialog(v) {
  editingVol.value = v || null
  if (v) Object.assign(volForm, { name: v.name, pool_name: v.pool_name, size: v.size, format: v.format })
  else Object.assign(volForm, { name: '', pool_name: pools.value[0]?.name || '', size: 50, format: 'qcow2' })
  volDialogVisible.value = true
}

async function saveVol() {
  const pool = pools.value.find(p => p.name === volForm.pool_name)
  await api.post('/storage/volumes', { name: volForm.name, pool_id: pool?.id || '', size: volForm.size, format: volForm.format })
  ElMessage.success('卷已创建'); volDialogVisible.value = false; load()
}

async function delVol(v) {
  await ElMessageBox.confirm(`确认删除卷 ${v.name}?`, '警告', { type: 'warning' })
  await api.delete(`/storage/volumes/${v.id}`)
  ElMessage.success('已删除'); load()
}

onMounted(load)
</script>
