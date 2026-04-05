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
import { ref, computed } from 'vue'
import { Folder, Document, Upload, FolderAdd } from '@element-plus/icons-vue'
import { ElMessage, ElMessageBox } from 'element-plus'

const showUpload = ref(false)
const currentPath = ref('')

const pathSegments = computed(() => {
  const segs = ['']
  if (currentPath.value) segs.push(...currentPath.value.split('/').filter(Boolean))
  return segs
})

const fileTree = {
  '': [
    { name: 'iso', type: 'folder', size: '-', modified: '2025-01-10 08:00', owner: 'root' },
    { name: 'templates', type: 'folder', size: '-', modified: '2025-01-12 10:00', owner: 'root' },
    { name: 'backups', type: 'folder', size: '-', modified: '2025-01-18 14:00', owner: 'root' },
    { name: 'logs', type: 'folder', size: '-', modified: '2025-01-19 09:00', owner: 'root' },
    { name: 'README.txt', type: 'file', size: '2.4 KB', modified: '2025-01-05 12:00', owner: 'admin' },
  ],
  'iso': [
    { name: 'KylinOS-V10-SP3.iso', type: 'file', size: '4.2 GB', modified: '2025-01-08 10:00', owner: 'root' },
    { name: 'UOS-20-desktop.iso', type: 'file', size: '3.8 GB', modified: '2025-01-09 14:00', owner: 'root' },
    { name: 'CentOS-7.9.iso', type: 'file', size: '4.4 GB', modified: '2025-01-07 09:00', owner: 'root' },
  ],
  'templates': [
    { name: 'desktop-kylin.qcow2', type: 'file', size: '8.5 GB', modified: '2025-01-12 10:30', owner: 'root' },
    { name: 'server-centos.qcow2', type: 'file', size: '12.0 GB', modified: '2025-01-11 16:00', owner: 'root' },
  ],
  'backups': [
    { name: 'full-backup-20250118.tar.gz', type: 'file', size: '25.6 GB', modified: '2025-01-18 14:30', owner: 'root' },
  ],
  'logs': [
    { name: 'mc-server.log', type: 'file', size: '15.2 MB', modified: '2025-01-19 09:30', owner: 'root' },
    { name: 'libvirtd.log', type: 'file', size: '8.7 MB', modified: '2025-01-19 09:00', owner: 'root' },
  ],
}

const currentFiles = computed(() => fileTree[currentPath.value] || [])

function openItem(row) {
  if (row.type === 'folder') {
    currentPath.value = currentPath.value ? currentPath.value + '/' + row.name : row.name
  }
}

function navigateTo(idx) {
  if (idx === 0) currentPath.value = ''
  else currentPath.value = pathSegments.value.slice(1, idx + 1).join('/')
}

function downloadFile(row) { ElMessage.info('下载: ' + row.name) }

async function renameItem(row) {
  const { value } = await ElMessageBox.prompt('新名称:', '重命名', { inputValue: row.name })
  if (value) { row.name = value; ElMessage.success('重命名成功') }
}

async function deleteItem(row) {
  await ElMessageBox.confirm(`确定删除 "${row.name}" ?`, '确认')
  const list = fileTree[currentPath.value]
  if (list) {
    const idx = list.indexOf(row)
    if (idx >= 0) list.splice(idx, 1)
  }
  ElMessage.success('删除成功')
}

async function createFolder() {
  const { value } = await ElMessageBox.prompt('文件夹名称:', '新建文件夹')
  if (value) {
    const list = fileTree[currentPath.value]
    if (list) list.unshift({ name: value, type: 'folder', size: '-', modified: new Date().toLocaleString(), owner: 'admin' })
    ElMessage.success('创建成功')
  }
}
</script>
