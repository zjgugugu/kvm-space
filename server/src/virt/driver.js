// KVM虚拟化管理平台 - 虚拟化驱动统一接口（抽象基类）
// 三种模式: mock / readonly / full
// 仅包含与虚拟化后端相关的操作，纯 DB CRUD 见 services/data-service.js

class VirtDriver {
  constructor(mode) {
    this.mode = mode; // 'mock' | 'readonly' | 'full'
  }

  // ===== 宿主机管理 =====
  async listHosts() { throw new Error('Not implemented'); }
  async getHost(id) { throw new Error('Not implemented'); }
  async getHostVMs(id) { throw new Error('Not implemented'); }
  async addHost(config) { throw new Error('Not implemented'); }
  async removeHost(id) { throw new Error('Not implemented'); }
  async rebootHost(id) { throw new Error('Not implemented'); }
  async shutdownHost(id) { throw new Error('Not implemented'); }
  async updateHostConfig(id, config) { throw new Error('Not implemented'); }
  async getHostStats(id) { throw new Error('Not implemented'); }

  // ===== 虚拟机生命周期 =====
  async listVMs(includeDeleted) { throw new Error('Not implemented'); }
  async listDeletedVMs() { throw new Error('Not implemented'); }
  async getVM(id) { throw new Error('Not implemented'); }
  async createVM(config) { throw new Error('Not implemented'); }
  async editVM(id, config) { throw new Error('Not implemented'); }
  async deleteVM(id, permanent) { throw new Error('Not implemented'); }
  async restoreVM(id) { throw new Error('Not implemented'); }
  async startVM(id) { throw new Error('Not implemented'); }
  async stopVM(id) { throw new Error('Not implemented'); }
  async forceStopVM(id) { throw new Error('Not implemented'); }
  async rebootVM(id) { throw new Error('Not implemented'); }
  async forceRebootVM(id) { throw new Error('Not implemented'); }
  async suspendVM(id) { throw new Error('Not implemented'); }
  async resumeVM(id) { throw new Error('Not implemented'); }
  async restoreToTemplate(id) { throw new Error('Not implemented'); }
  async migrateVM(id, targetHostId) { throw new Error('Not implemented'); }
  async cloneVM(id, newName) { throw new Error('Not implemented'); }
  async getVMStats(id) { throw new Error('Not implemented'); }

  // ===== VM 热添加/移除硬件 =====
  async addDisk(vmId, config) { throw new Error('Not implemented'); }
  async addNic(vmId, config) { throw new Error('Not implemented'); }
  async removeDisk(vmId, diskId) { throw new Error('Not implemented'); }
  async removeNic(vmId, nicId) { throw new Error('Not implemented'); }

  // ===== 快照 =====
  async listSnapshots(vmId) { throw new Error('Not implemented'); }
  async createSnapshot(vmId, name, description) { throw new Error('Not implemented'); }
  async editSnapshot(vmId, snapId, updates) { throw new Error('Not implemented'); }
  async revertSnapshot(vmId, snapId) { throw new Error('Not implemented'); }
  async deleteSnapshot(vmId, snapId) { throw new Error('Not implemented'); }

  // ===== 模板/黄金镜像 =====
  async listTemplates() { throw new Error('Not implemented'); }
  async getTemplate(id) { throw new Error('Not implemented'); }
  async createTemplate(config) { throw new Error('Not implemented'); }
  async createTemplateFromVM(vmId, name) { throw new Error('Not implemented'); }
  async editTemplate(id, updates) { throw new Error('Not implemented'); }
  async publishTemplate(id) { throw new Error('Not implemented'); }
  async maintainTemplate(id) { throw new Error('Not implemented'); }
  async cloneTemplate(id, newName) { throw new Error('Not implemented'); }
  async deleteTemplate(id) { throw new Error('Not implemented'); }

  // ===== 存储池与卷 =====
  async listStoragePools() { throw new Error('Not implemented'); }
  async getStoragePool(id) { throw new Error('Not implemented'); }
  async createStoragePool(config) { throw new Error('Not implemented'); }
  async editStoragePool(id, updates) { throw new Error('Not implemented'); }
  async expandStoragePool(id, additionalSize) { throw new Error('Not implemented'); }
  async deleteStoragePool(id) { throw new Error('Not implemented'); }
  async listVolumes(poolId) { throw new Error('Not implemented'); }
  async createVolume(config) { throw new Error('Not implemented'); }
  async deleteVolume(id) { throw new Error('Not implemented'); }

  // ===== 网络/虚拟交换机 =====
  async listNetworks() { throw new Error('Not implemented'); }
  async getNetwork(id) { throw new Error('Not implemented'); }
  async createNetwork(config) { throw new Error('Not implemented'); }
  async editNetwork(id, updates) { throw new Error('Not implemented'); }
  async deleteNetwork(id) { throw new Error('Not implemented'); }

  // ===== 安全组（虚拟防火墙） =====
  async listSecurityGroups() { throw new Error('Not implemented'); }
  async getSecurityGroup(id) { throw new Error('Not implemented'); }
  async createSecurityGroup(config) { throw new Error('Not implemented'); }
  async updateSecurityGroup(id, updates) { throw new Error('Not implemented'); }
  async addSecurityRule(groupId, rule) { throw new Error('Not implemented'); }
  async deleteSecurityRule(ruleId) { throw new Error('Not implemented'); }
  async deleteSecurityGroup(id) { throw new Error('Not implemented'); }

  // ===== MAC 地址池 =====
  async listMacPools() { throw new Error('Not implemented'); }
  async createMacPool(config) { throw new Error('Not implemented'); }
  async updateMacPool(id, updates) { throw new Error('Not implemented'); }
  async deleteMacPool(id) { throw new Error('Not implemented'); }
}

module.exports = VirtDriver;
