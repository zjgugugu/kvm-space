<template>
  <div>
    <div class="page-header">
      <h2>文件管理</h2>
      <div>
        <el-button type="primary" @click="showUpload = true">
          <el-icon><Upload /></el-icon> 上传文件
        </el-button>
        <el-button @click="createFolder">
          <el-icon><FolderAdd /></el-icon> 新建文件夹
        </el-button>
      </div>
    </div>

    <!-- 面包屑导航 -->
    <el-breadcrumb separator="/" style="margin-bottom: 16px;">
      <el-breadcrumb-item v-for="(seg, i) in pathSegments" :key="i">
        <a href="#" @click.prevent="navigateTo(i)">{{ seg || '根目录' }}</a>
      </el-breadcrumb-item>
    </el-breadcrumb>

    <el-card shadow="hover">
      <el-table :data="currentFiles" border stripe @row-dblclick="openItem">
        <el-table-column width="50">
          <template #default="{ row }">
            <el-icon :size="20" :color="row.type === 'folder' ? '#E6A23C' : '#909399'">
              <Folder v-if="row.type === 'folder'" />
              <Document v-else />
            </el-icon>
          </template>
        </el-table-column>
        <el-table-column prop="name" label="名称" min-width="250">
          <template #default="{ row }">
            <a href="#" @click.prevent="openItem(row)" style="color: #409EFF; text-decoration: none;">{{ row.name }}</a>
          </template>
        </el-table-column>
        <el-table-column prop="size" label="大小" width="120" />
        <el-table-column prop="modified" label="修改时间" width="180" />
        <el-table-column prop="owner" label="所有者" width="100" />
        <el-table-column label="操作" width="200">
          <template #default="{ row }">
            <el-button v-if="row.type !== 'folder'" size="small" @click="downloadFile(row)">下载</el-button>
            <el-button size="small" @click="renameItem(row)">重命名</el-button>
            <el-button size="small" type="danger" @click="deleteItem(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- Upload Dialog -->
    <el-dialog v-model="showUpload" title="上传文件" width="450px">
      <el-upload drag action="#" :auto-upload="false" multiple>
        <el-icon :size="40" style="color: #C0C4CC;"><Upload /></el-icon>
        <div>将文件拖到此处或 <em>点击上传</em></div>
      </el-upload>
      <template #footer>
        <el-button @click="showUpload = false">取消</el-button>
        <el-button type="primary" @click="showUpload = false; $message.success('上传成功')">上传</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { Folder, Document, Upload, FolderAdd } from '@element-plus/icons-vue'
import api from '../api'
import { ElMessage, ElMessageBox } from 'element-plus'

const showUpload = ref(false)
const currentCategory = ref('')
const files = ref([])
const loading = ref(false)

const currentFiles = computed(() => {
  if (!currentCategory.value) return files.value
  return files.value.filter(f => f.category === currentCategory.value || f.type === currentCategory.value)
})

const pathSegments = computed(() => {
  const segs = ['根目录']
  if (currentCategory.value) segs.push(currentCategory.value)
  return segs
})

async function load() {
  loading.value = true
  try {
    const params = currentCategory.value ? { category: currentCategory.value } : {}
    files.value = (await api.get('/files', { params })).data || []
  } catch (e) { files.value = [] }
  finally { loading.value = false }
}

function openItem(row) {
  if (row.type === 'folder' || row.category) {
    currentCategory.value = row.name || row.category
    load()
  }
}

function navigateTo(idx) {
  if (idx === 0) { currentCategory.value = ''; load() }
}

function downloadFile(row) { ElMessage.info('下载: ' + row.name) }

async function renameItem(row) {
  const { value } = await ElMessageBox.prompt('新名称:', '重命名', { inputValue: row.name })
  if (value) {
    try {
      await api.put(`/files/${row.id}`, { name: value })
      ElMessage.success('重命名成功'); load()
    } catch (e) { ElMessage.error('重命名失败') }
  }
}

async function deleteItem(row) {
  await ElMessageBox.confirm(`确定删除 "${row.name}" ?`, '确认')
  await api.delete(`/files/${row.id}`)
  ElMessage.success('删除成功'); load()
}

async function createFolder() {
  const { value } = await ElMessageBox.prompt('文件夹名称:', '新建文件夹')
  if (value) {
    await api.post('/files', { name: value, type: 'folder', category: currentCategory.value || 'general' })
    ElMessage.success('创建成功'); load()
  }
}

onMounted(load)
</script>
