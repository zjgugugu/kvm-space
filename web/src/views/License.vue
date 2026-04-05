<template>
  <div>
    <div class="page-header">
      <h2>授权许可</h2>
    </div>
    <el-row :gutter="16">
      <el-col :span="12">
        <el-card shadow="hover">
          <template #header><span style="font-weight:bold;">许可证信息</span></template>
          <el-descriptions :column="1" border size="default">
            <el-descriptions-item label="产品名称">麒麟信安云 V7R023</el-descriptions-item>
            <el-descriptions-item label="许可类型"><el-tag>{{ license.type || '开发版' }}</el-tag></el-descriptions-item>
            <el-descriptions-item label="授权单位">{{ license.org || '开发/测试' }}</el-descriptions-item>
            <el-descriptions-item label="有效期至">
              <el-tag :type="isExpired ? 'danger' : 'success'">{{ license.expire_date || '永久有效' }}</el-tag>
            </el-descriptions-item>
            <el-descriptions-item label="授权状态">
              <el-tag :type="license.status === 'active' ? 'success' : 'danger'">{{ license.status === 'active' ? '已激活' : '未激活' }}</el-tag>
            </el-descriptions-item>
          </el-descriptions>
        </el-card>
      </el-col>
      <el-col :span="12">
        <el-card shadow="hover">
          <template #header><span style="font-weight:bold;">资源配额</span></template>
          <el-descriptions :column="1" border size="default">
            <el-descriptions-item label="最大服务器数">
              <span>{{ license.used_hosts || 1 }} / {{ license.max_hosts || '无限制' }}</span>
            </el-descriptions-item>
            <el-descriptions-item label="最大虚拟机数">
              <span>{{ license.used_vms || 8 }} / {{ license.max_vms || '无限制' }}</span>
            </el-descriptions-item>
            <el-descriptions-item label="最大用户数">
              <span>{{ license.used_users || 3 }} / {{ license.max_users || '无限制' }}</span>
            </el-descriptions-item>
            <el-descriptions-item label="最大终端数">
              <span>{{ license.used_clients || 0 }} / {{ license.max_clients || '无限制' }}</span>
            </el-descriptions-item>
          </el-descriptions>
        </el-card>
      </el-col>
    </el-row>
    <el-card shadow="hover" style="margin-top:16px;">
      <template #header><span style="font-weight:bold;">激活许可证</span></template>
      <el-form :inline="true">
        <el-form-item label="许可证密钥">
          <el-input v-model="licenseKey" placeholder="请输入许可证密钥" style="width:400px" />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="activate">激活</el-button>
        </el-form-item>
        <el-form-item>
          <el-upload action="#" :before-upload="handleUpload" :show-file-list="false" accept=".lic,.key">
            <el-button>导入许可文件</el-button>
          </el-upload>
        </el-form-item>
      </el-form>
    </el-card>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted } from 'vue'
import api from '../api'
import { ElMessage } from 'element-plus'

const license = reactive({ type: '开发版', org: '开发/测试', expire_date: '永久有效', status: 'active', max_hosts: '无限制', max_vms: '无限制', max_users: '无限制', max_clients: '无限制', used_hosts: 1, used_vms: 8, used_users: 3, used_clients: 0 })
const licenseKey = ref('')
const isExpired = computed(() => false)

async function load() {
  try {
    const info = await api.get('/info')
    if (info.license) Object.assign(license, info.license)
  } catch(e) {}
}

function activate() {
  if (!licenseKey.value) return ElMessage.warning('请输入许可证密钥')
  ElMessage.success('许可证已激活（模拟）')
}

function handleUpload(file) {
  ElMessage.success(`已导入许可文件 ${file.name}（模拟）`)
  return false
}

onMounted(load)
</script>
