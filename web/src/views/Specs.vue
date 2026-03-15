<template>
  <div>
    <div class="page-header">
      <h2>桌面规格</h2>
      <el-button type="primary" @click="showDialog()"><el-icon><Plus /></el-icon>创建规格</el-button>
    </div>
    <el-table :data="specs" v-loading="loading" border stripe>
      <el-table-column prop="name" label="名称" width="150" />
      <el-table-column label="CPU" width="110"><template #default="{ row }">{{ row.cpu }}核 (最大{{ row.max_cpu }})</template></el-table-column>
      <el-table-column label="内存" width="130"><template #default="{ row }">{{ (row.memory/1024).toFixed(0) }}GB (最大{{ (row.max_memory/1024).toFixed(0) }})</template></el-table-column>
      <el-table-column prop="system_disk" label="系统盘(GB)" width="95" />
      <el-table-column prop="user_disk" label="数据盘(GB)" width="95" />
      <el-table-column prop="protocol" label="协议" width="70" />
      <el-table-column prop="usb_mode" label="USB" width="70">
        <template #default="{ row }">{{ row.usb_mode === 'redirect' ? '重定向' : '本地' }}</template>
      </el-table-column>
      <el-table-column label="GPU" width="80"><template #default="{ row }">{{ row.gpu_type || '无' }}</template></el-table-column>
      <el-table-column prop="watermark" label="水印" width="60">
        <template #default="{ row }"><el-tag :type="row.watermark ? 'success' : 'info'" size="small">{{ row.watermark ? '开' : '关' }}</el-tag></template>
      </el-table-column>
      <el-table-column prop="description" label="描述" min-width="130" show-overflow-tooltip />
      <el-table-column label="操作" width="150" fixed="right">
        <template #default="{ row }">
          <el-button size="small" @click="showDialog(row)">编辑</el-button>
          <el-button size="small" type="danger" @click="del(row)">删除</el-button>
        </template>
      </el-table-column>
    </el-table>

    <el-dialog v-model="dialogVisible" :title="editing ? '编辑桌面规格' : '创建桌面规格'" width="650px">
      <el-tabs v-model="formTab">
        <el-tab-pane label="系统配置" name="system">
          <el-form :model="form" label-width="100px">
            <el-form-item label="规格名称" required><el-input v-model="form.name" /></el-form-item>
            <el-row :gutter="16">
              <el-col :span="12"><el-form-item label="CPU(核)"><el-input-number v-model="form.cpu" :min="1" :max="64" style="width: 100%;" /></el-form-item></el-col>
              <el-col :span="12"><el-form-item label="最大CPU"><el-input-number v-model="form.max_cpu" :min="1" :max="128" style="width: 100%;" /></el-form-item></el-col>
            </el-row>
            <el-row :gutter="16">
              <el-col :span="12"><el-form-item label="内存(MB)"><el-input-number v-model="form.memory" :min="512" :step="512" style="width: 100%;" /></el-form-item></el-col>
              <el-col :span="12"><el-form-item label="最大内存"><el-input-number v-model="form.max_memory" :min="512" :step="512" style="width: 100%;" /></el-form-item></el-col>
            </el-row>
          </el-form>
        </el-tab-pane>

        <el-tab-pane label="存储配置" name="storage">
          <el-form :model="form" label-width="100px">
            <el-row :gutter="16">
              <el-col :span="12"><el-form-item label="系统盘(GB)"><el-input-number v-model="form.system_disk" :min="10" style="width: 100%;" /></el-form-item></el-col>
              <el-col :span="12"><el-form-item label="数据盘(GB)"><el-input-number v-model="form.user_disk" :min="0" style="width: 100%;" /></el-form-item></el-col>
            </el-row>
            <el-form-item label="磁盘缓存">
              <el-select v-model="form.disk_cache" style="width: 100%;">
                <el-option label="无" value="none" /><el-option label="writeback" value="writeback" /><el-option label="writethrough" value="writethrough" />
              </el-select>
            </el-form-item>
          </el-form>
        </el-tab-pane>

        <el-tab-pane label="协议配置" name="protocol">
          <el-form :model="form" label-width="100px">
            <el-form-item label="桌面协议">
              <el-select v-model="form.protocol" style="width: 100%;">
                <el-option label="UDAP" value="UDAP" /><el-option label="SPICE" value="SPICE" /><el-option label="VNC" value="VNC" />
              </el-select>
            </el-form-item>
            <el-form-item label="水印"><el-switch v-model="form.watermark" /></el-form-item>
            <el-form-item label="剪切板"><el-switch v-model="form.clipboard" /></el-form-item>
            <el-form-item label="文件传输"><el-switch v-model="form.file_transfer" /></el-form-item>
          </el-form>
        </el-tab-pane>

        <el-tab-pane label="USB/外设" name="usb">
          <el-form :model="form" label-width="100px">
            <el-form-item label="USB模式">
              <el-select v-model="form.usb_mode" style="width: 100%;">
                <el-option label="本地模式" value="native" /><el-option label="重定向" value="redirect" /><el-option label="禁用" value="disabled" />
              </el-select>
            </el-form-item>
            <el-form-item label="串口"><el-switch v-model="form.serial_port" /></el-form-item>
            <el-form-item label="并口"><el-switch v-model="form.parallel_port" /></el-form-item>
          </el-form>
        </el-tab-pane>

        <el-tab-pane label="GPU/高级" name="advanced">
          <el-form :model="form" label-width="100px">
            <el-form-item label="GPU类型">
              <el-select v-model="form.gpu_type" style="width: 100%;" clearable placeholder="无GPU">
                <el-option label="vGPU" value="vGPU" /><el-option label="GPU直通" value="passthrough" />
              </el-select>
            </el-form-item>
            <el-form-item label="描述"><el-input v-model="form.description" type="textarea" :rows="3" /></el-form-item>
          </el-form>
        </el-tab-pane>
      </el-tabs>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="saving" @click="save">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import api from '../api'
import { ElMessage, ElMessageBox } from 'element-plus'

const loading = ref(false), saving = ref(false), dialogVisible = ref(false), editing = ref(null)
const specs = ref([])
const formTab = ref('system')
const defaultForm = { name: '', cpu: 2, max_cpu: 4, memory: 2048, max_memory: 4096, system_disk: 40, user_disk: 0, protocol: 'UDAP', usb_mode: 'native', description: '', gpu_type: '', disk_cache: 'none', watermark: false, clipboard: true, file_transfer: true, serial_port: false, parallel_port: false }
const form = reactive({ ...defaultForm })

async function load() { loading.value = true; try { specs.value = (await api.get('/specs')).data } finally { loading.value = false } }

function showDialog(s) {
  editing.value = s || null; formTab.value = 'system'
  if (s) Object.assign(form, { ...defaultForm, ...s })
  else Object.assign(form, { ...defaultForm })
  dialogVisible.value = true
}

async function save() {
  saving.value = true
  try {
    if (editing.value) await api.put(`/specs/${editing.value.id}`, form)
    else await api.post('/specs', form)
    ElMessage.success('保存成功'); dialogVisible.value = false; load()
  } finally { saving.value = false }
}

async function del(s) {
  await ElMessageBox.confirm(`确认删除规格 ${s.name}?`, '警告', { type: 'warning' })
  await api.delete(`/specs/${s.id}`); ElMessage.success('已删除'); load()
}

onMounted(load)
</script>
