<template>
  <div>
    <div class="page-header">
      <h2>数据存储: {{ storageName }}</h2>
      <el-button @click="$router.push('/storage')">
        <el-icon><Back /></el-icon> 返回存储池
      </el-button>
    </div>

    <!-- 概览 -->
    <el-row :gutter="16" style="margin-bottom: 20px;">
      <el-col :span="6" v-for="card in overviewCards" :key="card.label">
        <el-card shadow="hover">
          <div style="text-align: center;">
            <div style="font-size: 28px; font-weight: bold;" :style="{ color: card.color || '#409EFF' }">{{ card.value }}</div>
            <div style="color: #909399; margin-top: 4px;">{{ card.label }}</div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 容量饼图 -->
    <el-card shadow="hover" style="margin-bottom: 20px;">
      <template #header><span>容量使用</span></template>
      <el-progress :percentage="usedPercent" :stroke-width="20" :color="usedPercent > 80 ? '#F56C6C' : '#409EFF'">
        <span>{{ usedPercent }}% 已使用 ({{ usedGB }}GB / {{ totalGB }}GB)</span>
      </el-progress>
    </el-card>

    <!-- 磁盘列表 -->
    <el-card shadow="hover">
      <template #header><span>磁盘卷</span></template>
      <el-table :data="volumes" border stripe>
        <el-table-column prop="name" label="磁盘名" min-width="200" />
        <el-table-column prop="format" label="格式" width="80" />
        <el-table-column prop="capacity" label="容量" width="100" />
        <el-table-column prop="allocation" label="已分配" width="100" />
        <el-table-column prop="vm" label="关联虚拟机" min-width="150" />
        <el-table-column label="操作" width="180">
          <template #default="{ row }">
            <el-button size="small" @click="editVol(row)">编辑</el-button>
            <el-button size="small" type="danger" :disabled="!!row.vm" @click="deleteVol(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { Back } from '@element-plus/icons-vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import api from '../api'

const route = useRoute()
const storageName = computed(() => pool.value?.name || route.params.name || 'default')
const loading = ref(false)
const pool = ref({})
const volumes = ref([])

const totalGB = computed(() => Math.round(pool.value?.total || 0))
const usedGB = computed(() => Math.round(pool.value?.used || 0))
const usedPercent = computed(() => totalGB.value ? Math.round(usedGB.value / totalGB.value * 100) : 0)

const overviewCards = computed(() => [
  { label: '总容量', value: totalGB.value + ' GB', color: '#409EFF' },
  { label: '已使用', value: usedGB.value + ' GB', color: '#E6A23C' },
  { label: '可用', value: (totalGB.value - usedGB.value) + ' GB', color: '#67C23A' },
  { label: '磁盘数', value: volumes.value.length, color: '#909399' },
])

async function load() {
  loading.value = true
  try {
    // Load pool detail by name (route param is name)
    const pools = (await api.get('/storage/pools')).data || []
    pool.value = pools.find(p => p.name === route.params.name || p.id === route.params.name) || {}
    if (pool.value.id) {
      volumes.value = (await api.get('/storage/volumes', { params: { pool_id: pool.value.id } })).data || []
    }
  } catch (e) { pool.value = {}; volumes.value = [] }
  finally { loading.value = false }
}

function editVol(row) { ElMessage.info('编辑: ' + row.name) }
async function deleteVol(row) {
  await ElMessageBox.confirm(`确定删除磁盘 "${row.name}" ?`, '确认')
  try {
    await api.delete(`/storage/volumes/${row.id}`)
    ElMessage.success('删除成功')
    load()
  } catch (e) { ElMessage.error('删除失败') }
}

onMounted(load)
</script>
