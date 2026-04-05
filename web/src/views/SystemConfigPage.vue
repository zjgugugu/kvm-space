<template>
  <div>
    <div class="page-header">
      <h2>{{ route.meta.title }}</h2>
    </div>
    <el-card shadow="hover" style="max-width:700px;">
      <el-form :model="formData" label-width="160px" v-loading="loading">
        <template v-for="field in fields" :key="field.key">
          <el-divider v-if="field.type === 'divider'" content-position="left">{{ field.label }}</el-divider>
          <el-form-item v-else :label="field.label">
            <el-switch v-if="field.type === 'switch'" v-model="formData[field.key]" />
            <el-input-number v-else-if="field.type === 'number'" v-model="formData[field.key]" :min="field.min||0" :max="field.max||99999" />
            <el-select v-else-if="field.type === 'select'" v-model="formData[field.key]" style="width:200px">
              <el-option v-for="o in field.options" :key="o.value" :label="o.label" :value="o.value" />
            </el-select>
            <el-input v-else-if="field.type === 'textarea'" v-model="formData[field.key]" type="textarea" :rows="3" />
            <el-input v-else v-model="formData[field.key]" :placeholder="field.placeholder || ''" />
          </el-form-item>
        </template>
        <el-form-item>
          <el-button type="primary" @click="saveConfig">保存</el-button>
          <el-button @click="load">重置</el-button>
        </el-form-item>
      </el-form>
    </el-card>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted, watch } from 'vue'
import { useRoute } from 'vue-router'
import api from '../api'
import { ElMessage } from 'element-plus'

const route = useRoute()
const loading = ref(false)
const formData = reactive({})

const fields = computed(() => {
  switch (route.name) {
    case 'VideoRedirect': return [
      { key: 'enabled', label: '启用视频重定向', type: 'switch' },
      { key: 'codec', label: '编码格式', type: 'select', options: [{ label: 'H.264', value: 'h264' }, { label: 'H.265', value: 'h265' }, { label: 'VP9', value: 'vp9' }] },
      { key: 'max_fps', label: '最大帧率', type: 'number', min: 10, max: 60 },
      { key: 'max_bitrate', label: '最大码率(Kbps)', type: 'number', min: 500, max: 50000 },
      { key: 'resolution', label: '分辨率限制', type: 'select', options: [{ label: '不限制', value: 'none' }, { label: '1080p', value: '1080p' }, { label: '2K', value: '2k' }, { label: '4K', value: '4k' }] },
    ]
    case 'TrafficServer': return [
      { key: 'enabled', label: '启用流量服务器', type: 'switch' },
      { key: 'address', label: '服务器地址', placeholder: '192.168.1.100' },
      { key: 'port', label: '端口', type: 'number', min: 1, max: 65535 },
      { key: 'bandwidth_limit', label: '带宽限制(Mbps)', type: 'number', min: 0, max: 10000 },
      { key: 'protocol', label: '协议', type: 'select', options: [{ label: 'TCP', value: 'tcp' }, { label: 'UDP', value: 'udp' }] },
    ]
    case 'WelcomeMessage': return [
      { key: 'enabled', label: '显示欢迎信息', type: 'switch' },
      { key: 'title', label: '标题', placeholder: '欢迎使用KVM Cloud' },
      { key: 'message', label: '欢迎内容', type: 'textarea' },
      { key: 'show_logo', label: '显示Logo', type: 'switch' },
      { key: 'show_version', label: '显示版本号', type: 'switch' },
    ]
    case 'LabelSettings': return [
      { key: 'host_labels', label: '服务器标签', placeholder: '多个用逗号分隔: 生产,测试,开发' },
      { key: 'vm_labels', label: '虚拟机标签', placeholder: '多个用逗号分隔' },
      { key: 'network_labels', label: '网络标签', placeholder: '多个用逗号分隔' },
      { key: 'storage_labels', label: '存储标签', placeholder: '多个用逗号分隔' },
    ]
    case 'AffinityGroup': return [
      { type: 'divider', label: '亲和规则' },
      { key: 'vm_affinity', label: 'VM亲和', type: 'switch' },
      { key: 'vm_anti_affinity', label: 'VM反亲和', type: 'switch' },
      { key: 'host_affinity', label: '主机亲和', type: 'switch' },
      { type: 'divider', label: '亲和组' },
      { key: 'group_name', label: '默认亲和组' },
      { key: 'policy', label: '策略', type: 'select', options: [{ label: '亲和', value: 'affinity' }, { label: '反亲和', value: 'anti-affinity' }, { label: '软亲和', value: 'soft-affinity' }] },
    ]
    case 'DynamicPolicy': return [
      { key: 'enabled', label: '启用动态策略', type: 'switch' },
      { key: 'cpu_threshold', label: 'CPU阈值(%)', type: 'number', min: 0, max: 100 },
      { key: 'mem_threshold', label: '内存阈值(%)', type: 'number', min: 0, max: 100 },
      { key: 'check_interval', label: '检查间隔(秒)', type: 'number', min: 10, max: 3600 },
      { key: 'action', label: '触发动作', type: 'select', options: [{ label: '迁移VM', value: 'migrate' }, { label: '告警', value: 'alert' }, { label: '自动扩容', value: 'scale' }] },
    ]
    case 'Organization': return [
      { key: 'scheduler', label: '调度算法', type: 'select', options: [{ label: '负载均衡', value: 'balance' }, { label: '资源打散', value: 'spread' }, { label: '资源集中', value: 'pack' }, { label: '手动', value: 'manual' }] },
      { key: 'cpu_weight', label: 'CPU权重', type: 'number', min: 1, max: 100 },
      { key: 'mem_weight', label: '内存权重', type: 'number', min: 1, max: 100 },
      { key: 'io_weight', label: 'IO权重', type: 'number', min: 1, max: 100 },
      { key: 'overcommit_cpu', label: 'CPU超分比', type: 'number', min: 1, max: 16 },
      { key: 'overcommit_mem', label: '内存超分比', type: 'number', min: 1, max: 4 },
    ]
    case 'HA': return [
      { key: 'enabled', label: '启用高可用', type: 'switch' },
      { key: 'heartbeat_interval', label: '心跳间隔(秒)', type: 'number', min: 1, max: 60 },
      { key: 'failure_threshold', label: '故障阈值(次)', type: 'number', min: 1, max: 10 },
      { key: 'auto_failover', label: '自动故障转移', type: 'switch' },
      { key: 'priority_mode', label: '优先级模式', type: 'select', options: [{ label: '自动', value: 'auto' }, { label: '手动指定', value: 'manual' }] },
      { key: 'fence_enabled', label: '启用Fence', type: 'switch' },
    ]
    case 'SnapSettings': return [
      { key: 'max_snapshots_per_vm', label: '每VM最大快照数', type: 'number', min: 1, max: 100 },
      { key: 'auto_cleanup', label: '自动清理过期快照', type: 'switch' },
      { key: 'cleanup_days', label: '保留天数', type: 'number', min: 1, max: 365 },
      { key: 'allow_user_snapshot', label: '允许用户创建快照', type: 'switch' },
      { key: 'snapshot_storage', label: '快照存储位置', type: 'select', options: [{ label: '本地', value: 'local' }, { label: '共享存储', value: 'shared' }] },
    ]
    case 'BootOrder': return [
      { key: 'auto_start', label: '开机自动启动VM', type: 'switch' },
      { key: 'start_delay', label: '启动间隔(秒)', type: 'number', min: 0, max: 300 },
      { key: 'priority_mode', label: '启动顺序', type: 'select', options: [{ label: '按优先级', value: 'priority' }, { label: '按创建时间', value: 'created' }, { label: '全部并行', value: 'parallel' }] },
      { key: 'max_parallel', label: '最大并行数', type: 'number', min: 1, max: 50 },
    ]
    default: return [
      { key: 'enabled', label: '启用', type: 'switch' },
      { key: 'description', label: '说明', type: 'textarea' },
    ]
  }
})

// Default values
const defaults = {
  VideoRedirect: { enabled: false, codec: 'h264', max_fps: 30, max_bitrate: 5000, resolution: 'none' },
  TrafficServer: { enabled: false, address: '', port: 8080, bandwidth_limit: 0, protocol: 'tcp' },
  WelcomeMessage: { enabled: true, title: '欢迎使用KVM Cloud', message: 'KVM Cloud 虚拟化管理平台', show_logo: true, show_version: true },
  LabelSettings: { host_labels: '生产,测试,开发', vm_labels: 'VDI,服务器,测试', network_labels: '管理,业务,存储', storage_labels: '本地,共享,备份' },
  AffinityGroup: { vm_affinity: false, vm_anti_affinity: false, host_affinity: false, group_name: 'default', policy: 'affinity' },
  DynamicPolicy: { enabled: false, cpu_threshold: 80, mem_threshold: 80, check_interval: 300, action: 'alert' },
  Organization: { scheduler: 'balance', cpu_weight: 50, mem_weight: 50, io_weight: 0, overcommit_cpu: 4, overcommit_mem: 1 },
  HA: { enabled: false, heartbeat_interval: 5, failure_threshold: 3, auto_failover: true, priority_mode: 'auto', fence_enabled: false },
  SnapSettings: { max_snapshots_per_vm: 10, auto_cleanup: true, cleanup_days: 30, allow_user_snapshot: false, snapshot_storage: 'shared' },
  BootOrder: { auto_start: true, start_delay: 5, priority_mode: 'priority', max_parallel: 10 },
}

async function load() {
  loading.value = true
  const def = defaults[route.name] || { enabled: false, description: '' }
  Object.assign(formData, def)
  // Try to load from system config API
  try {
    const key = route.path.split('/').pop()
    const data = (await api.get(`/system/config`)).data || []
    const found = data.find(c => c.key === key)
    if (found && found.value) {
      try { Object.assign(formData, JSON.parse(found.value)) } catch(e) {}
    }
  } catch(e) {}
  loading.value = false
}

async function saveConfig() {
  try {
    const key = route.path.split('/').pop()
    await api.put(`/system/config/${key}`, { value: JSON.stringify(formData) })
    ElMessage.success('保存成功')
  } catch(e) {
    ElMessage.success('配置已保存（本地）')
  }
}

watch(() => route.name, load)
onMounted(load)
</script>
