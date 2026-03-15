<template>
  <div>
    <div class="page-header"><h2>系统管理</h2></div>

    <el-tabs v-model="activeTab" tab-position="left" style="min-height: 500px;">
      <!-- 管理员账户 -->
      <el-tab-pane label="管理员账户" name="admins">
        <div style="margin-bottom: 12px; display: flex; justify-content: space-between;">
          <h4 style="margin: 0;">管理员账户列表</h4>
          <el-button type="primary" size="small" @click="showUserDialog()"><el-icon><Plus /></el-icon>新增管理员</el-button>
        </div>
        <el-table :data="admins" border stripe size="small">
          <el-table-column prop="username" label="用户名" width="120" />
          <el-table-column prop="display_name" label="姓名" width="120" />
          <el-table-column prop="email" label="邮箱" width="180" />
          <el-table-column prop="role" label="角色" width="100"><template #default="{ row }"><el-tag size="small">{{ row.role }}</el-tag></template></el-table-column>
          <el-table-column prop="status" label="状态" width="80">
            <template #default="{ row }"><el-tag :type="row.status === 'active' ? 'success' : 'danger'" size="small">{{ row.status === 'active' ? '启用' : '禁用' }}</el-tag></template>
          </el-table-column>
          <el-table-column prop="last_login" label="最近登录" width="160" />
          <el-table-column label="操作" width="160">
            <template #default="{ row }">
              <el-button size="small" @click="showUserDialog(row)">编辑</el-button>
              <el-button size="small" type="danger" @click="deleteUser(row)" :disabled="row.username === 'admin'">删除</el-button>
            </template>
          </el-table-column>
        </el-table>
      </el-tab-pane>

      <!-- 密码策略 -->
      <el-tab-pane label="密码策略" name="password">
        <el-form :model="passwordPolicy" label-width="140px" style="max-width: 500px;">
          <el-form-item label="最小密码长度"><el-input-number v-model="passwordPolicy.min_length" :min="6" :max="32" /></el-form-item>
          <el-form-item label="密码复杂度">
            <el-checkbox-group v-model="passwordPolicy.complexity">
              <el-checkbox label="uppercase">大写字母</el-checkbox>
              <el-checkbox label="lowercase">小写字母</el-checkbox>
              <el-checkbox label="number">数字</el-checkbox>
              <el-checkbox label="special">特殊字符</el-checkbox>
            </el-checkbox-group>
          </el-form-item>
          <el-form-item label="密码过期天数"><el-input-number v-model="passwordPolicy.expire_days" :min="0" :max="365" /><span style="margin-left: 8px; color: #909399;">0=永不过期</span></el-form-item>
          <el-form-item label="登录失败锁定"><el-input-number v-model="passwordPolicy.max_failures" :min="0" :max="20" /><span style="margin-left: 8px; color: #909399;">次</span></el-form-item>
          <el-form-item><el-button type="primary" @click="savePasswordPolicy">保存</el-button></el-form-item>
        </el-form>
      </el-tab-pane>

      <!-- 访问策略 -->
      <el-tab-pane label="访问策略" name="access">
        <el-form :model="accessPolicy" label-width="140px" style="max-width: 500px;">
          <el-form-item label="会话超时(分钟)"><el-input-number v-model="accessPolicy.session_timeout" :min="5" :max="480" /></el-form-item>
          <el-form-item label="允许多端登录"><el-switch v-model="accessPolicy.multi_login" /></el-form-item>
          <el-form-item label="IP白名单"><el-input v-model="accessPolicy.ip_whitelist" type="textarea" :rows="3" placeholder="每行一个IP或CIDR，留空不限制" /></el-form-item>
          <el-form-item><el-button type="primary" @click="saveAccessPolicy">保存</el-button></el-form-item>
        </el-form>
      </el-tab-pane>

      <!-- 角色管理 -->
      <el-tab-pane label="角色管理" name="roles">
        <el-table :data="roles" border stripe size="small">
          <el-table-column prop="name" label="角色名" width="120" />
          <el-table-column prop="description" label="描述" width="200" />
          <el-table-column label="权限" min-width="200">
            <template #default="{ row }">
              <el-tag v-for="p in (row.permissions || []).slice(0, 5)" :key="p" size="small" style="margin: 2px;">{{ p }}</el-tag>
              <el-tag v-if="(row.permissions || []).length > 5" size="small" type="info">+{{ row.permissions.length - 5 }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="user_count" label="用户数" width="80" />
        </el-table>
      </el-tab-pane>

      <!-- SMTP配置 -->
      <el-tab-pane label="邮件通知" name="smtp">
        <el-form :model="smtpConfig" label-width="120px" style="max-width: 500px;">
          <el-form-item label="SMTP服务器"><el-input v-model="smtpConfig.host" placeholder="smtp.example.com" /></el-form-item>
          <el-form-item label="端口"><el-input-number v-model="smtpConfig.port" :min="1" :max="65535" /></el-form-item>
          <el-form-item label="加密方式">
            <el-select v-model="smtpConfig.encryption" style="width: 100%;"><el-option label="无" value="none" /><el-option label="SSL" value="ssl" /><el-option label="TLS" value="tls" /></el-select>
          </el-form-item>
          <el-form-item label="发件人"><el-input v-model="smtpConfig.from" /></el-form-item>
          <el-form-item label="用户名"><el-input v-model="smtpConfig.username" /></el-form-item>
          <el-form-item label="密码"><el-input v-model="smtpConfig.password" type="password" show-password /></el-form-item>
          <el-form-item>
            <el-button type="primary" @click="saveSmtp">保存</el-button>
            <el-button @click="testSmtp">发送测试邮件</el-button>
          </el-form-item>
        </el-form>
      </el-tab-pane>

      <!-- 系统备份 -->
      <el-tab-pane label="系统备份" name="backup">
        <div style="margin-bottom: 12px;"><el-button type="primary" @click="createBackup"><el-icon><Download /></el-icon>创建备份</el-button></div>
        <el-table :data="backups" border stripe size="small">
          <el-table-column prop="name" label="备份名称" width="200" />
          <el-table-column prop="created_at" label="创建时间" width="170" />
          <el-table-column prop="size" label="大小" width="100" />
          <el-table-column prop="type" label="类型" width="100"><template #default="{ row }"><el-tag size="small">{{ row.type }}</el-tag></template></el-table-column>
          <el-table-column label="操作" width="160">
            <template #default="{ row }">
              <el-button size="small" type="primary" @click="restoreBackup(row)">恢复</el-button>
              <el-button size="small" type="danger" @click="deleteBackup(row)">删除</el-button>
            </template>
          </el-table-column>
        </el-table>
      </el-tab-pane>

      <!-- 系统配置 -->
      <el-tab-pane label="系统配置" name="config">
        <el-table :data="configs" v-loading="loading" border stripe size="small">
          <el-table-column prop="key" label="配置项" width="200" />
          <el-table-column prop="description" label="说明" min-width="200" />
          <el-table-column label="当前值" width="200">
            <template #default="{ row }">
              <el-input v-if="editingKey === row.key" v-model="editValue" size="small" @keyup.enter="saveConfig(row)" />
              <span v-else>{{ row.value }}</span>
            </template>
          </el-table-column>
          <el-table-column label="操作" width="150" fixed="right">
            <template #default="{ row }">
              <template v-if="editingKey === row.key">
                <el-button size="small" type="primary" @click="saveConfig(row)">保存</el-button>
                <el-button size="small" @click="editingKey = ''">取消</el-button>
              </template>
              <el-button v-else size="small" @click="startEdit(row)">修改</el-button>
            </template>
          </el-table-column>
        </el-table>
      </el-tab-pane>

      <!-- 系统信息 -->
      <el-tab-pane label="关于系统" name="about">
        <el-descriptions :column="2" border size="default" title="系统信息" style="max-width: 600px;">
          <el-descriptions-item label="平台名称">{{ info.name }}</el-descriptions-item>
          <el-descriptions-item label="版本号">{{ info.version }}</el-descriptions-item>
          <el-descriptions-item label="运行模式">{{ info.mode }}</el-descriptions-item>
          <el-descriptions-item label="数据库">SQLite</el-descriptions-item>
          <el-descriptions-item label="Node.js">v18.18.2</el-descriptions-item>
          <el-descriptions-item label="虚拟化驱动">MockDriver</el-descriptions-item>
        </el-descriptions>
        <el-divider />
        <el-descriptions :column="1" border size="default" title="许可证信息" style="max-width: 600px;">
          <el-descriptions-item label="许可类型">开发版</el-descriptions-item>
          <el-descriptions-item label="最大服务器">无限制</el-descriptions-item>
          <el-descriptions-item label="最大虚拟机">无限制</el-descriptions-item>
        </el-descriptions>
      </el-tab-pane>
    </el-tabs>

    <!-- 用户编辑对话框 -->
    <el-dialog v-model="userDialogVisible" :title="editingUser ? '编辑管理员' : '新增管理员'" width="450px">
      <el-form :model="userForm" label-width="80px">
        <el-form-item label="用户名" required><el-input v-model="userForm.username" :disabled="!!editingUser" /></el-form-item>
        <el-form-item label="姓名"><el-input v-model="userForm.display_name" /></el-form-item>
        <el-form-item label="邮箱"><el-input v-model="userForm.email" /></el-form-item>
        <el-form-item label="密码" :required="!editingUser"><el-input v-model="userForm.password" type="password" show-password :placeholder="editingUser ? '留空不修改' : ''" /></el-form-item>
        <el-form-item label="角色">
          <el-select v-model="userForm.role" style="width: 100%;"><el-option label="admin" value="admin" /><el-option label="operator" value="operator" /><el-option label="user" value="user" /></el-select>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="userDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="saveUser">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import api from '../api'
import { ElMessage, ElMessageBox } from 'element-plus'

const loading = ref(false)
const activeTab = ref('admins')
const configs = ref([]), info = ref({})
const editingKey = ref(''), editValue = ref('')
const admins = ref([])
const userDialogVisible = ref(false), editingUser = ref(null)
const userForm = reactive({ username: '', display_name: '', email: '', password: '', role: 'admin' })

// Password policy
const passwordPolicy = reactive({ min_length: 8, complexity: ['uppercase', 'lowercase', 'number'], expire_days: 90, max_failures: 5 })
// Access policy
const accessPolicy = reactive({ session_timeout: 30, multi_login: false, ip_whitelist: '' })
// SMTP
const smtpConfig = reactive({ host: '', port: 25, encryption: 'none', from: '', username: '', password: '' })
// Roles
const roles = ref([
  { name: 'admin', description: '系统管理员', permissions: ['全部权限'], user_count: 1 },
  { name: 'operator', description: '运维操作员', permissions: ['VM管理', '主机查看', '日志查看', '模板管理'], user_count: 0 },
  { name: 'user', description: '普通用户', permissions: ['查看分配的VM', '远程连接'], user_count: 0 }
])
// Backups
const backups = ref([
  { name: 'backup_2024-01-15_auto', created_at: '2024-01-15 02:00:00', size: '156 MB', type: '自动备份' },
  { name: 'backup_2024-01-10_manual', created_at: '2024-01-10 14:30:00', size: '143 MB', type: '手动备份' }
])

async function load() {
  loading.value = true
  try {
    configs.value = (await api.get('/system/config')).data || []
    info.value = await api.get('/info')
    admins.value = (await api.get('/users')).data || []
  } catch(e) {} finally { loading.value = false }
}

function startEdit(row) { editingKey.value = row.key; editValue.value = row.value }

async function saveConfig(row) {
  await api.put(`/system/config/${row.key}`, { value: editValue.value })
  ElMessage.success('已保存'); editingKey.value = ''; load()
}

function showUserDialog(user) {
  editingUser.value = user || null
  if (user) Object.assign(userForm, { username: user.username, display_name: user.display_name || '', email: user.email || '', password: '', role: user.role })
  else Object.assign(userForm, { username: '', display_name: '', email: '', password: '', role: 'admin' })
  userDialogVisible.value = true
}

async function saveUser() {
  if (editingUser.value) {
    const data = { ...userForm }
    if (!data.password) delete data.password
    await api.put(`/users/${editingUser.value.id}`, data)
  } else {
    await api.post('/users', userForm)
  }
  ElMessage.success('保存成功'); userDialogVisible.value = false; load()
}

async function deleteUser(user) {
  await ElMessageBox.confirm(`确认删除用户 ${user.username}?`, '警告', { type: 'warning' })
  await api.delete(`/users/${user.id}`); ElMessage.success('已删除'); load()
}

function savePasswordPolicy() { ElMessage.success('密码策略已保存') }
function saveAccessPolicy() { ElMessage.success('访问策略已保存') }
function saveSmtp() { ElMessage.success('邮件配置已保存') }
function testSmtp() { ElMessage.info('测试邮件已发送') }
function createBackup() {
  const name = `backup_${new Date().toISOString().slice(0,10)}_manual`
  backups.value.unshift({ name, created_at: new Date().toLocaleString(), size: '-- MB', type: '手动备份' })
  ElMessage.success('备份已创建')
}
function restoreBackup(b) { ElMessageBox.confirm(`确认从 ${b.name} 恢复?`, '恢复备份', { type: 'warning' }).then(() => ElMessage.success('恢复完成')) }
function deleteBackup(b) { ElMessageBox.confirm(`确认删除备份 ${b.name}?`, '删除', { type: 'warning' }).then(() => { backups.value = backups.value.filter(x => x !== b); ElMessage.success('已删除') }) }

onMounted(load)
</script>
