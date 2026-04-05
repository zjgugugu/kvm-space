<template>
  <div>
    <div class="page-header">
      <h2>安全组</h2>
      <el-button type="primary" @click="showDialog()"><el-icon><Plus /></el-icon>创建安全组</el-button>
    </div>
    <el-table :data="groups" v-loading="loading" border stripe size="small">
      <el-table-column prop="name" label="安全组名称" width="180" />
      <el-table-column prop="description" label="描述" min-width="200" />
      <el-table-column prop="rule_count" label="规则数" width="80">
        <template #default="{ row }">{{ (row.rules || []).length }}</template>
      </el-table-column>
      <el-table-column prop="created_at" label="创建时间" width="160" />
      <el-table-column label="操作" width="200" fixed="right">
        <template #default="{ row }">
          <el-button size="small" @click="showRules(row)">规则</el-button>
          <el-button size="small" @click="showDialog(row)">编辑</el-button>
          <el-button size="small" type="danger" @click="remove(row)">删除</el-button>
        </template>
      </el-table-column>
    </el-table>

    <el-dialog v-model="dialogVisible" :title="editing ? '编辑安全组' : '创建安全组'" width="450px">
      <el-form :model="form" label-width="80px">
        <el-form-item label="名称" required><el-input v-model="form.name" /></el-form-item>
        <el-form-item label="描述"><el-input v-model="form.description" type="textarea" :rows="2" /></el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="save">确定</el-button>
      </template>
    </el-dialog>

    <el-dialog v-model="rulesVisible" :title="`安全组规则 - ${activeGroup?.name || ''}`" width="700px">
      <div style="margin-bottom: 10px;">
        <el-button type="primary" size="small" @click="showRuleDialog()"><el-icon><Plus /></el-icon>添加规则</el-button>
      </div>
      <el-table :data="activeGroup?.rules || []" border stripe size="small">
        <el-table-column prop="direction" label="方向" width="80">
          <template #default="{ row }"><el-tag :type="row.direction === 'ingress' ? 'success' : 'warning'" size="small">{{ row.direction === 'ingress' ? '入站' : '出站' }}</el-tag></template>
        </el-table-column>
        <el-table-column prop="protocol" label="协议" width="80" />
        <el-table-column prop="port_range" label="端口范围" width="120" />
        <el-table-column prop="source" label="来源/目标" width="140" />
        <el-table-column prop="action" label="动作" width="80">
          <template #default="{ row }"><el-tag :type="row.action === 'accept' ? 'success' : 'danger'" size="small">{{ row.action === 'accept' ? '允许' : '拒绝' }}</el-tag></template>
        </el-table-column>
        <el-table-column label="操作" width="80">
          <template #default="{ row }">
            <el-button size="small" type="danger" @click="removeRule(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>

      <el-dialog v-model="ruleDialogVisible" title="添加规则" width="450px" append-to-body>
        <el-form :model="ruleForm" label-width="80px">
          <el-form-item label="方向">
            <el-select v-model="ruleForm.direction" style="width:100%"><el-option label="入站" value="ingress" /><el-option label="出站" value="egress" /></el-select>
          </el-form-item>
          <el-form-item label="协议">
            <el-select v-model="ruleForm.protocol" style="width:100%"><el-option label="TCP" value="tcp" /><el-option label="UDP" value="udp" /><el-option label="ICMP" value="icmp" /><el-option label="全部" value="all" /></el-select>
          </el-form-item>
          <el-form-item label="端口范围"><el-input v-model="ruleForm.port_range" placeholder="如: 80 或 8000-9000" /></el-form-item>
          <el-form-item label="来源"><el-input v-model="ruleForm.source" placeholder="0.0.0.0/0" /></el-form-item>
          <el-form-item label="动作">
            <el-select v-model="ruleForm.action" style="width:100%"><el-option label="允许" value="accept" /><el-option label="拒绝" value="drop" /></el-select>
          </el-form-item>
        </el-form>
        <template #footer>
          <el-button @click="ruleDialogVisible = false">取消</el-button>
          <el-button type="primary" @click="addRule">确定</el-button>
        </template>
      </el-dialog>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import api from '../api'
import { ElMessage, ElMessageBox } from 'element-plus'

const loading = ref(false)
const groups = ref([])
const dialogVisible = ref(false), editing = ref(null)
const form = reactive({ name: '', description: '' })
const rulesVisible = ref(false), activeGroup = ref(null)
const ruleDialogVisible = ref(false)
const ruleForm = reactive({ direction: 'ingress', protocol: 'tcp', port_range: '', source: '0.0.0.0/0', action: 'accept' })

async function load() {
  loading.value = true
  try { groups.value = (await api.get('/networks/security-groups')).data || [] }
  catch(e) { groups.value = [] }
  finally { loading.value = false }
}

function showDialog(g) {
  editing.value = g || null
  Object.assign(form, g ? { name: g.name, description: g.description || '' } : { name: '', description: '' })
  dialogVisible.value = true
}

async function save() {
  if (editing.value) await api.put(`/networks/security-groups/${editing.value.id}`, form)
  else await api.post('/networks/security-groups', form)
  ElMessage.success('保存成功'); dialogVisible.value = false; load()
}

async function remove(g) {
  await ElMessageBox.confirm(`确认删除安全组 ${g.name}?`, '删除', { type: 'warning' })
  await api.delete(`/networks/security-groups/${g.id}`); ElMessage.success('已删除'); load()
}

function showRules(g) { activeGroup.value = g; rulesVisible.value = true }

function showRuleDialog() {
  Object.assign(ruleForm, { direction: 'ingress', protocol: 'tcp', port_range: '', source: '0.0.0.0/0', action: 'accept' })
  ruleDialogVisible.value = true
}

async function addRule() {
  await api.post(`/networks/security-groups/${activeGroup.value.id}/rules`, ruleForm)
  ElMessage.success('规则已添加'); ruleDialogVisible.value = false; load()
  const updated = groups.value.find(g => g.id === activeGroup.value.id)
  if (updated) activeGroup.value = updated
}

async function removeRule(r) {
  await ElMessageBox.confirm('确认删除此规则?', '删除', { type: 'warning' })
  await api.delete(`/networks/security-groups/rules/${r.id}`); ElMessage.success('已删除'); load()
}

onMounted(load)
</script>
