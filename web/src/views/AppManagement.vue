<template>
  <div>
    <div class="page-header">
      <h2>{{ route.meta.title }}</h2>
      <el-button type="primary" @click="showDialog = true">
        <el-icon><Plus /></el-icon> {{ addLabel }}
      </el-button>
    </div>

    <el-card shadow="hover">
      <div style="margin-bottom: 16px; display: flex; gap: 12px;">
        <el-input v-model="search" placeholder="搜索..." clearable style="width: 240px">
          <template #prefix><el-icon><Search /></el-icon></template>
        </el-input>
        <el-select v-if="statusOptions.length" v-model="statusFilter" placeholder="状态" clearable style="width: 140px">
          <el-option v-for="o in statusOptions" :key="o.value" :label="o.label" :value="o.value" />
        </el-select>
      </div>
      <el-table :data="filteredData" border stripe v-loading="loading" max-height="600">
        <el-table-column v-for="col in columns" :key="col.prop" :prop="col.prop" :label="col.label" :width="col.width" :min-width="col.minWidth">
          <template #default="{ row }" v-if="col.type">
            <el-tag v-if="col.type === 'tag'" :type="col.tagType?.(row[col.prop]) || ''">{{ row[col.prop] }}</el-tag>
            <el-tag v-else-if="col.type === 'status'" :type="row[col.prop] === '启用' || row[col.prop] === '运行中' ? 'success' : 'info'">{{ row[col.prop] }}</el-tag>
            <span v-else-if="col.type === 'size'">{{ row[col.prop] }} MB</span>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="200" fixed="right">
          <template #default="{ row }">
            <el-button size="small" @click="editRow(row)">编辑</el-button>
            <el-button size="small" type="danger" @click="deleteRow(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- Dialog -->
    <el-dialog v-model="showDialog" :title="editingId ? '编辑' : '新建'" width="500px">
      <el-form :model="form" label-width="120px">
        <el-form-item v-for="field in formFields" :key="field.key" :label="field.label">
          <el-switch v-if="field.type === 'switch'" v-model="form[field.key]" />
          <el-select v-else-if="field.type === 'select'" v-model="form[field.key]" style="width: 100%">
            <el-option v-for="o in field.options" :key="o.value" :label="o.label" :value="o.value" />
          </el-select>
          <el-input-number v-else-if="field.type === 'number'" v-model="form[field.key]" :min="field.min||0" />
          <el-input v-else-if="field.type === 'textarea'" v-model="form[field.key]" type="textarea" :rows="3" />
          <el-input v-else v-model="form[field.key]" :placeholder="field.placeholder || ''" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showDialog = false">取消</el-button>
        <el-button type="primary" @click="saveItem">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted, watch } from 'vue'
import { useRoute } from 'vue-router'
import { Plus, Search } from '@element-plus/icons-vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import api from '../api'

const route = useRoute()
const loading = ref(false)
const search = ref('')
const statusFilter = ref('')
const showDialog = ref(false)
const editingId = ref(null)
const form = reactive({})
const tableData = ref([])

// Route name to API endpoint mapping
const apiMap = {
  AppLayers: '/apps/layers',
  SoftwareLibrary: '/apps/software',
  SoftwarePublish: '/apps/software-publish',
  AppControlBuiltin: '/apps/control-rules?type=builtin',
  AppControlCustom: '/apps/control-rules?type=custom',
  VirtualAppGroups: '/apps/virtual-groups',
  VirtualAppSessions: '/apps/virtual-sessions',
}

function getApiPath() {
  const ep = apiMap[route.name]
  return ep ? ep.split('?')[0] : null
}

function getApiListUrl() {
  return apiMap[route.name] || null
}

const config = computed(() => {
  switch (route.name) {
    case 'AppLayers': return {
      addLabel: '新建应用层',
      statusOptions: [{ label: '可用', value: '可用' }, { label: '不可用', value: '不可用' }],
      columns: [
        { prop: 'name', label: '名称', minWidth: 150 },
        { prop: 'description', label: '描述', minWidth: 200 },
        { prop: 'os_type', label: '操作系统' },
        { prop: 'size', label: '大小', type: 'size', width: 100 },
        { prop: 'status', label: '状态', type: 'status', width: 100 },
        { prop: 'created_at', label: '创建时间', width: 160 },
      ],
      formFields: [
        { key: 'name', label: '名称' },
        { key: 'description', label: '描述', type: 'textarea' },
        { key: 'os_type', label: '操作系统', type: 'select', options: [{ label: 'KylinOS V10', value: 'KylinOS V10' }, { label: 'UOS 20', value: 'UOS 20' }, { label: 'CentOS 7', value: 'CentOS 7' }] },
        { key: 'base_image', label: '基础镜像' },
      ],
      demoData: [
        { id: 1, name: 'office-layer', description: 'WPS Office + LibreOffice', os_type: 'KylinOS V10', size: 2048, status: '可用', created_at: '2025-01-15 10:00' },
        { id: 2, name: 'dev-tools-layer', description: '开发工具集合', os_type: 'KylinOS V10', size: 3072, status: '可用', created_at: '2025-01-16 14:30' },
        { id: 3, name: 'browser-layer', description: '浏览器插件', os_type: 'UOS 20', size: 512, status: '不可用', created_at: '2025-01-17 09:00' },
      ]
    }
    case 'SoftwareLibrary': return {
      addLabel: '上传软件',
      statusOptions: [{ label: '已发布', value: '已发布' }, { label: '草稿', value: '草稿' }],
      columns: [
        { prop: 'name', label: '软件名称', minWidth: 150 },
        { prop: 'version', label: '版本', width: 100 },
        { prop: 'category', label: '分类', width: 120 },
        { prop: 'size', label: '大小', type: 'size', width: 100 },
        { prop: 'status', label: '状态', type: 'status', width: 100 },
        { prop: 'upload_time', label: '上传时间', width: 160 },
      ],
      formFields: [
        { key: 'name', label: '软件名称' },
        { key: 'version', label: '版本号' },
        { key: 'category', label: '分类', type: 'select', options: [{ label: '办公软件', value: '办公软件' }, { label: '开发工具', value: '开发工具' }, { label: '安全软件', value: '安全软件' }, { label: '系统工具', value: '系统工具' }] },
        { key: 'description', label: '描述', type: 'textarea' },
      ],
      demoData: [
        { id: 1, name: 'WPS Office', version: '11.1.0', category: '办公软件', size: 380, status: '已发布', upload_time: '2025-01-10 08:00' },
        { id: 2, name: '360安全浏览器', version: '13.1', category: '安全软件', size: 120, status: '已发布', upload_time: '2025-01-11 09:00' },
        { id: 3, name: 'GCC编译器', version: '12.2', category: '开发工具', size: 210, status: '草稿', upload_time: '2025-01-12 10:00' },
      ]
    }
    case 'SoftwarePublish': return {
      addLabel: '新建发布任务',
      statusOptions: [{ label: '进行中', value: '进行中' }, { label: '已完成', value: '已完成' }, { label: '失败', value: '失败' }],
      columns: [
        { prop: 'name', label: '任务名称', minWidth: 150 },
        { prop: 'software', label: '软件', minWidth: 120 },
        { prop: 'target', label: '目标范围', minWidth: 120 },
        { prop: 'progress', label: '进度', width: 100 },
        { prop: 'status', label: '状态', type: 'status', width: 100 },
        { prop: 'created_at', label: '创建时间', width: 160 },
      ],
      formFields: [
        { key: 'name', label: '任务名称' },
        { key: 'software', label: '选择软件' },
        { key: 'target', label: '目标范围', type: 'select', options: [{ label: '所有桌面', value: '所有桌面' }, { label: '指定桌面池', value: '指定桌面池' }, { label: '指定用户组', value: '指定用户组' }] },
        { key: 'auto_install', label: '自动安装', type: 'switch' },
      ],
      demoData: [
        { id: 1, name: 'WPS全量部署', software: 'WPS Office 11.1.0', target: '所有桌面', progress: '100%', status: '已完成', created_at: '2025-01-15 14:00' },
        { id: 2, name: '浏览器更新', software: '360安全浏览器 13.1', target: '指定桌面池', progress: '65%', status: '进行中', created_at: '2025-01-18 09:30' },
      ]
    }
    case 'AppControlBuiltin': return {
      addLabel: '新建规则',
      statusOptions: [{ label: '启用', value: '启用' }, { label: '禁用', value: '禁用' }],
      columns: [
        { prop: 'name', label: '规则名称', minWidth: 150 },
        { prop: 'type', label: '类型', width: 100, type: 'tag' },
        { prop: 'target_app', label: '目标应用', minWidth: 150 },
        { prop: 'action', label: '动作', width: 100 },
        { prop: 'status', label: '状态', type: 'status', width: 100 },
      ],
      formFields: [
        { key: 'name', label: '规则名称' },
        { key: 'type', label: '类型', type: 'select', options: [{ label: '白名单', value: '白名单' }, { label: '黑名单', value: '黑名单' }] },
        { key: 'target_app', label: '目标应用' },
        { key: 'action', label: '动作', type: 'select', options: [{ label: '允许', value: '允许' }, { label: '阻止', value: '阻止' }, { label: '审计', value: '审计' }] },
        { key: 'status', label: '状态', type: 'select', options: [{ label: '启用', value: '启用' }, { label: '禁用', value: '禁用' }] },
      ],
      demoData: [
        { id: 1, name: '禁止游戏', type: '黑名单', target_app: 'game*.exe', action: '阻止', status: '启用' },
        { id: 2, name: '允许办公', type: '白名单', target_app: 'wps*,libreoffice*', action: '允许', status: '启用' },
        { id: 3, name: '审计下载', type: '黑名单', target_app: 'wget,curl,aria2c', action: '审计', status: '禁用' },
      ]
    }
    case 'AppControlCustom': return {
      addLabel: '新建自定义应用',
      statusOptions: [],
      columns: [
        { prop: 'name', label: '应用名称', minWidth: 150 },
        { prop: 'exec_path', label: '可执行路径', minWidth: 200 },
        { prop: 'category', label: '分类', width: 120 },
        { prop: 'hash', label: 'SHA256', minWidth: 200 },
        { prop: 'status', label: '状态', type: 'status', width: 100 },
      ],
      formFields: [
        { key: 'name', label: '应用名称' },
        { key: 'exec_path', label: '可执行路径' },
        { key: 'category', label: '分类', type: 'select', options: [{ label: '办公', value: '办公' }, { label: '开发', value: '开发' }, { label: '安全', value: '安全' }, { label: '其他', value: '其他' }] },
        { key: 'hash', label: 'SHA256哈希' },
      ],
      demoData: [
        { id: 1, name: '内部OA系统', exec_path: '/opt/oa-client/oa.bin', category: '办公', hash: 'a1b2c3d4...', status: '启用' },
        { id: 2, name: '自研监控工具', exec_path: '/usr/local/bin/monitor', category: '安全', hash: 'e5f6a7b8...', status: '启用' },
      ]
    }
    case 'VirtualAppGroups': return {
      addLabel: '新建应用组',
      statusOptions: [{ label: '运行中', value: '运行中' }, { label: '已停止', value: '已停止' }],
      columns: [
        { prop: 'name', label: '应用组名称', minWidth: 150 },
        { prop: 'app_count', label: '应用数量', width: 100 },
        { prop: 'user_count', label: '用户数', width: 100 },
        { prop: 'pool', label: '关联桌面池', minWidth: 150 },
        { prop: 'status', label: '状态', type: 'status', width: 100 },
      ],
      formFields: [
        { key: 'name', label: '组名称' },
        { key: 'pool', label: '关联桌面池' },
        { key: 'description', label: '描述', type: 'textarea' },
      ],
      demoData: [
        { id: 1, name: '办公应用组', app_count: 5, user_count: 120, pool: '通用桌面池', status: '运行中' },
        { id: 2, name: '开发应用组', app_count: 8, user_count: 30, pool: '开发桌面池', status: '运行中' },
        { id: 3, name: '测试应用组', app_count: 3, user_count: 10, pool: '测试桌面池', status: '已停止' },
      ]
    }
    case 'VirtualAppSessions': return {
      addLabel: '刷新',
      statusOptions: [{ label: '活跃', value: '活跃' }, { label: '空闲', value: '空闲' }, { label: '断开', value: '断开' }],
      columns: [
        { prop: 'user', label: '用户', minWidth: 120 },
        { prop: 'app_name', label: '应用', minWidth: 120 },
        { prop: 'app_group', label: '应用组', minWidth: 120 },
        { prop: 'client_ip', label: '客户端IP', width: 140 },
        { prop: 'start_time', label: '开始时间', width: 160 },
        { prop: 'duration', label: '时长', width: 100 },
        { prop: 'status', label: '状态', type: 'status', width: 100 },
      ],
      formFields: [],
      demoData: [
        { id: 1, user: 'zhangsan', app_name: 'WPS Writer', app_group: '办公应用组', client_ip: '192.168.1.101', start_time: '2025-01-19 08:30', duration: '2h15m', status: '活跃' },
        { id: 2, user: 'lisi', app_name: 'VS Code', app_group: '开发应用组', client_ip: '192.168.1.102', start_time: '2025-01-19 09:00', duration: '1h45m', status: '活跃' },
        { id: 3, user: 'wangwu', app_name: 'Firefox', app_group: '办公应用组', client_ip: '192.168.1.103', start_time: '2025-01-19 07:00', duration: '30m', status: '断开' },
      ]
    }
    default: return {
      addLabel: '新建',
      statusOptions: [],
      columns: [{ prop: 'name', label: '名称', minWidth: 200 }, { prop: 'status', label: '状态', type: 'status', width: 100 }],
      formFields: [{ key: 'name', label: '名称' }],
      demoData: []
    }
  }
})

const addLabel = computed(() => config.value.addLabel)
const statusOptions = computed(() => config.value.statusOptions)
const columns = computed(() => config.value.columns)
const formFields = computed(() => config.value.formFields)

const filteredData = computed(() => {
  let data = tableData.value
  if (search.value) {
    const q = search.value.toLowerCase()
    data = data.filter(r => Object.values(r).some(v => String(v).toLowerCase().includes(q)))
  }
  if (statusFilter.value) {
    data = data.filter(r => r.status === statusFilter.value)
  }
  return data
})

function editRow(row) {
  editingId.value = row.id
  Object.keys(form).forEach(k => delete form[k])
  Object.assign(form, { ...row })
  showDialog.value = true
}

async function deleteRow(row) {
  await ElMessageBox.confirm(`确定删除 "${row.name}" ?`, '确认')
  const path = getApiPath()
  if (path) {
    await api.delete(`${path}/${row.id}`)
  }
  ElMessage.success('删除成功'); load()
}

async function saveItem() {
  const path = getApiPath()
  if (path) {
    if (editingId.value) {
      await api.put(`${path}/${editingId.value}`, form)
    } else {
      await api.post(path, form)
    }
  }
  showDialog.value = false
  editingId.value = null
  ElMessage.success('保存成功'); load()
}

async function load() {
  loading.value = true
  editingId.value = null
  Object.keys(form).forEach(k => delete form[k])
  const url = getApiListUrl()
  if (url) {
    try { tableData.value = (await api.get(url)).data || [] }
    catch (e) { tableData.value = [] }
  } else {
    tableData.value = []
  }
  loading.value = false
}

watch(() => route.name, load)
onMounted(load)
</script>
