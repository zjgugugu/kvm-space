<template>
  <div>
    <div class="page-header">
      <h2>虚拟交换机: {{ vswitchName }}</h2>
      <el-button @click="$router.push('/networks')">
        <el-icon><Back /></el-icon> 返回网络池
      </el-button>
    </div>

    <!-- 概览 -->
    <el-row :gutter="16" style="margin-bottom: 20px;">
      <el-col :span="6" v-for="card in overviewCards" :key="card.label">
        <el-card shadow="hover">
          <div style="text-align: center;">
            <div style="font-size: 28px; font-weight: bold; color: #409EFF;">{{ card.value }}</div>
            <div style="color: #909399; margin-top: 4px;">{{ card.label }}</div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- Tabs -->
    <el-tabs v-model="activeTab">
      <el-tab-pane label="端口组" name="ports">
        <el-table :data="portGroups" border stripe>
          <el-table-column prop="name" label="名称" min-width="150" />
          <el-table-column prop="vlan_id" label="VLAN ID" width="100" />
          <el-table-column prop="network_type" label="网络类型" width="120" />
          <el-table-column prop="vm_count" label="虚拟机数" width="100" />
          <el-table-column prop="mtu" label="MTU" width="80" />
        </el-table>
      </el-tab-pane>
      <el-tab-pane label="物理网卡" name="nics">
        <el-table :data="physicalNics" border stripe>
          <el-table-column prop="name" label="网卡名" width="120" />
          <el-table-column prop="mac" label="MAC地址" width="180" />
          <el-table-column prop="speed" label="速率" width="100" />
          <el-table-column prop="link_status" label="链路状态" width="100">
            <template #default="{ row }">
              <el-tag :type="row.link_status === 'up' ? 'success' : 'danger'">{{ row.link_status }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="driver" label="驱动" width="120" />
        </el-table>
      </el-tab-pane>
      <el-tab-pane label="配置" name="config">
        <el-form label-width="140px" style="max-width: 500px;">
          <el-form-item label="交换机名称">
            <el-input :model-value="vswitchName" disabled />
          </el-form-item>
          <el-form-item label="类型">
            <el-input model-value="Open vSwitch" disabled />
          </el-form-item>
          <el-form-item label="MTU">
            <el-input-number :model-value="1500" :min="68" :max="9000" />
          </el-form-item>
          <el-form-item label="STP">
            <el-switch :model-value="false" />
          </el-form-item>
          <el-form-item>
            <el-button type="primary">保存</el-button>
          </el-form-item>
        </el-form>
      </el-tab-pane>
    </el-tabs>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { Back } from '@element-plus/icons-vue'
import api from '../api'

const route = useRoute()
const vswitchName = computed(() => route.params.name || 'ovs-br0')
const activeTab = ref('ports')

const portGroups = ref([])
const physicalNics = ref([])

const overviewCards = computed(() => [
  { label: '端口组', value: portGroups.value.length },
  { label: '物理网卡', value: physicalNics.value.length },
  { label: '连接虚拟机', value: portGroups.value.reduce((s, p) => s + (p.vm_count || 0), 0) },
  { label: 'MTU', value: 1500 },
])

async function load() {
  try {
    const res = await api.get('/network-extra/port-groups')
    portGroups.value = (res.data || []).filter(p => !vswitchName.value || p.vswitch === vswitchName.value || true)
  } catch (e) { portGroups.value = [] }

  try {
    const nics = await api.get('/maintenance/system-info')
    // Physical NICs from network interfaces
    physicalNics.value = []
  } catch (e) {}
}

onMounted(load)
</script>
