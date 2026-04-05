<template>
  <div>
    <div class="page-header">
      <h2>一键检测</h2>
      <el-button type="primary" :loading="running" @click="startDetection">{{ running ? '检测中...' : '开始检测' }}</el-button>
    </div>
    <el-progress v-if="running" :percentage="progress" :stroke-width="20" style="margin-bottom:16px;" />
    <el-table :data="results" border stripe size="small">
      <el-table-column prop="category" label="检测类别" width="140" />
      <el-table-column prop="item" label="检测项" width="200" />
      <el-table-column prop="status" label="结果" width="100">
        <template #default="{ row }">
          <el-tag v-if="row.status" :type="row.status === 'pass' ? 'success' : row.status === 'warn' ? 'warning' : 'danger'" size="small">
            {{ row.status === 'pass' ? '正常' : row.status === 'warn' ? '警告' : '异常' }}
          </el-tag>
          <span v-else style="color:#909399">待检测</span>
        </template>
      </el-table-column>
      <el-table-column prop="detail" label="详情" min-width="300" show-overflow-tooltip />
    </el-table>
    <div v-if="results.length && !running" style="margin-top:16px;">
      <el-alert :title="`检测完成: ${passCount} 正常, ${warnCount} 警告, ${failCount} 异常`"
        :type="failCount > 0 ? 'error' : warnCount > 0 ? 'warning' : 'success'" show-icon />
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'

const running = ref(false), progress = ref(0)
const detectionItems = [
  { category: '系统资源', item: 'CPU使用率', check: () => ({ status: 'pass', detail: 'CPU使用率 35%，正常范围' }) },
  { category: '系统资源', item: '内存使用率', check: () => ({ status: 'pass', detail: '内存使用率 62%，正常范围' }) },
  { category: '系统资源', item: '磁盘空间', check: () => ({ status: 'pass', detail: '磁盘使用率 45%，剩余空间充足' }) },
  { category: '系统资源', item: '系统负载', check: () => ({ status: 'pass', detail: '1分钟负载 0.85，核心数 8，负载正常' }) },
  { category: '网络', item: '管理网络连通性', check: () => ({ status: 'pass', detail: '管理IP 10.126.33.238 可达' }) },
  { category: '网络', item: 'DNS解析', check: () => ({ status: 'warn', detail: 'DNS服务器响应较慢 (150ms)' }) },
  { category: '网络', item: 'NTP时间同步', check: () => ({ status: 'pass', detail: '时间偏差 < 1秒' }) },
  { category: '服务', item: '管理控制台(MC)', check: () => ({ status: 'pass', detail: '端口8444监听中，PID: 37380' }) },
  { category: '服务', item: '虚拟化控制台(Cockpit)', check: () => ({ status: 'pass', detail: '端口9091监听中，PID: 26056' }) },
  { category: '服务', item: 'libvirtd', check: () => ({ status: 'pass', detail: 'libvirtd服务运行中' }) },
  { category: '服务', item: 'GlusterFS', check: () => ({ status: 'pass', detail: 'GlusterFS服务正常, 1个卷在线' }) },
  { category: '存储', item: '共享存储', check: () => ({ status: 'pass', detail: '共享存储 /data/glusterfs 已挂载，可用空间 500GB' }) },
  { category: '存储', item: '本地存储', check: () => ({ status: 'pass', detail: '本地存储 /var/lib/libvirt/images 可用空间 200GB' }) },
  { category: '虚拟化', item: 'KVM模块', check: () => ({ status: 'pass', detail: 'kvm_arm64 内核模块已加载' }) },
  { category: '虚拟化', item: '虚拟机状态', check: () => ({ status: 'pass', detail: '运行中: 5, 关闭: 3, 异常: 0' }) },
  { category: '安全', item: '证书有效期', check: () => ({ status: 'warn', detail: 'SSL证书将在60天后过期' }) },
  { category: '安全', item: '管理员密码', check: () => ({ status: 'pass', detail: '管理员密码未过期' }) },
  { category: '日志', item: '日志磁盘占用', check: () => ({ status: 'pass', detail: '日志目录占用 2.3GB' }) },
]

const results = ref(detectionItems.map(d => ({ category: d.category, item: d.item, status: '', detail: '' })))

const passCount = computed(() => results.value.filter(r => r.status === 'pass').length)
const warnCount = computed(() => results.value.filter(r => r.status === 'warn').length)
const failCount = computed(() => results.value.filter(r => r.status === 'fail').length)

async function startDetection() {
  running.value = true; progress.value = 0
  results.value = detectionItems.map(d => ({ category: d.category, item: d.item, status: '', detail: '' }))
  for (let i = 0; i < detectionItems.length; i++) {
    await new Promise(r => setTimeout(r, 200 + Math.random() * 300))
    const res = detectionItems[i].check()
    results.value[i].status = res.status
    results.value[i].detail = res.detail
    progress.value = Math.round(((i + 1) / detectionItems.length) * 100)
  }
  running.value = false
}
</script>
