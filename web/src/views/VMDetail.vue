<template>
  <div v-loading="loading">
    <div class="page-header">
      <h2>{{ vm.name || '虚拟机详情' }}</h2>
      <el-button @click="$router.push('/vms')">返回列表</el-button>
    </div>

    <!-- 基本信息 -->
    <el-row :gutter="16" style="margin-bottom: 16px;">
      <el-col :span="16">
        <el-card shadow="hover">
          <template #header><span style="font-weight: 600;">基本信息</span></template>
          <el-descriptions :column="3" border size="small">
            <el-descriptions-item label="名称">{{ vm.name }}</el-descriptions-item>
            <el-descriptions-item label="状态">
              <el-tag :type="statusType(vm.status)" size="small">{{ statusText(vm.status) }}</el-tag>
            </el-descriptions-item>
            <el-descriptions-item label="操作系统">{{ vm.os_version }}</el-descriptions-item>
            <el-descriptions-item label="CPU">{{ vm.cpu }} 核 (最大 {{ vm.max_cpu }})</el-descriptions-item>
            <el-descriptions-item label="内存">{{ (vm.memory/1024).toFixed(0) }} GB (最大 {{ (vm.max_memory/1024).toFixed(0) }})</el-descriptions-item>
            <el-descriptions-item label="系统盘">{{ vm.disk }} GB</el-descriptions-item>
            <el-descriptions-item label="IP">{{ vm.ip }}</el-descriptions-item>
            <el-descriptions-item label="MAC">{{ vm.mac }}</el-descriptions-item>
            <el-descriptions-item label="VNC端口">{{ vm.vnc_port || '-' }}</el-descriptions-item>
            <el-descriptions-item label="所在主机">{{ vm.host_name }}</el-descriptions-item>
            <el-descriptions-item label="使用者">{{ vm.owner }}</el-descriptions-item>
            <el-descriptions-item label="创建时间">{{ vm.created_at }}</el-descriptions-item>
          </el-descriptions>
        </el-card>
      </el-col>
      <el-col :span="8">
        <el-card shadow="hover">
          <template #header><span style="font-weight: 600;">快捷操作</span></template>
          <div style="display: flex; flex-wrap: wrap; gap: 8px;">
            <el-button v-if="vm.status==='stopped'" type="success" @click="action('start')">开机</el-button>
            <el-button v-if="vm.status==='running'" type="warning" @click="action('stop')">关机</el-button>
            <el-button v-if="vm.status==='running'" @click="action('reboot')">重启</el-button>
            <el-button v-if="vm.status==='running'" @click="action('suspend')">挂起</el-button>
            <el-button v-if="vm.status==='suspended'" @click="action('resume')">唤醒</el-button>
            <el-button @click="action('force_stop')">强制关机</el-button>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 磁盘、网卡、快照 标签页 -->
    <el-card shadow="hover">
      <el-tabs v-model="activeTab">
        <!-- 磁盘 -->
        <el-tab-pane label="磁盘" name="disks">
          <el-button size="small" type="primary" @click="addDiskVisible=true" style="margin-bottom: 10px;"><el-icon><Plus /></el-icon>添加磁盘</el-button>
          <el-table :data="vm.disks || []" border size="small">
            <el-table-column prop="name" label="名称" width="150" />
            <el-table-column prop="size" label="大小(GB)" width="100" />
            <el-table-column prop="type" label="类型" width="100" />
            <el-table-column prop="bus" label="总线" width="100" />
            <el-table-column label="操作" width="100">
              <template #default="{ row }">
                <el-button size="small" type="danger" @click="removeDisk(row)">移除</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>

        <!-- 网卡 -->
        <el-tab-pane label="网卡" name="nics">
          <el-button size="small" type="primary" @click="addNicVisible=true" style="margin-bottom: 10px;"><el-icon><Plus /></el-icon>添加网卡</el-button>
          <el-table :data="vm.nics || []" border size="small">
            <el-table-column prop="name" label="名称" width="150" />
            <el-table-column prop="mac" label="MAC" width="160" />
            <el-table-column prop="network_name" label="网络" width="140" />
            <el-table-column prop="model" label="型号" width="100" />
            <el-table-column label="操作" width="100">
              <template #default="{ row }">
                <el-button size="small" type="danger" @click="removeNic(row)">移除</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>

        <!-- 快照 -->
        <el-tab-pane label="快照" name="snapshots">
          <el-button size="small" type="primary" @click="createSnap" style="margin-bottom: 10px;"><el-icon><Plus /></el-icon>创建快照</el-button>
          <el-table :data="snapshots" border size="small">
            <el-table-column prop="name" label="名称" width="160" />
            <el-table-column prop="description" label="描述" min-width="180" />
            <el-table-column prop="created_at" label="创建时间" width="170" />
            <el-table-column label="操作" width="160">
              <template #default="{ row }">
                <el-button size="small" type="primary" @click="revertSnap(row)">恢复</el-button>
                <el-button size="small" type="danger" @click="deleteSnap(row)">删除</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>
      </el-tabs>
    </el-card>

    <!-- 添加磁盘 -->
    <el-dialog v-model="addDiskVisible" title="添加磁盘" width="400px">
      <el-form :model="diskForm" label-width="80px">
        <el-form-item label="大小(GB)"><el-input-number v-model="diskForm.size" :min="1" :max="2048" /></el-form-item>
        <el-form-item label="类型">
          <el-select v-model="diskForm.type"><el-option label="数据盘" value="data" /><el-option label="系统盘" value="system" /></el-select>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="addDiskVisible=false">取消</el-button>
        <el-button type="primary" @click="doAddDisk">确定</el-button>
      </template>
    </el-dialog>

    <!-- 添加网卡 -->
    <el-dialog v-model="addNicVisible" title="添加网卡" width="400px">
      <el-form :model="nicForm" label-width="80px">
        <el-form-item label="网络">
          <el-select v-model="nicForm.network_id" style="width: 100%;">
            <el-option v-for="n in networkList" :key="n.id" :label="n.name" :value="n.id" />
          </el-select>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="addNicVisible=false">取消</el-button>
        <el-button type="primary" @click="doAddNic">确定</el-button>
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
const vm = ref({})
const snapshots = ref([])
const networkList = ref([])
const activeTab = ref('disks')
const addDiskVisible = ref(false), addNicVisible = ref(false)
const diskForm = reactive({ size: 20, type: 'data' })
const nicForm = reactive({ network_id: '' })

function statusType(s) { return { running: 'success', stopped: 'danger', suspended: 'warning' }[s] || 'info' }
function statusText(s) { return { running: '运行中', stopped: '已关机', suspended: '挂起' }[s] || s }

async function loadVM() {
  loading.value = true
  try {
    vm.value = await api.get(`/vms/${route.params.id}`)
    snapshots.value = (await api.get(`/vms/${route.params.id}/snapshots`)).data
  } finally { loading.value = false }
}

async function action(act) {
  await api.post(`/vms/${route.params.id}/action`, { action: act })
  ElMessage.success('操作成功'); loadVM()
}

async function doAddDisk() {
  await api.post(`/vms/${route.params.id}/disks`, diskForm)
  ElMessage.success('添加成功'); addDiskVisible.value = false; loadVM()
}
async function removeDisk(d) {
  await ElMessageBox.confirm(`确认移除磁盘 ${d.name}?`)
  await api.delete(`/vms/${route.params.id}/disks/${d.id}`); ElMessage.success('已移除'); loadVM()
}
async function doAddNic() {
  if (!networkList.value.length) networkList.value = (await api.get('/networks')).data
  await api.post(`/vms/${route.params.id}/nics`, nicForm)
  ElMessage.success('添加成功'); addNicVisible.value = false; loadVM()
}
async function removeNic(n) {
  await ElMessageBox.confirm(`确认移除网卡 ${n.name}?`)
  await api.delete(`/vms/${route.params.id}/nics/${n.id}`); ElMessage.success('已移除'); loadVM()
}
async function createSnap() {
  const { value } = await ElMessageBox.prompt('快照名称', '创建快照', { inputValue: `snap-${Date.now()}` })
  await api.post(`/vms/${route.params.id}/snapshots`, { name: value }); ElMessage.success('创建成功'); loadVM()
}
async function revertSnap(s) {
  await ElMessageBox.confirm(`确认恢复到快照 ${s.name}?`)
  await api.post(`/vms/${route.params.id}/snapshots/${s.id}/revert`); ElMessage.success('已恢复'); loadVM()
}
async function deleteSnap(s) {
  await ElMessageBox.confirm(`确认删除快照 ${s.name}?`)
  await api.delete(`/vms/${route.params.id}/snapshots/${s.id}`); ElMessage.success('已删除'); loadVM()
}

onMounted(async () => {
  networkList.value = (await api.get('/networks')).data
  loadVM()
})
</script>
