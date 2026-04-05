<template>
  <div>
    <div class="page-header">
      <h2>{{ title }}</h2>
      <div style="display:flex;gap:8px;">
        <el-input v-model="search" placeholder="搜索..." clearable style="width:180px" @clear="filterData" @keyup.enter="filterData">
          <template #prefix><el-icon><Search /></el-icon></template>
        </el-input>
        <el-button type="primary" @click="showDialog()"><el-icon><Plus /></el-icon>创建</el-button>
      </div>
    </div>
    <el-table :data="filtered" v-loading="loading" border stripe size="small">
      <el-table-column v-for="col in columns" :key="col.prop" :prop="col.prop" :label="col.label" :width="col.width" :show-overflow-tooltip="true">
        <template #default="{ row }" v-if="col.type === 'tag'">
          <el-tag :type="col.tagType?.(row[col.prop]) || 'info'" size="small">{{ col.format ? col.format(row[col.prop]) : row[col.prop] }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column label="操作" width="140" fixed="right">
        <template #default="{ row }">
          <el-button size="small" @click="showDialog(row)">编辑</el-button>
          <el-button size="small" type="danger" @click="remove(row)">删除</el-button>
        </template>
      </el-table-column>
    </el-table>

    <el-dialog v-model="dialogVisible" :title="editing ? `编辑${title}` : `创建${title}`" width="500px">
      <el-form :model="form" label-width="100px">
        <el-form-item v-for="f in formFields" :key="f.prop" :label="f.label" :required="f.required">
          <el-input v-if="!f.type || f.type === 'input'" v-model="form[f.prop]" :placeholder="f.placeholder" />
          <el-input v-else-if="f.type === 'textarea'" v-model="form[f.prop]" type="textarea" :rows="2" />
          <el-input-number v-else-if="f.type === 'number'" v-model="form[f.prop]" :min="f.min || 0" :max="f.max || 99999" />
          <el-select v-else-if="f.type === 'select'" v-model="form[f.prop]" style="width:100%">
            <el-option v-for="o in f.options" :key="o.value" :label="o.label" :value="o.value" />
          </el-select>
          <el-switch v-else-if="f.type === 'switch'" v-model="form[f.prop]" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="save">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch, reactive } from 'vue'
import { useRoute } from 'vue-router'
import api from '../api'
import { ElMessage, ElMessageBox } from 'element-plus'

const route = useRoute()
const loading = ref(false)
const items = ref([])
const search = ref('')
const dialogVisible = ref(false), editing = ref(null)
const form = reactive({})

const title = computed(() => route.meta.title || '')

// Config per route
const config = computed(() => {
  switch (route.name) {
    case 'PortGroups': return {
      api: '/networks', demo: [
        { id: 1, name: 'default-pg', vlan_id: 0, vswitch: 'vswitch0', type: '访问', vm_count: 5, description: '默认端口组' },
        { id: 2, name: 'storage-pg', vlan_id: 100, vswitch: 'vswitch0', type: '存储', vm_count: 3, description: '存储网络端口组' },
      ],
      columns: [
        { prop: 'name', label: '端口组名称', width: 150 },
        { prop: 'vlan_id', label: 'VLAN ID', width: 90 },
        { prop: 'vswitch', label: '虚拟交换机', width: 130 },
        { prop: 'type', label: '类型', width: 80, type: 'tag' },
        { prop: 'vm_count', label: '虚拟机数', width: 90 },
        { prop: 'description', label: '描述' },
      ],
      formFields: [
        { prop: 'name', label: '名称', required: true },
        { prop: 'vlan_id', label: 'VLAN ID', type: 'number', min: 0, max: 4094 },
        { prop: 'type', label: '类型', type: 'select', options: [{ label: '访问', value: '访问' }, { label: '存储', value: '存储' }, { label: '管理', value: '管理' }] },
        { prop: 'description', label: '描述', type: 'textarea' },
      ]
    }
    case 'Subnets': return {
      api: '/networks/subnets', demo: [
        { id: 1, name: 'mgmt-subnet', cidr: '10.126.33.0/24', gateway: '10.126.33.1', dns: '10.126.33.1', dhcp: true, used: 15 },
        { id: 2, name: 'storage-subnet', cidr: '192.168.100.0/24', gateway: '192.168.100.1', dns: '', dhcp: false, used: 3 },
      ],
      columns: [
        { prop: 'name', label: '子网名称', width: 140 },
        { prop: 'cidr', label: 'CIDR', width: 150 },
        { prop: 'gateway', label: '网关', width: 130 },
        { prop: 'dns', label: 'DNS', width: 130 },
        { prop: 'dhcp', label: 'DHCP', width: 80, type: 'tag', format: v => v ? '启用' : '禁用', tagType: v => v ? 'success' : 'info' },
        { prop: 'used', label: '已用IP', width: 80 },
      ],
      formFields: [
        { prop: 'name', label: '名称', required: true },
        { prop: 'cidr', label: 'CIDR', placeholder: '10.0.0.0/24' },
        { prop: 'gateway', label: '网关' },
        { prop: 'dns', label: 'DNS' },
        { prop: 'dhcp', label: 'DHCP', type: 'switch' },
      ]
    }
    case 'VlanPool': return {
      api: null, demo: [
        { id: 1, name: 'vlan-pool-1', range_start: 100, range_end: 200, used: 5, total: 101, description: '业务VLAN' },
        { id: 2, name: 'vlan-pool-2', range_start: 300, range_end: 400, used: 0, total: 101, description: '存储VLAN' },
      ],
      columns: [
        { prop: 'name', label: '名称', width: 150 },
        { prop: 'range_start', label: '起始VLAN', width: 100 },
        { prop: 'range_end', label: '结束VLAN', width: 100 },
        { prop: 'used', label: '已用', width: 70 },
        { prop: 'total', label: '总数', width: 70 },
        { prop: 'description', label: '描述' },
      ],
      formFields: [
        { prop: 'name', label: '名称', required: true },
        { prop: 'range_start', label: '起始VLAN', type: 'number', min: 1, max: 4094 },
        { prop: 'range_end', label: '结束VLAN', type: 'number', min: 1, max: 4094 },
        { prop: 'description', label: '描述', type: 'textarea' },
      ]
    }
    case 'PortMirroring': return {
      api: null, demo: [
        { id: 1, name: 'mirror-1', source: 'port-1', target: 'port-monitor', direction: '双向', status: '启用' },
      ],
      columns: [
        { prop: 'name', label: '名称', width: 150 },
        { prop: 'source', label: '源端口', width: 130 },
        { prop: 'target', label: '目标端口', width: 130 },
        { prop: 'direction', label: '方向', width: 80 },
        { prop: 'status', label: '状态', width: 80, type: 'tag', tagType: v => v === '启用' ? 'success' : 'info' },
      ],
      formFields: [
        { prop: 'name', label: '名称', required: true },
        { prop: 'source', label: '源端口' },
        { prop: 'target', label: '目标端口' },
        { prop: 'direction', label: '方向', type: 'select', options: [{ label: '入站', value: '入站' }, { label: '出站', value: '出站' }, { label: '双向', value: '双向' }] },
      ]
    }
    case 'NetworkConfigRules': return {
      api: null, demo: [
        { id: 1, name: 'default-qos', type: 'QoS', bandwidth: '100Mbps', priority: '高', target: '所有VM', enabled: true },
        { id: 2, name: 'rate-limit', type: '限速', bandwidth: '50Mbps', priority: '中', target: '普通用户', enabled: true },
      ],
      columns: [
        { prop: 'name', label: '规则名称', width: 150 },
        { prop: 'type', label: '类型', width: 80, type: 'tag' },
        { prop: 'bandwidth', label: '带宽', width: 100 },
        { prop: 'priority', label: '优先级', width: 80 },
        { prop: 'target', label: '应用对象', width: 120 },
        { prop: 'enabled', label: '状态', width: 80, type: 'tag', format: v => v ? '启用' : '禁用', tagType: v => v ? 'success' : 'info' },
      ],
      formFields: [
        { prop: 'name', label: '规则名称', required: true },
        { prop: 'type', label: '类型', type: 'select', options: [{ label: 'QoS', value: 'QoS' }, { label: '限速', value: '限速' }, { label: 'ACL', value: 'ACL' }] },
        { prop: 'bandwidth', label: '带宽' },
        { prop: 'priority', label: '优先级', type: 'select', options: [{ label: '高', value: '高' }, { label: '中', value: '中' }, { label: '低', value: '低' }] },
      ]
    }
    case 'VirtualFirewall': return {
      api: null, demo: [
        { id: 1, name: 'fw-default', status: '启用', rules: 5, type: '网络', zone: '内部', description: '默认防火墙' },
      ],
      columns: [
        { prop: 'name', label: '名称', width: 150 },
        { prop: 'status', label: '状态', width: 80, type: 'tag', tagType: v => v === '启用' ? 'success' : 'danger' },
        { prop: 'rules', label: '规则数', width: 80 },
        { prop: 'type', label: '类型', width: 80 },
        { prop: 'zone', label: '区域', width: 80 },
        { prop: 'description', label: '描述' },
      ],
      formFields: [
        { prop: 'name', label: '名称', required: true },
        { prop: 'type', label: '类型', type: 'select', options: [{ label: '网络', value: '网络' }, { label: '应用', value: '应用' }] },
        { prop: 'zone', label: '区域' },
        { prop: 'description', label: '描述', type: 'textarea' },
      ]
    }
    default: return {
      api: null, demo: [],
      columns: [{ prop: 'name', label: '名称', width: 200 }, { prop: 'description', label: '描述' }],
      formFields: [{ prop: 'name', label: '名称', required: true }, { prop: 'description', label: '描述', type: 'textarea' }]
    }
  }
})

const columns = computed(() => config.value.columns)
const formFields = computed(() => config.value.formFields)
const filtered = computed(() => {
  if (!search.value) return items.value
  const s = search.value.toLowerCase()
  return items.value.filter(i => Object.values(i).some(v => String(v).toLowerCase().includes(s)))
})

function filterData() {}

async function load() {
  loading.value = true
  try {
    if (config.value.api) {
      const res = await api.get(config.value.api)
      items.value = res.data || []
    } else {
      items.value = config.value.demo
    }
  } catch(e) { items.value = config.value.demo }
  finally { loading.value = false }
}

function showDialog(item) {
  editing.value = item || null
  const defaults = {}
  formFields.value.forEach(f => { defaults[f.prop] = item ? item[f.prop] || '' : (f.type === 'number' ? 0 : f.type === 'switch' ? false : '') })
  Object.assign(form, defaults)
  dialogVisible.value = true
}

async function save() {
  if (editing.value) {
    Object.assign(editing.value, form)
  } else {
    items.value.push({ id: Date.now(), ...form })
  }
  ElMessage.success('保存成功')
  dialogVisible.value = false
}

async function remove(item) {
  await ElMessageBox.confirm(`确认删除?`, '删除', { type: 'warning' })
  items.value = items.value.filter(i => i.id !== item.id)
  ElMessage.success('已删除')
}

watch(() => route.name, () => { items.value = []; load() })
onMounted(load)
</script>
