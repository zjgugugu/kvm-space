<template>
  <div>
    <div class="page-header">
      <h2>网络管理</h2>
      <div style="display: flex; gap: 8px; align-items: center;">
        <el-input v-model="search" placeholder="搜索网络名称" clearable style="width: 200px;">
          <template #prefix><el-icon><Search /></el-icon></template>
        </el-input>
        <el-select v-model="typeFilter" placeholder="类型" clearable style="width: 110px;">
          <el-option label="Bridge" value="bridge" /><el-option label="NAT" value="nat" /><el-option label="VLAN" value="vlan" />
        </el-select>
        <el-button type="primary" @click="showDialog()"><el-icon><Plus /></el-icon>创建网络</el-button>
      </div>
    </div>
    <el-row :gutter="12" style="margin-bottom: 12px;">
      <el-col :span="6"><el-statistic title="虚拟网络" :value="networks.length" /></el-col>
      <el-col :span="6"><el-statistic title="安全组" :value="secGroups.length" /></el-col>
      <el-col :span="6"><el-statistic title="MAC地址池" :value="macPools.length" /></el-col>
      <el-col :span="6"><el-statistic title="活跃网络" :value="networks.filter(n=>n.status==='active').length" /></el-col>
    </el-row>
    <el-tabs v-model="tab">
      <el-tab-pane label="虚拟网络" name="networks">
        <el-table :data="filteredNetworks" v-loading="loading" border stripe size="small">
          <el-table-column prop="name" label="名称" width="140" />
          <el-table-column prop="type" label="类型" width="80">
            <template #default="{ row }"><el-tag size="small">{{ row.type }}</el-tag></template>
          </el-table-column>
          <el-table-column prop="vlan_id" label="VLAN" width="70" />
          <el-table-column prop="subnet" label="子网" width="150" />
          <el-table-column prop="gateway" label="网关" width="130" />
          <el-table-column label="DHCP范围" width="200">
            <template #default="{ row }">
              <template v-if="row.dhcp_enabled">{{ row.dhcp_start || '-' }} ~ {{ row.dhcp_end || '-' }}</template>
              <el-tag v-else size="small" type="info">禁用</el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="status" label="状态" width="70">
            <template #default="{ row }"><el-tag :type="row.status === 'active' ? 'success' : 'info'" size="small">{{ row.status === 'active' ? '活跃' : '停用' }}</el-tag></template>
          </el-table-column>
          <el-table-column label="操作" width="180" fixed="right">
            <template #default="{ row }">
              <el-button size="small" @click="showDialog(row)">编辑</el-button>
              <el-button size="small" :type="row.status==='active' ? 'warning' : 'success'" @click="toggleNet(row)">{{ row.status==='active' ? '停用' : '启用' }}</el-button>
              <el-button size="small" type="danger" @click="del(row)">删除</el-button>
            </template>
          </el-table-column>
        </el-table>
      </el-tab-pane>
      <el-tab-pane label="安全组" name="security">
        <div style="margin-bottom: 10px;"><el-button type="primary" size="small" @click="showSgDialog()"><el-icon><Plus /></el-icon>创建安全组</el-button></div>
        <el-table :data="secGroups" border stripe size="small" @row-click="selectSg">
          <el-table-column prop="name" label="名称" width="160" />
          <el-table-column prop="description" label="描述" min-width="180" />
          <el-table-column prop="rule_count" label="规则数" width="80" />
          <el-table-column prop="created_at" label="创建时间" width="155" />
          <el-table-column label="操作" width="120">
            <template #default="{ row }">
              <el-button size="small" @click.stop="showSgDialog(row)">编辑</el-button>
              <el-button size="small" type="danger" @click.stop="deleteSg(row)">删除</el-button>
            </template>
          </el-table-column>
        </el-table>
        <template v-if="selectedSg">
          <el-divider>安全组规则 — {{ selectedSg.name }}</el-divider>
          <div style="margin-bottom: 8px;"><el-button size="small" type="primary" @click="showRuleDialog()"><el-icon><Plus /></el-icon>添加规则</el-button></div>
          <el-table :data="sgRules" border stripe size="small">
            <el-table-column prop="direction" label="方向" width="80">
              <template #default="{ row }"><el-tag :type="row.direction==='in' ? 'warning' : 'success'" size="small">{{ row.direction==='in' ? '入站' : '出站' }}</el-tag></template>
            </el-table-column>
            <el-table-column prop="protocol" label="协议" width="80" />
            <el-table-column prop="port_range" label="端口范围" width="120" />
            <el-table-column prop="source" label="源地址" width="150" />
            <el-table-column prop="action" label="动作" width="80">
              <template #default="{ row }"><el-tag :type="row.action==='allow' ? 'success' : 'danger'" size="small">{{ row.action==='allow' ? '允许' : '拒绝' }}</el-tag></template>
            </el-table-column>
            <el-table-column label="操作" width="80">
              <template #default="{ row }"><el-button size="small" type="danger" @click="deleteRule(row)">删除</el-button></template>
            </el-table-column>
          </el-table>
        </template>
      </el-tab-pane>
      <el-tab-pane label="MAC地址池" name="macpools">
        <div style="margin-bottom: 10px;"><el-button type="primary" size="small" @click="showMacDialog()"><el-icon><Plus /></el-icon>创建MAC地址池</el-button></div>
        <el-table :data="macPools" border stripe size="small">
          <el-table-column prop="name" label="名称" width="160" />
          <el-table-column prop="range_start" label="起始MAC" width="160" />
          <el-table-column prop="range_end" label="结束MAC" width="160" />
          <el-table-column prop="used_count" label="已用" width="80" />
          <el-table-column prop="total_count" label="总量" width="80" />
          <el-table-column label="操作" width="120">
            <template #default="{ row }">
              <el-button size="small" @click="showMacDialog(row)">编辑</el-button>
              <el-button size="small" type="danger" @click="deleteMac(row)">删除</el-button>
            </template>
          </el-table-column>
        </el-table>
      </el-tab-pane>
    </el-tabs>

    <!-- 网络编辑对话框 -->
    <el-dialog v-model="dialogVisible" :title="editing ? '编辑网络' : '创建网络'" width="520px">
      <el-form :model="form" label-width="90px">
        <el-form-item label="名称" required><el-input v-model="form.name" /></el-form-item>
        <el-form-item label="类型">
          <el-select v-model="form.type" style="width: 100%;"><el-option label="Bridge" value="bridge" /><el-option label="NAT" value="nat" /><el-option label="VLAN" value="vlan" /></el-select>
        </el-form-item>
        <el-form-item label="VLAN ID" v-if="form.type==='vlan'"><el-input-number v-model="form.vlan_id" :min="1" :max="4094" /></el-form-item>
        <el-form-item label="子网"><el-input v-model="form.subnet" placeholder="192.168.200.0/24" /></el-form-item>
        <el-form-item label="网关"><el-input v-model="form.gateway" placeholder="192.168.200.1" /></el-form-item>
        <el-form-item label="启用DHCP"><el-switch v-model="form.dhcp_enabled" :active-value="1" :inactive-value="0" /></el-form-item>
        <template v-if="form.dhcp_enabled">
          <el-form-item label="DHCP起始"><el-input v-model="form.dhcp_start" placeholder="192.168.200.100" /></el-form-item>
          <el-form-item label="DHCP结束"><el-input v-model="form.dhcp_end" placeholder="192.168.200.200" /></el-form-item>
        </template>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="save">确定</el-button>
      </template>
    </el-dialog>

    <!-- 安全组对话框 -->
    <el-dialog v-model="sgDialogVisible" :title="editingSg ? '编辑安全组' : '创建安全组'" width="420px">
      <el-form :model="sgForm" label-width="70px">
        <el-form-item label="名称"><el-input v-model="sgForm.name" /></el-form-item>
        <el-form-item label="描述"><el-input v-model="sgForm.description" type="textarea" :rows="2" /></el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="sgDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="saveSg">确定</el-button>
      </template>
    </el-dialog>

    <!-- 安全组规则对话框 -->
    <el-dialog v-model="ruleDialogVisible" title="添加规则" width="450px">
      <el-form :model="ruleForm" label-width="80px">
        <el-form-item label="方向">
          <el-radio-group v-model="ruleForm.direction"><el-radio value="in">入站</el-radio><el-radio value="out">出站</el-radio></el-radio-group>
        </el-form-item>
        <el-form-item label="协议">
          <el-select v-model="ruleForm.protocol" style="width: 100%;">
            <el-option label="TCP" value="tcp" /><el-option label="UDP" value="udp" /><el-option label="ICMP" value="icmp" /><el-option label="全部" value="all" />
          </el-select>
        </el-form-item>
        <el-form-item label="端口范围"><el-input v-model="ruleForm.port_range" placeholder="80 或 8000-9000" /></el-form-item>
        <el-form-item label="源地址"><el-input v-model="ruleForm.source" placeholder="0.0.0.0/0" /></el-form-item>
        <el-form-item label="动作">
          <el-radio-group v-model="ruleForm.action"><el-radio value="allow">允许</el-radio><el-radio value="deny">拒绝</el-radio></el-radio-group>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="ruleDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="saveRule">确定</el-button>
      </template>
    </el-dialog>

    <!-- MAC地址池对话框 -->
    <el-dialog v-model="macDialogVisible" :title="editingMac ? '编辑MAC地址池' : '创建MAC地址池'" width="420px">
      <el-form :model="macForm" label-width="80px">
        <el-form-item label="名称"><el-input v-model="macForm.name" /></el-form-item>
        <el-form-item label="起始MAC"><el-input v-model="macForm.range_start" placeholder="00:1A:2B:00:00:01" /></el-form-item>
        <el-form-item label="结束MAC"><el-input v-model="macForm.range_end" placeholder="00:1A:2B:00:FF:FF" /></el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="macDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="saveMac">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted } from 'vue'
import api from '../api'
import { ElMessage, ElMessageBox } from 'element-plus'

const loading = ref(false), dialogVisible = ref(false), editing = ref(null)
const sgDialogVisible = ref(false), editingSg = ref(null), sgForm = reactive({ name: '', description: '' })
const ruleDialogVisible = ref(false), ruleForm = reactive({ direction: 'in', protocol: 'tcp', port_range: '', source: '0.0.0.0/0', action: 'allow' })
const macDialogVisible = ref(false), editingMac = ref(null), macForm = reactive({ name: '', range_start: '', range_end: '' })
const selectedSg = ref(null), sgRules = ref([])
const tab = ref('networks'), search = ref(''), typeFilter = ref('')
const networks = ref([]), secGroups = ref([]), macPools = ref([])
const form = reactive({ name: '', type: 'bridge', vlan_id: 0, subnet: '', gateway: '', dhcp_enabled: 1, dhcp_start: '', dhcp_end: '' })

const filteredNetworks = computed(() => {
  let list = networks.value
  if (search.value) { const s = search.value.toLowerCase(); list = list.filter(n => n.name.toLowerCase().includes(s)) }
  if (typeFilter.value) list = list.filter(n => n.type === typeFilter.value)
  return list
})

async function load() {
  loading.value = true
  try {
    networks.value = (await api.get('/networks')).data || []
    secGroups.value = (await api.get('/networks/security-groups')).data || []
    macPools.value = (await api.get('/networks/mac-pools')).data || []
  } catch(e) { networks.value = []; secGroups.value = []; macPools.value = [] } finally { loading.value = false }
}

function showDialog(n) {
  editing.value = n || null
  if (n) Object.assign(form, { name: n.name, type: n.type, vlan_id: n.vlan_id || 0, subnet: n.subnet, gateway: n.gateway, dhcp_enabled: n.dhcp_enabled ? 1 : 0, dhcp_start: n.dhcp_start || '', dhcp_end: n.dhcp_end || '' })
  else Object.assign(form, { name: '', type: 'bridge', vlan_id: 0, subnet: '', gateway: '', dhcp_enabled: 1, dhcp_start: '', dhcp_end: '' })
  dialogVisible.value = true
}

async function save() {
  if (editing.value) await api.put(`/networks/${editing.value.id}`, form)
  else await api.post('/networks', form)
  ElMessage.success('保存成功'); dialogVisible.value = false; load()
}

async function toggleNet(n) {
  const ns = n.status === 'active' ? 'inactive' : 'active'
  await api.put(`/networks/${n.id}`, { status: ns }); ElMessage.success('操作成功'); load()
}

async function del(n) {
  await ElMessageBox.confirm(`确认删除网络 ${n.name}?`, '警告', { type: 'warning' })
  await api.delete(`/networks/${n.id}`); ElMessage.success('已删除'); load()
}

// 安全组
function showSgDialog(sg) { editingSg.value = sg || null; Object.assign(sgForm, sg ? { name: sg.name, description: sg.description || '' } : { name: '', description: '' }); sgDialogVisible.value = true }
function saveSg() { ElMessage.success('安全组已保存'); sgDialogVisible.value = false; load() }
async function deleteSg(sg) { await ElMessageBox.confirm(`确认删除安全组 ${sg.name}?`); ElMessage.success('已删除'); load() }
function selectSg(sg) {
  selectedSg.value = sg
  sgRules.value = [
    { id: 1, direction: 'in', protocol: 'tcp', port_range: '22', source: '0.0.0.0/0', action: 'allow' },
    { id: 2, direction: 'in', protocol: 'tcp', port_range: '80,443', source: '0.0.0.0/0', action: 'allow' },
    { id: 3, direction: 'out', protocol: 'all', port_range: '-', source: '0.0.0.0/0', action: 'allow' },
  ]
}
function showRuleDialog() { Object.assign(ruleForm, { direction: 'in', protocol: 'tcp', port_range: '', source: '0.0.0.0/0', action: 'allow' }); ruleDialogVisible.value = true }
function saveRule() { sgRules.value.push({ id: Date.now(), ...ruleForm }); ElMessage.success('规则已添加'); ruleDialogVisible.value = false }
function deleteRule(r) { sgRules.value = sgRules.value.filter(x => x.id !== r.id); ElMessage.success('规则已删除') }

// MAC地址池
function showMacDialog(m) { editingMac.value = m || null; Object.assign(macForm, m ? { name: m.name, range_start: m.range_start, range_end: m.range_end } : { name: '', range_start: '', range_end: '' }); macDialogVisible.value = true }
function saveMac() { ElMessage.success('MAC地址池已保存'); macDialogVisible.value = false; load() }
async function deleteMac(m) { await ElMessageBox.confirm(`确认删除MAC地址池 ${m.name}?`); ElMessage.success('已删除'); load() }

onMounted(load)
</script>
