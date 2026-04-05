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
            <el-tag v-if="col.type === 'status'" :type="
              row[col.prop] === '运行中' || row[col.prop] === '启用' || row[col.prop] === '正常' ? 'success' :
              row[col.prop] === '告警' ? 'warning' :
              row[col.prop] === '停止' || row[col.prop] === '禁用' ? 'danger' : 'info'
            ">{{ row[col.prop] }}</el-tag>
            <el-progress v-else-if="col.type === 'progress'" :percentage="row[col.prop]" :stroke-width="10" />
            <span v-else>{{ row[col.prop] }}</span>
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

    <el-dialog v-model="showDialog" :title="editingId ? '编辑' : '新建'" width="550px">
      <el-form :model="form" label-width="140px">
        <el-form-item v-for="field in formFields" :key="field.key" :label="field.label">
          <el-switch v-if="field.type === 'switch'" v-model="form[field.key]" />
          <el-select v-else-if="field.type === 'select'" v-model="form[field.key]" style="width: 100%">
            <el-option v-for="o in field.options" :key="o.value" :label="o.label" :value="o.value" />
          </el-select>
          <el-input-number v-else-if="field.type === 'number'" v-model="form[field.key]" :min="field.min||0" :max="field.max||99999" />
          <el-slider v-else-if="field.type === 'slider'" v-model="form[field.key]" :min="field.min||0" :max="field.max||100" show-input />
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

const route = useRoute()
const loading = ref(false)
const search = ref('')
const statusFilter = ref('')
const showDialog = ref(false)
const editingId = ref(null)
const form = reactive({})
const tableData = ref([])

const config = computed(() => {
  switch (route.name) {
    case 'AutoScalingStrategy': return {
      addLabel: '新建策略',
      statusOptions: [{ label: '启用', value: '启用' }, { label: '禁用', value: '禁用' }],
      columns: [
        { prop: 'name', label: '策略名称', minWidth: 150 },
        { prop: 'metric', label: '指标', width: 120 },
        { prop: 'threshold', label: '阈值', width: 100 },
        { prop: 'scale_out', label: '扩容数', width: 80 },
        { prop: 'scale_in', label: '缩容数', width: 80 },
        { prop: 'cooldown', label: '冷却时间', width: 100 },
        { prop: 'status', label: '状态', type: 'status', width: 80 },
      ],
      formFields: [
        { key: 'name', label: '策略名称' },
        { key: 'metric', label: '监控指标', type: 'select', options: [{ label: 'CPU使用率', value: 'cpu' }, { label: '内存使用率', value: 'memory' }, { label: '连接数', value: 'connections' }, { label: '带宽', value: 'bandwidth' }] },
        { key: 'threshold', label: '触发阈值(%)', type: 'number', min: 1, max: 100 },
        { key: 'scale_out', label: '扩容数量', type: 'number', min: 1, max: 10 },
        { key: 'scale_in', label: '缩容数量', type: 'number', min: 1, max: 10 },
        { key: 'cooldown', label: '冷却时间(秒)', type: 'number', min: 60, max: 3600 },
        { key: 'status', label: '状态', type: 'select', options: [{ label: '启用', value: '启用' }, { label: '禁用', value: '禁用' }] },
      ],
      demoData: [
        { id: 1, name: '高负载自动扩容', metric: 'CPU使用率', threshold: '80%', scale_out: 2, scale_in: 1, cooldown: '300s', status: '启用' },
        { id: 2, name: '内存压力策略', metric: '内存使用率', threshold: '85%', scale_out: 1, scale_in: 1, cooldown: '600s', status: '禁用' },
      ]
    }
    case 'AutoScalingGroup': return {
      addLabel: '新建伸缩组',
      statusOptions: [{ label: '运行中', value: '运行中' }, { label: '停止', value: '停止' }],
      columns: [
        { prop: 'name', label: '伸缩组名称', minWidth: 150 },
        { prop: 'min_instances', label: '最小实例', width: 90 },
        { prop: 'max_instances', label: '最大实例', width: 90 },
        { prop: 'current', label: '当前实例', width: 90 },
        { prop: 'strategy', label: '关联策略', minWidth: 120 },
        { prop: 'template', label: '模板', minWidth: 120 },
        { prop: 'status', label: '状态', type: 'status', width: 80 },
      ],
      formFields: [
        { key: 'name', label: '伸缩组名称' },
        { key: 'min_instances', label: '最小实例数', type: 'number', min: 0, max: 100 },
        { key: 'max_instances', label: '最大实例数', type: 'number', min: 1, max: 100 },
        { key: 'strategy', label: '伸缩策略' },
        { key: 'template', label: '虚拟机模板' },
      ],
      demoData: [
        { id: 1, name: '桌面伸缩组', min_instances: 5, max_instances: 50, current: 12, strategy: '高负载自动扩容', template: 'desktop-tpl-01', status: '运行中' },
        { id: 2, name: '开发伸缩组', min_instances: 2, max_instances: 10, current: 3, strategy: '内存压力策略', template: 'dev-tpl-01', status: '运行中' },
      ]
    }
    case 'LoadBalance': return {
      addLabel: '新建负载均衡器',
      statusOptions: [{ label: '运行中', value: '运行中' }, { label: '停止', value: '停止' }],
      columns: [
        { prop: 'name', label: '名称', minWidth: 150 },
        { prop: 'vip', label: '虚拟IP', width: 140 },
        { prop: 'algorithm', label: '算法', width: 120 },
        { prop: 'port', label: '端口', width: 80 },
        { prop: 'backend_count', label: '后端数', width: 80 },
        { prop: 'health_check', label: '健康检查', width: 100 },
        { prop: 'status', label: '状态', type: 'status', width: 80 },
      ],
      formFields: [
        { key: 'name', label: '名称' },
        { key: 'vip', label: '虚拟IP', placeholder: '192.168.1.100' },
        { key: 'algorithm', label: '负载算法', type: 'select', options: [{ label: '轮询', value: '轮询' }, { label: '加权轮询', value: '加权轮询' }, { label: '最少连接', value: '最少连接' }, { label: '源IP哈希', value: '源IP哈希' }] },
        { key: 'port', label: '监听端口', type: 'number', min: 1, max: 65535 },
        { key: 'health_check', label: '健康检查', type: 'select', options: [{ label: 'TCP', value: 'TCP' }, { label: 'HTTP', value: 'HTTP' }, { label: '关闭', value: '关闭' }] },
      ],
      demoData: [
        { id: 1, name: 'desktop-lb', vip: '192.168.1.100', algorithm: '最少连接', port: 3389, backend_count: 5, health_check: 'TCP', status: '运行中' },
        { id: 2, name: 'web-lb', vip: '192.168.1.101', algorithm: '轮询', port: 443, backend_count: 3, health_check: 'HTTP', status: '运行中' },
      ]
    }
    case 'DRS': return {
      addLabel: '新建DRS规则',
      statusOptions: [{ label: '启用', value: '启用' }, { label: '禁用', value: '禁用' }],
      columns: [
        { prop: 'name', label: '规则名称', minWidth: 150 },
        { prop: 'mode', label: '模式', width: 100 },
        { prop: 'threshold', label: '迁移阈值', width: 100 },
        { prop: 'check_interval', label: '检查间隔', width: 100 },
        { prop: 'last_run', label: '上次执行', width: 160 },
        { prop: 'migrations', label: '迁移次数', width: 80 },
        { prop: 'status', label: '状态', type: 'status', width: 80 },
      ],
      formFields: [
        { key: 'name', label: '规则名称' },
        { key: 'mode', label: '模式', type: 'select', options: [{ label: '全自动', value: '全自动' }, { label: '半自动', value: '半自动' }, { label: '手动', value: '手动' }] },
        { key: 'threshold', label: '迁移阈值(%)', type: 'slider', min: 10, max: 95 },
        { key: 'check_interval', label: '检查间隔(分)', type: 'number', min: 1, max: 60 },
      ],
      demoData: [
        { id: 1, name: '默认DRS规则', mode: '全自动', threshold: '70%', check_interval: '5分钟', last_run: '2025-01-19 12:00', migrations: 23, status: '启用' },
      ]
    }
    case 'DPM': return {
      addLabel: '新建DPM策略',
      statusOptions: [{ label: '启用', value: '启用' }, { label: '禁用', value: '禁用' }],
      columns: [
        { prop: 'name', label: '策略名称', minWidth: 150 },
        { prop: 'mode', label: '模式', width: 100 },
        { prop: 'low_threshold', label: '低负载阈值', width: 100 },
        { prop: 'high_threshold', label: '高负载阈值', width: 100 },
        { prop: 'hosts_managed', label: '管理主机数', width: 100 },
        { prop: 'hosts_powered_off', label: '已关闭主机', width: 100 },
        { prop: 'status', label: '状态', type: 'status', width: 80 },
      ],
      formFields: [
        { key: 'name', label: '策略名称' },
        { key: 'mode', label: '模式', type: 'select', options: [{ label: '自动', value: '自动' }, { label: '手动', value: '手动' }] },
        { key: 'low_threshold', label: '低负载阈值(%)', type: 'slider', min: 5, max: 50 },
        { key: 'high_threshold', label: '高负载阈值(%)', type: 'slider', min: 50, max: 95 },
      ],
      demoData: [
        { id: 1, name: '节能策略', mode: '自动', low_threshold: '20%', high_threshold: '80%', hosts_managed: 8, hosts_powered_off: 2, status: '启用' },
      ]
    }
    default: return {
      addLabel: '新建', statusOptions: [],
      columns: [{ prop: 'name', label: '名称', minWidth: 200 }],
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
  if (statusFilter.value) data = data.filter(r => r.status === statusFilter.value)
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
  tableData.value = tableData.value.filter(r => r.id !== row.id)
  ElMessage.success('删除成功')
}

function saveItem() {
  if (editingId.value) {
    const idx = tableData.value.findIndex(r => r.id === editingId.value)
    if (idx >= 0) tableData.value[idx] = { ...form }
  } else {
    tableData.value.push({ ...form, id: Date.now(), status: '启用' })
  }
  showDialog.value = false
  editingId.value = null
  ElMessage.success('保存成功')
}

function load() {
  loading.value = true
  editingId.value = null
  Object.keys(form).forEach(k => delete form[k])
  tableData.value = [...(config.value.demoData || [])]
  loading.value = false
}

watch(() => route.name, load)
onMounted(load)
</script>
