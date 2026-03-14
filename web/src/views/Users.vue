<template>
  <div>
    <div class="page-header">
      <h2>用户管理</h2>
      <el-button type="primary" @click="showDialog()"><el-icon><Plus /></el-icon>添加用户</el-button>
    </div>
    <el-tabs v-model="tab">
      <el-tab-pane label="用户列表" name="users">
        <el-table :data="users" v-loading="loading" border stripe>
          <el-table-column prop="username" label="用户名" width="120" />
          <el-table-column prop="display_name" label="显示名" width="120" />
          <el-table-column prop="role" label="角色" width="100">
            <template #default="{ row }">{{ roleText(row.role) }}</template>
          </el-table-column>
          <el-table-column prop="department" label="部门" width="120" />
          <el-table-column prop="email" label="邮箱" width="180" />
          <el-table-column prop="status" label="状态" width="80">
            <template #default="{ row }"><el-tag :type="row.status === 'active' ? 'success' : 'danger'" size="small">{{ row.status === 'active' ? '启用' : '禁用' }}</el-tag></template>
          </el-table-column>
          <el-table-column prop="last_login" label="最后登录" width="170" />
          <el-table-column prop="created_at" label="创建时间" min-width="160" />
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
        <el-table :data="groups" border stripe size="small">
          <el-table-column prop="name" label="组名" width="160" />
          <el-table-column prop="description" label="描述" min-width="200" />
          <el-table-column prop="member_count" label="成员数" width="80" />
          <el-table-column prop="created_at" label="创建时间" width="170" />
        </el-table>
      </el-tab-pane>
    </el-tabs>

    <el-dialog v-model="dialogVisible" :title="editing ? '编辑用户' : '添加用户'" width="500px">
      <el-form :model="form" label-width="80px">
        <el-form-item label="用户名"><el-input v-model="form.username" :disabled="!!editing" /></el-form-item>
        <el-form-item label="显示名"><el-input v-model="form.display_name" /></el-form-item>
        <el-form-item label="密码" v-if="!editing"><el-input v-model="form.password" type="password" show-password /></el-form-item>
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
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import api from '../api'
import { ElMessage, ElMessageBox } from 'element-plus'

const loading = ref(false), saving = ref(false), dialogVisible = ref(false), editing = ref(null)
const tab = ref('users')
const users = ref([]), groups = ref([])
const form = reactive({ username: '', display_name: '', password: '', role: 'user', department: '', email: '' })

function roleText(r) { return { sysadmin: '系统管理员', secadmin: '安全管理员', auditor: '审计管理员', user: '普通用户' }[r] || r }

async function load() {
  loading.value = true
  try {
    users.value = (await api.get('/users')).data
    groups.value = (await api.get('/users/groups')).data
  } catch(e) {} finally { loading.value = false }
}

function showDialog(u) {
  editing.value = u || null
  if (u) Object.assign(form, { username: u.username, display_name: u.display_name, password: '', role: u.role, department: u.department || '', email: u.email || '' })
  else Object.assign(form, { username: '', display_name: '', password: '', role: 'user', department: '', email: '' })
  dialogVisible.value = true
}

async function save() {
  saving.value = true
  try {
    if (editing.value) await api.put(`/users/${editing.value.id}`, form)
    else await api.post('/users', form)
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

onMounted(load)
</script>
