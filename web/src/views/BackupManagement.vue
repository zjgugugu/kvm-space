<template>
  <div>
    <div class="page-header">
      <h2>备份管理</h2>
      <el-button type="primary" @click="showBackupDialog"><el-icon><Plus /></el-icon>创建备份</el-button>
    </div>
    <el-tabs v-model="tab">
      <el-tab-pane label="备份列表" name="list">
        <el-table :data="backups" v-loading="loading" border stripe size="small">
          <el-table-column prop="user_name" label="用户" width="100" />
          <el-table-column prop="vm_name" label="桌面" width="140" />
          <el-table-column prop="group_name" label="组" width="100" />
          <el-table-column prop="interval_days" label="间隔天数" width="90" />
          <el-table-column prop="keep_count" label="保留份数" width="90" />
          <el-table-column prop="location" label="备份位置" width="130" show-overflow-tooltip>
            <template #default="{ row }">{{ row.location || row.server_name || '-' }}</template>
          </el-table-column>
          <el-table-column prop="schedule_time" label="定时时间" width="90" />
          <el-table-column prop="last_backup_at" label="最后备份时间" width="155" />
          <el-table-column prop="status" label="状态" width="90">
            <template #default="{ row }"><el-tag :type="statusType(row.status)" size="small">{{ statusText(row.status) }}</el-tag></template>
          </el-table-column>
          <el-table-column prop="note" label="备注" min-width="100" show-overflow-tooltip />
          <el-table-column label="操作" width="160" fixed="right">
            <template #default="{ row }">
              <el-button size="small" type="primary" @click="restore(row)" :disabled="row.status!=='completed'">恢复</el-button>
              <el-button size="small" type="danger" @click="remove(row)">删除</el-button>
            </template>
          </el-table-column>
        </el-table>
      </el-tab-pane>
      <el-tab-pane label="备份服务器" name="servers">
        <div style="margin-bottom:10px"><el-button type="primary" size="small" @click="showServerDialog()"><el-icon><Plus /></el-icon>添加服务器</el-button></div>
        <el-table :data="servers" border stripe size="small">
          <el-table-column prop="name" label="名称" width="150" />
          <el-table-column prop="address" label="地址" width="160" />
          <el-table-column prop="type" label="类型" width="100" />
          <el-table-column prop="status" label="状态" width="90">
            <template #default="{ row }"><el-tag :type="row.status === 'online' ? 'success' : 'danger'" size="small">{{ row.status === 'online' ? '在线' : '离线' }}</el-tag></template>
          </el-table-column>
          <el-table-column prop="capacity" label="存储容量" width="120" />
          <el-table-column label="操作" width="120">
            <template #default="{ row }">
              <el-button size="small" @click="showServerDialog(row)">编辑</el-button>
              <el-button size="small" type="danger" @click="removeServer(row)">删除</el-button>
            </template>
          </el-table-column>
        </el-table>
      </el-tab-pane>
    </el-tabs>

    <el-dialog v-model="backupDialogVisible" title="创建备份" width="450px">
      <el-form :model="backupForm" label-width="90px">
        <el-form-item label="备份名称"><el-input v-model="backupForm.name" :placeholder="`backup_${new Date().toISOString().slice(0,10)}`" /></el-form-item>
        <el-form-item label="虚拟机">
          <el-select v-model="backupForm.vm_id" placeholder="选择虚拟机" style="width:100%">
            <el-option v-for="v in vms" :key="v.id" :label="v.name" :value="v.id" />
          </el-select>
        </el-form-item>
        <el-form-item label="备份类型">
          <el-radio-group v-model="backupForm.type"><el-radio value="full">全量</el-radio><el-radio value="incremental">增量</el-radio></el-radio-group>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="backupDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="createBackup">确定</el-button>
      </template>
    </el-dialog>

    <el-dialog v-model="serverDialogVisible" :title="editingServer ? '编辑服务器' : '添加备份服务器'" width="450px">
      <el-form :model="serverForm" label-width="80px">
        <el-form-item label="名称"><el-input v-model="serverForm.name" /></el-form-item>
        <el-form-item label="地址"><el-input v-model="serverForm.address" placeholder="192.168.1.100" /></el-form-item>
        <el-form-item label="类型">
          <el-select v-model="serverForm.type" style="width:100%"><el-option label="NFS" value="nfs" /><el-option label="CIFS" value="cifs" /><el-option label="iSCSI" value="iscsi" /></el-select>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="serverDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="saveServer">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import api from '../api'
import { ElMessage, ElMessageBox } from 'element-plus'

const route = useRoute()
const loading = ref(false)
const tab = ref(route.meta.defaultTab || 'list')
const backups = ref([]), servers = ref([]), vms = ref([])
const backupDialogVisible = ref(false), serverDialogVisible = ref(false), editingServer = ref(null)
const backupForm = reactive({ name: '', vm_id: '', type: 'full' })
const serverForm = reactive({ name: '', address: '', type: 'nfs' })

function statusType(s) { return { completed: 'success', running: 'info', failed: 'danger', pending: 'warning' }[s] || 'info' }
function statusText(s) { return { completed: '已完成', running: '进行中', failed: '失败', pending: '等待中' }[s] || s }

async function load() {
  loading.value = true
  try {
    const [b, s, v] = await Promise.all([api.get('/backups'), api.get('/backups/servers'), api.get('/vms')])
    backups.value = b.data || []; servers.value = s.data || []; vms.value = v.data || []
  } catch(e) {}
  finally { loading.value = false }
}

function showBackupDialog() {
  Object.assign(backupForm, { name: `backup_${new Date().toISOString().slice(0,10)}_manual`, vm_id: '', type: 'full' })
  backupDialogVisible.value = true
}

async function createBackup() {
  await api.post('/backups', backupForm)
  ElMessage.success('备份已创建'); backupDialogVisible.value = false; load()
}

async function restore(b) {
  await ElMessageBox.confirm(`确认从 ${b.name} 恢复?`, '恢复', { type: 'warning' })
  await api.post(`/backups/${b.id}/restore`); ElMessage.success('恢复完成'); load()
}

async function remove(b) {
  await ElMessageBox.confirm(`确认删除备份 ${b.name}?`, '删除', { type: 'warning' })
  await api.delete(`/backups/${b.id}`); ElMessage.success('已删除'); load()
}

function showServerDialog(s) {
  editingServer.value = s || null
  if (s) Object.assign(serverForm, { name: s.name, address: s.address, type: s.type })
  else Object.assign(serverForm, { name: '', address: '', type: 'nfs' })
  serverDialogVisible.value = true
}

async function saveServer() {
  if (editingServer.value) await api.put(`/backups/servers/${editingServer.value.id}`, serverForm)
  else await api.post('/backups/servers', serverForm)
  ElMessage.success('保存成功'); serverDialogVisible.value = false; load()
}

async function removeServer(s) {
  await ElMessageBox.confirm(`确认删除备份服务器 ${s.name}?`, '删除', { type: 'warning' })
  await api.delete(`/backups/servers/${s.id}`); ElMessage.success('已删除'); load()
}

onMounted(load)
</script>
