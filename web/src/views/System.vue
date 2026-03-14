<template>
  <div>
    <div class="page-header"><h2>系统设置</h2></div>
    <el-card shadow="hover">
      <el-table :data="configs" v-loading="loading" border stripe>
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
    </el-card>

    <el-card shadow="hover" style="margin-top: 16px;">
      <template #header><span style="font-weight: 600;">系统信息</span></template>
      <el-descriptions :column="2" border size="small">
        <el-descriptions-item label="平台名称">{{ info.name }}</el-descriptions-item>
        <el-descriptions-item label="版本">{{ info.version }}</el-descriptions-item>
        <el-descriptions-item label="运行模式">{{ info.mode }}</el-descriptions-item>
      </el-descriptions>
    </el-card>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import api from '../api'
import { ElMessage } from 'element-plus'

const loading = ref(false)
const configs = ref([]), info = ref({})
const editingKey = ref(''), editValue = ref('')

async function load() {
  loading.value = true
  try {
    configs.value = (await api.get('/system/config')).data
    info.value = await api.get('/info')
  } catch(e) {} finally { loading.value = false }
}

function startEdit(row) { editingKey.value = row.key; editValue.value = row.value }

async function saveConfig(row) {
  await api.put(`/system/config/${row.key}`, { value: editValue.value })
  ElMessage.success('已保存'); editingKey.value = ''; load()
}

onMounted(load)
</script>
