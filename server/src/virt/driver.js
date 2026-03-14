// KVM虚拟化管理平台 - 虚拟化驱动统一接口
// 三种模式: mock / readonly / full

class VirtDriver {
  constructor(mode) {
    this.mode = mode; // 'mock' | 'readonly' | 'full'
  }

  // ===== 宿主机 =====
  async getHostInfo() { throw new Error('Not implemented'); }
  async listHosts() { throw new Error('Not implemented'); }

  // ===== 虚拟机 =====
  async listVMs() { throw new Error('Not implemented'); }
  async getVM(id) { throw new Error('Not implemented'); }
  async createVM(config) { throw new Error('Not implemented'); }
  async deleteVM(id) { throw new Error('Not implemented'); }
  async startVM(id) { throw new Error('Not implemented'); }
  async stopVM(id) { throw new Error('Not implemented'); }
  async forceStopVM(id) { throw new Error('Not implemented'); }
  async rebootVM(id) { throw new Error('Not implemented'); }
  async suspendVM(id) { throw new Error('Not implemented'); }
  async resumeVM(id) { throw new Error('Not implemented'); }
  async migrateVM(id, targetHost) { throw new Error('Not implemented'); }
  async cloneVM(id, newName) { throw new Error('Not implemented'); }
  async getVMStats(id) { throw new Error('Not implemented'); }

  // ===== 快照 =====
  async listSnapshots(vmId) { throw new Error('Not implemented'); }
  async createSnapshot(vmId, name) { throw new Error('Not implemented'); }
  async revertSnapshot(vmId, snapId) { throw new Error('Not implemented'); }
  async deleteSnapshot(vmId, snapId) { throw new Error('Not implemented'); }

  // ===== 存储 =====
  async listStoragePools() { throw new Error('Not implemented'); }
  async getStoragePool(name) { throw new Error('Not implemented'); }
  async listVolumes(pool) { throw new Error('Not implemented'); }

  // ===== 网络 =====
  async listNetworks() { throw new Error('Not implemented'); }
  async getNetwork(name) { throw new Error('Not implemented'); }

  // ===== 模板/镜像 =====
  async listTemplates() { throw new Error('Not implemented'); }
  async getTemplate(id) { throw new Error('Not implemented'); }
  async createTemplate(vmId, name) { throw new Error('Not implemented'); }
}

module.exports = VirtDriver;
