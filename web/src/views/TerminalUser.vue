<template>
  <div>
    <div class="page-header">
      <h2>终端与用户关联</h2>
      <el-button type="primary" @click="showDialog = true">
        <el-icon><Plus /></el-icon> 新建关联
      </el-button>
    </div>

    <el-card shadow="hover">
      <div style="margin-bottom: 16px;">
        <el-input v-model="search" placeholder="搜索终端或用户..." clearable style="width: 300px">
          <template #prefix><el-icon><Search /></el-icon></template>
        </el-input>
      </div>
      <el-table :data="filteredData" border stripe>
        <el-table-column prop="terminal" label="终端名称" min-width="150" />
        <el-table-column prop="terminal_ip" label="终端IP" width="140" />
        <el-table-column prop="user" label="绑定用户" min-width="120" />
        <el-table-column prop="user_group" label="用户组" width="120" />
        <el-table-column prop="pool" label="桌面池" min-width="120" />
        <el-table-column prop="bind_type" label="绑定方式" width="100">
          <template #default="{ row }">
            <el-tag :type="row.bind_type === '固定' ? 'danger' : 'info'">{{ row.bind_type }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="status" label="状态" width="80">
          <template #default="{ row }">
            <el-tag :type="row.status === '在线' ? 'success' : 'info'">{{ row.status }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="160">
          <template #default="{ row }">
            <el-button size="small" @click="editRow(row)">编辑</el-button>
            <el-button size="small" type="danger" @click="deleteRow(row)">解绑</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <el-dialog v-model="showDialog" :title="editingId ? '编辑关联' : '新建关联'" width="450px">
      <el-form :model="form" label-width="100px">
        <el-form-item label="终端">
          <el-input v-model="form.terminal" />
        </el-form-item>
        <el-form-item label="终端IP">
          <el-input v-model="form.terminal_ip" placeholder="192.168.1.x" />
        </el-form-item>
        <el-form-item label="绑定用户">
          <el-input v-model="form.user" />
        </el-form-item>
        <el-form-item label="桌面池">
          <el-input v-model="form.pool" />
        </el-form-item>
        <el-form-item label="绑定方式">
          <el-select v-model="form.bind_type" style="width:100%">
            <el-option label="固定" value="固定" />
            <el-option label="浮动" value="浮动" />
          </el-select>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showDialog = false">取消</el-button>
        <el-button type="primary" @click="save">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, reactive, computed, onMounted } from 'vue'
import { Plus, Search } from '@element-plus/icons-vue'
import { ElMessage, ElMessageBox } from 'element-plus'

const search = ref('')
const showDialog = ref(false)
const editingId = ref(null)
const form = reactive({ terminal: '', terminal_ip: '', user: '', pool: '', bind_type: '浮动' })

const tableData = ref([
  { id: 1, terminal: 'TC-001', terminal_ip: '192.168.1.101', user: 'zhangsan', user_group: '办公组', pool: '通用桌面池', bind_type: '固定', status: '在线' },
  { id: 2, terminal: 'TC-002', terminal_ip: '192.168.1.102', user: 'lisi', user_group: '办公组', pool: '通用桌面池', bind_type: '浮动', status: '在线' },
  { id: 3, terminal: 'TC-003', terminal_ip: '192.168.1.103', user: 'wangwu', user_group: '开发组', pool: '开发桌面池', bind_type: '固定', status: '离线' },
  { id: 4, terminal: 'TC-004', terminal_ip: '192.168.1.104', user: 'zhaoliu', user_group: '测试组', pool: '测试桌面池', bind_type: '浮动', status: '离线' },
])

const filteredData = computed(() => {
  if (!search.value) return tableData.value
  const q = search.value.toLowerCase()
  return tableData.value.filter(r => r.terminal.toLowerCase().includes(q) || r.user.toLowerCase().includes(q) || r.terminal_ip.includes(q))
})

function editRow(row) {
  editingId.value = row.id
  Object.assign(form, row)
  showDialog.value = true
}

async function deleteRow(row) {
  await ElMessageBox.confirm(`确定解除 "${row.terminal}" 与 "${row.user}" 的绑定?`, '确认')
  tableData.value = tableData.value.filter(r => r.id !== row.id)
  ElMessage.success('已解绑')
}

function save() {
  if (editingId.value) {
    const idx = tableData.value.findIndex(r => r.id === editingId.value)
    if (idx >= 0) Object.assign(tableData.value[idx], form)
  } else {
    tableData.value.push({ ...form, id: Date.now(), user_group: '-', status: '离线' })
  }
  showDialog.value = false
  editingId.value = null
  ElMessage.success('保存成功')
}
</script>
