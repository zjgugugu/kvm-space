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
import { ref, computed, onMounted } from 'vue'
import api from '../api'

const running = ref(false), progress = ref(0)
const results = ref([])

const passCount = computed(() => results.value.filter(r => r.status === 'pass').length)
const warnCount = computed(() => results.value.filter(r => r.status === 'warn').length)
const failCount = computed(() => results.value.filter(r => r.status === 'fail').length)

async function loadHistory() {
  try {
    const res = await api.get('/system-extra/detection')
    if (res.data && res.data.length) results.value = res.data
  } catch (e) { /* no history */ }
}

async function startDetection() {
  running.value = true; progress.value = 0
  results.value = []
  try {
    const res = await api.post('/system-extra/detection/run')
    results.value = res.data?.results || res.data?.items || res.data || []
    progress.value = 100
  } catch (e) {
    results.value = [{ category: '系统', item: '检测失败', status: 'fail', detail: e.message || '检测服务不可用' }]
  }
  running.value = false
}

onMounted(loadHistory)
</script>
