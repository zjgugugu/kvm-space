<template>
  <div>
    <div class="page-header">
      <h2>网络管理</h2>
      <el-button type="primary" @click="showDialog()"><el-icon><Plus /></el-icon>创建网络</el-button>
    </div>
    <el-tabs v-model="tab">
      <el-tab-pane label="虚拟网络" name="networks">
        <el-table :data="networks" v-loading="loading" border stripe>
          <el-table-column prop="name" label="名称" width="160" />
          <el-table-column prop="type" label="类型" width="100" />
          <el-table-column prop="vlan_id" label="VLAN" width="80" />
          <el-table-column prop="subnet" label="子网" width="160" />
          <el-table-column prop="gateway" label="网关" width="140" />
          <el-table-column prop="dhcp_enabled" label="DHCP" width="80">
            <template #default="{ row }"><el-tag :type="row.dhcp_enabled ? 'success' : 'info'" size="small">{{ row.dhcp_enabled ? '启用' : '禁用' }}</el-tag></template>
          </el-table-column>
          <el-table-column prop="status" label="状态" width="80">
            <template #default="{ row }"><el-tag :type="row.status === 'active' ? 'success' : 'info'" size="small">{{ row.status === 'active' ? '活跃' : '停用' }}</el-tag></template>
          </el-table-column>
          <el-table-column label="操作" width="150" fixed="right">
            <template #default="{ row }">
              <el-button size="small" @click="showDialog(row)">编辑</el-button>
              <el-button size="small" type="danger" @click="del(row)">删除</el-button>
            </template>
          </el-table-column>
        </el-table>
      </el-tab-pane>
      <el-tab-pane label="安全组" name="security">
        <el-table :data="secGroups" border stripe size="small">
          <el-table-column prop="name" label="名称" width="160" />
          <el-table-column prop="description" label="描述" min-width="200" />
          <el-table-column prop="rule_count" label="规则数" width="80" />
          <el-table-column prop="created_at" label="创建时间" width="170" />
        </el-table>
      </el-tab-pane>
      <el-tab-pane label="MAC地址池" name="macpools">
        <el-table :data="macPools" border stripe size="small">
          <el-table-column prop="name" label="名称" width="160" />
          <el-table-column prop="range_start" label="起始MAC" width="160" />
          <el-table-column prop="range_end" label="结束MAC" width="160" />
          <el-table-column prop="used_count" label="已用" width="80" />
        </el-table>
      </el-tab-pane>
    </el-tabs>

    <el-dialog v-model="dialogVisible" :title="editing ? '编辑网络' : '创建网络'" width="520px">
      <el-form :model="form" label-width="80px">
        <el-form-item label="名称"><el-input v-model="form.name" /></el-form-item>
        <el-form-item label="类型">
          <el-select v-model="form.type" style="width: 100%;"><el-option label="bridge" value="bridge" /><el-option label="nat" value="nat" /><el-option label="vlan" value="vlan" /></el-select>
        </el-form-item>
        <el-form-item label="VLAN ID" v-if="form.type==='vlan'"><el-input-number v-model="form.vlan_id" :min="1" :max="4094" /></el-form-item>
        <el-form-item label="子网"><el-input v-model="form.subnet" placeholder="192.168.200.0/24" /></el-form-item>
        <el-form-item label="网关"><el-input v-model="form.gateway" /></el-form-item>
        <el-form-item label="DHCP"><el-switch v-model="form.dhcp_enabled" :active-value="1" :inactive-value="0" /></el-form-item>
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

const loading = ref(false), dialogVisible = ref(false), editing = ref(null)
const tab = ref('networks')
const networks = ref([]), secGroups = ref([]), macPools = ref([])
const form = reactive({ name: '', type: 'bridge', vlan_id: 0, subnet: '', gateway: '', dhcp_enabled: 1 })

async function load() {
  loading.value = true
  try {
    networks.value = (await api.get('/networks')).data
    secGroups.value = (await api.get('/networks/security-groups')).data
    macPools.value = (await api.get('/networks/mac-pools')).data
  } catch(e) {} finally { loading.value = false }
}

function showDialog(n) {
  editing.value = n || null
  if (n) Object.assign(form, { name: n.name, type: n.type, vlan_id: n.vlan_id || 0, subnet: n.subnet, gateway: n.gateway, dhcp_enabled: n.dhcp_enabled ? 1 : 0 })
  else Object.assign(form, { name: '', type: 'bridge', vlan_id: 0, subnet: '', gateway: '', dhcp_enabled: 1 })
  dialogVisible.value = true
}

async function save() {
  if (editing.value) await api.put(`/networks/${editing.value.id}`, form)
  else await api.post('/networks', form)
  ElMessage.success('保存成功'); dialogVisible.value = false; load()
}

async function del(n) {
  await ElMessageBox.confirm(`确认删除网络 ${n.name}?`)
  await api.delete(`/networks/${n.id}`); ElMessage.success('已删除'); load()
}

onMounted(load)
</script>
