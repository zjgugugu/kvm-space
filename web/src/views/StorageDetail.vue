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
import { ref, computed } from 'vue'
import { useRoute } from 'vue-router'
import { Back } from '@element-plus/icons-vue'
import { ElMessage, ElMessageBox } from 'element-plus'

const route = useRoute()
const storageName = computed(() => route.params.name || 'default')

const totalGB = 500
const usedGB = 312
const usedPercent = Math.round(usedGB / totalGB * 100)

const overviewCards = [
  { label: '总容量', value: totalGB + ' GB', color: '#409EFF' },
  { label: '已使用', value: usedGB + ' GB', color: '#E6A23C' },
  { label: '可用', value: (totalGB - usedGB) + ' GB', color: '#67C23A' },
  { label: '磁盘数', value: 5, color: '#909399' },
]

const volumes = ref([
  { name: 'vm-desktop-01.qcow2', format: 'qcow2', capacity: '40 GB', allocation: '18 GB', vm: 'desktop-01' },
  { name: 'vm-desktop-02.qcow2', format: 'qcow2', capacity: '40 GB', allocation: '22 GB', vm: 'desktop-02' },
  { name: 'vm-server-01.qcow2', format: 'qcow2', capacity: '100 GB', allocation: '65 GB', vm: 'server-01' },
  { name: 'template-kylin-v10.qcow2', format: 'qcow2', capacity: '20 GB', allocation: '12 GB', vm: '' },
  { name: 'backup-snapshot.qcow2', format: 'qcow2', capacity: '80 GB', allocation: '45 GB', vm: '' },
])

function editVol(row) { ElMessage.info('编辑: ' + row.name) }
async function deleteVol(row) {
  await ElMessageBox.confirm(`确定删除磁盘 "${row.name}" ?`, '确认')
  volumes.value = volumes.value.filter(v => v.name !== row.name)
  ElMessage.success('删除成功')
}
</script>
