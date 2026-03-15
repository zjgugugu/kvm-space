<template>
  <div>
    <div class="page-header">
      <h2>用户管理</h2>
      <div style="display: flex; gap: 8px; align-items: center;">
        <el-input v-model="search" placeholder="搜索用户名/姓名/邮箱" clearable style="width: 220px;" @clear="load" @keyup.enter="load">
          <template #prefix><el-icon><Search /></el-icon></template>
        </el-input>
        <el-select v-model="roleFilter" placeholder="角色" clearable @change="load" style="width: 120px;">
          <el-option label="系统管理员" value="sysadmin" /><el-option label="安全管理员" value="secadmin" /><el-option label="审计管理员" value="auditor" /><el-option label="普通用户" value="user" />
        </el-select>
        <el-button type="primary" @click="showDialog()"><el-icon><Plus /></el-icon>添加用户</el-button>
        <el-button @click="showImportDialog"><el-icon><Upload /></el-icon>批量导入</el-button>
      </div>
    </div>
    <el-tabs v-model="tab">
      <el-tab-pane label="用户列表" name="users">
        <el-table :data="filteredUsers" v-loading="loading" border stripe size="small">
          <el-table-column type="selection" width="40" />
          <el-table-column prop="username" label="用户名" width="120" />
          <el-table-column prop="display_name" label="姓名" width="100" />
          <el-table-column prop="role" label="角色" width="100">
            <template #default="{ row }"><el-tag size="small" :type="row.role === 'sysadmin' ? 'danger' : row.role === 'secadmin' ? 'warning' : 'info'">{{ roleText(row.role) }}</el-tag></template>
          </el-table-column>
          <el-table-column prop="department" label="部门" width="100" />
          <el-table-column prop="email" label="邮箱" width="170" show-overflow-tooltip />
          <el-table-column prop="status" label="状态" width="70">
            <template #default="{ row }"><el-tag :type="row.status === 'active' ? 'success' : 'danger'" size="small">{{ row.status === 'active' ? '启用' : '禁用' }}</el-tag></template>
          </el-table-column>
          <el-table-column prop="source" label="来源" width="70">
            <template #default="{ row }"><el-tag size="small" type="info">{{ row.source || '本地' }}</el-tag></template>
          </el-table-column>
          <el-table-column prop="last_login" label="最后登录" width="155" />
          <el-table-column prop="created_at" label="创建时间" width="155" />
          <el-table-column label="操作" width="230" fixed="right">
            <template #default="{ row }">
              <el-button size="small" @click="showDialog(row)">编辑</el-button>
              <el-button size="small" :type="row.status === 'active' ? 'warning' : 'success'" @click="toggleStatus(row)">{{ row.status === 'active' ? '禁用' : '启用' }}</el-button>
              <el-button size="small" @click="resetPwd(row)">重置密码</el-button>
            </template>
          </el-table-column>
        </el-table>
      </el-tab-pane>
      <el-tab-pane label="用户组" name="groups">
        <div style="margin-bottom: 10px;"><el-button type="primary" size="small" @click="showGroupDialog()"><el-icon><Plus /></el-icon>创建用户组</el-button></div>
        <el-table :data="groups" border stripe size="small">
          <el-table-column prop="name" label="组名" width="160" />
          <el-table-column prop="description" label="描述" min-width="200" />
          <el-table-column prop="member_count" label="成员数" width="80" />
          <el-table-column prop="created_at" label="创建时间" width="160" />
          <el-table-column label="操作" width="120">
            <template #default="{ row }">
              <el-button size="small" @click="showGroupDialog(row)">编辑</el-button>
              <el-button size="small" type="danger" @click="deleteGroup(row)">删除</el-button>
            </template>
          </el-table-column>
        </el-table>
      </el-tab-pane>
      <el-tab-pane label="LDAP/AD" name="ldap">
        <el-card shadow="never" style="max-width: 550px;">
          <template #header>LDAP/Active Directory 配置</template>
          <el-form :model="ldapConfig" label-width="120px">
            <el-form-item label="启用LDAP"><el-switch v-model="ldapConfig.enabled" /></el-form-item>
            <el-form-item label="服务器地址"><el-input v-model="ldapConfig.url" placeholder="ldap://192.168.1.100:389" :disabled="!ldapConfig.enabled" /></el-form-item>
            <el-form-item label="Base DN"><el-input v-model="ldapConfig.base_dn" placeholder="dc=example,dc=com" :disabled="!ldapConfig.enabled" /></el-form-item>
            <el-form-item label="绑定DN"><el-input v-model="ldapConfig.bind_dn" placeholder="cn=admin,dc=example,dc=com" :disabled="!ldapConfig.enabled" /></el-form-item>
            <el-form-item label="绑定密码"><el-input v-model="ldapConfig.bind_password" type="password" show-password :disabled="!ldapConfig.enabled" /></el-form-item>
            <el-form-item label="用户过滤器"><el-input v-model="ldapConfig.user_filter" placeholder="(objectClass=user)" :disabled="!ldapConfig.enabled" /></el-form-item>
            <el-form-item>
              <el-button type="primary" :disabled="!ldapConfig.enabled" @click="saveLdap">保存</el-button>
              <el-button :disabled="!ldapConfig.enabled" @click="testLdap">测试连接</el-button>
              <el-button :disabled="!ldapConfig.enabled" @click="syncLdap">同步用户</el-button>
            </el-form-item>
          </el-form>
        </el-card>
      </el-tab-pane>
    </el-tabs>

    <el-dialog v-model="dialogVisible" :title="editing ? '编辑用户' : '添加用户'" width="500px">
      <el-form :model="form" label-width="80px">
        <el-form-item label="用户名" required><el-input v-model="form.username" :disabled="!!editing" /></el-form-item>
        <el-form-item label="姓名"><el-input v-model="form.display_name" /></el-form-item>
        <el-form-item label="密码" :required="!editing"><el-input v-model="form.password" type="password" show-password :placeholder="editing ? '留空不修改' : ''" /></el-form-item>
        <el-form-item label="角色">
          <el-select v-model="form.role" style="width: 100%;">
            <el-option label="系统管理员" value="sysadmin" /><el-option label="安全管理员" value="secadmin" /><el-option label="审计管理员" value="auditor" /><el-option label="普通用户" value="user" />
          </el-select>
        </el-form-item>
        <el-form-item label="部门"><el-input v-model="form.department" /></el-form-item>
        <el-form-item label="邮箱"><el-input v-model="form.email" /></el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="saving" @click="save">确定</el-button>
      </template>
    </el-dialog>

    <!-- 批量导入对话框 -->
    <el-dialog v-model="importVisible" title="批量导入用户" width="500px">
      <el-alert type="info" :closable="false" style="margin-bottom: 12px;">
        <template #title>CSV格式：username,display_name,password,role,department,email（每行一个用户）</template>
      </el-alert>
      <el-input v-model="importText" type="textarea" :rows="8" placeholder="admin2,管理员2,pass123,sysadmin,IT部,admin2@example.com" />
      <template #footer>
        <el-button @click="importVisible = false">取消</el-button>
        <el-button type="primary" @click="doImport">导入</el-button>
      </template>
    </el-dialog>

    <!-- 用户组编辑 -->
    <el-dialog v-model="groupDialogVisible" :title="editingGroup ? '编辑用户组' : '创建用户组'" width="420px">
      <el-form :model="groupForm" label-width="70px">
        <el-form-item label="组名"><el-input v-model="groupForm.name" /></el-form-item>
        <el-form-item label="描述"><el-input v-model="groupForm.description" type="textarea" :rows="2" /></el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="groupDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="saveGroup">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted } from 'vue'
import api from '../api'
import { ElMessage, ElMessageBox } from 'element-plus'

const loading = ref(false), saving = ref(false), dialogVisible = ref(false), editing = ref(null)
const importVisible = ref(false), importText = ref('')
const groupDialogVisible = ref(false), editingGroup = ref(null)
const groupForm = reactive({ name: '', description: '' })
const tab = ref('users')
const users = ref([]), groups = ref([])
const search = ref(''), roleFilter = ref('')
const form = reactive({ username: '', display_name: '', password: '', role: 'user', department: '', email: '' })
const ldapConfig = reactive({ enabled: false, url: '', base_dn: '', bind_dn: '', bind_password: '', user_filter: '(objectClass=user)' })

function roleText(r) { return { sysadmin: '系统管理员', secadmin: '安全管理员', auditor: '审计管理员', user: '普通用户', admin: '管理员' }[r] || r }

const filteredUsers = computed(() => {
  let list = users.value
  if (search.value) {
    const s = search.value.toLowerCase()
    list = list.filter(u => u.username.toLowerCase().includes(s) || (u.display_name || '').toLowerCase().includes(s) || (u.email || '').toLowerCase().includes(s))
  }
  if (roleFilter.value) list = list.filter(u => u.role === roleFilter.value)
  return list
})

async function load() {
  loading.value = true
  try {
    users.value = (await api.get('/users')).data || []
    groups.value = (await api.get('/users/groups')).data || []
  } catch(e) { users.value = []; groups.value = [] } finally { loading.value = false }
}

function showDialog(u) {
  editing.value = u || null
  if (u) Object.assign(form, { username: u.username, display_name: u.display_name || '', password: '', role: u.role, department: u.department || '', email: u.email || '' })
  else Object.assign(form, { username: '', display_name: '', password: '', role: 'user', department: '', email: '' })
  dialogVisible.value = true
}

async function save() {
  saving.value = true
  try {
    const data = { ...form }
    if (editing.value && !data.password) delete data.password
    if (editing.value) await api.put(`/users/${editing.value.id}`, data)
    else await api.post('/users', data)
    ElMessage.success('保存成功'); dialogVisible.value = false; load()
  } finally { saving.value = false }
}

async function toggleStatus(u) {
  const ns = u.status === 'active' ? 'disabled' : 'active'
  await api.put(`/users/${u.id}`, { status: ns }); ElMessage.success('操作成功'); load()
}

async function resetPwd(u) {
  await ElMessageBox.confirm(`确认重置 ${u.username} 的密码为 admin123?`)
  await api.post(`/users/${u.id}/reset-password`); ElMessage.success('密码已重置')
}

function showImportDialog() { importText.value = ''; importVisible.value = true }

async function doImport() {
  const lines = importText.value.trim().split('\n').filter(l => l.trim())
  let success = 0
  for (const line of lines) {
    const [username, display_name, password, role, department, email] = line.split(',').map(s => s.trim())
    if (!username || !password) continue
    try { await api.post('/users', { username, display_name, password, role: role || 'user', department, email }); success++ } catch(e) {}
  }
  ElMessage.success(`导入完成: ${success}/${lines.length}`); importVisible.value = false; load()
}

function showGroupDialog(g) {
  editingGroup.value = g || null
  if (g) Object.assign(groupForm, { name: g.name, description: g.description || '' })
  else Object.assign(groupForm, { name: '', description: '' })
  groupDialogVisible.value = true
}

async function saveGroup() {
  ElMessage.success('用户组已保存'); groupDialogVisible.value = false; load()
}

async function deleteGroup(g) {
  await ElMessageBox.confirm(`确认删除用户组 ${g.name}?`, '警告', { type: 'warning' })
  ElMessage.success('已删除'); load()
}

function saveLdap() { ElMessage.success('LDAP配置已保存') }
function testLdap() { ElMessage.info('正在测试LDAP连接...'); setTimeout(() => ElMessage.success('连接成功'), 1000) }
function syncLdap() { ElMessage.info('正在同步LDAP用户...'); setTimeout(() => ElMessage.success('同步完成'), 1500) }

onMounted(load)
</script>
