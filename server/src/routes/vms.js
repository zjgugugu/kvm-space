// 虚拟机完整管理 API
const express = require('express');
const router = express.Router();

// VM列表（支持筛选）
router.get('/', async (req, res) => {
  try {
    const vms = await req.app.locals.driver.listVMs();
    // 支持状态筛选
    let data = vms;
    if (req.query.status) data = data.filter(v => v.status === req.query.status);
    if (req.query.host_id) data = data.filter(v => v.host_id === req.query.host_id);
    if (req.query.owner) data = data.filter(v => v.owner === req.query.owner);
    if (req.query.search) {
      const s = req.query.search.toLowerCase();
      data = data.filter(v => v.name.toLowerCase().includes(s) || (v.ip && v.ip.includes(s)) || (v.owner && v.owner.toLowerCase().includes(s)));
    }
    res.json({ data, total: data.length });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 回收站列表
router.get('/recycle-bin', async (req, res) => {
  try {
    const vms = await req.app.locals.driver.listDeletedVMs();
    res.json({ data: vms, total: vms.length });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// VM详情（包含磁盘、网卡、安全组）
router.get('/:id', async (req, res) => {
  try {
    const vm = await req.app.locals.driver.getVM(req.params.id);
    if (!vm) return res.status(404).json({ error: '虚拟机不存在' });
    res.json(vm);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 创建VM
router.post('/', async (req, res) => {
  try {
    const vm = await req.app.locals.driver.createVM(req.body);
    res.status(201).json(vm);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// 编辑VM配置（CPU/内存支持热调整）
router.put('/:id', async (req, res) => {
  try {
    const vm = await req.app.locals.driver.editVM(req.params.id, req.body);
    res.json(vm);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// 删除VM（移入回收站）
router.delete('/:id', async (req, res) => {
  try {
    const permanent = req.query.permanent === 'true';
    const result = await req.app.locals.driver.deleteVM(req.params.id, permanent);
    res.json(result);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// 从回收站恢复VM
router.post('/:id/restore', async (req, res) => {
  try {
    const result = await req.app.locals.driver.restoreVM(req.params.id);
    res.json(result);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// VM操作: 开机/关机/强制关机/重启/强制重启/挂起/唤醒/系统还原
router.post('/:id/action', async (req, res) => {
  try {
    const { action } = req.body;
    const driver = req.app.locals.driver;
    const id = req.params.id;
    let result;
    switch (action) {
      case 'start': result = await driver.startVM(id); break;
      case 'stop': result = await driver.stopVM(id); break;
      case 'force_stop': result = await driver.forceStopVM(id); break;
      case 'reboot': result = await driver.rebootVM(id); break;
      case 'force_reboot': result = await driver.forceRebootVM(id); break;
      case 'suspend': result = await driver.suspendVM(id); break;
      case 'resume': result = await driver.resumeVM(id); break;
      case 'restore_template': result = await driver.restoreToTemplate(id); break;
      default: return res.status(400).json({ error: `未知操作: ${action}` });
    }
    res.json(result);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// 迁移
router.post('/:id/migrate', async (req, res) => {
  try {
    const result = await req.app.locals.driver.migrateVM(req.params.id, req.body.target_host);
    res.json(result);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// 克隆
router.post('/:id/clone', async (req, res) => {
  try {
    const vm = await req.app.locals.driver.cloneVM(req.params.id, req.body.name);
    res.status(201).json(vm);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// 实时性能监控
router.get('/:id/stats', async (req, res) => {
  try {
    const stats = await req.app.locals.driver.getVMStats(req.params.id);
    res.json(stats);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ===== 磁盘热操作 =====
router.post('/:id/disks', async (req, res) => {
  try {
    const disk = await req.app.locals.driver.addDisk(req.params.id, req.body);
    res.status(201).json(disk);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

router.delete('/:id/disks/:diskId', async (req, res) => {
  try {
    const result = await req.app.locals.driver.removeDisk(req.params.id, req.params.diskId);
    res.json(result);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// ===== 网卡热操作 =====
router.post('/:id/nics', async (req, res) => {
  try {
    const nic = await req.app.locals.driver.addNic(req.params.id, req.body);
    res.status(201).json(nic);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

router.delete('/:id/nics/:nicId', async (req, res) => {
  try {
    const result = await req.app.locals.driver.removeNic(req.params.id, req.params.nicId);
    res.json(result);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// ===== 快照管理 =====
router.get('/:id/snapshots', async (req, res) => {
  try {
    const snaps = await req.app.locals.driver.listSnapshots(req.params.id);
    res.json({ data: snaps, total: snaps.length });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/:id/snapshots', async (req, res) => {
  try {
    const snap = await req.app.locals.driver.createSnapshot(req.params.id, req.body.name, req.body.description);
    res.status(201).json(snap);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

router.put('/:id/snapshots/:snapId', async (req, res) => {
  try {
    const snap = await req.app.locals.driver.editSnapshot(req.params.id, req.params.snapId, req.body);
    res.json(snap);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

router.post('/:id/snapshots/:snapId/revert', async (req, res) => {
  try {
    const result = await req.app.locals.driver.revertSnapshot(req.params.id, req.params.snapId);
    res.json(result);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

router.delete('/:id/snapshots/:snapId', async (req, res) => {
  try {
    const result = await req.app.locals.driver.deleteSnapshot(req.params.id, req.params.snapId);
    res.json(result);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// 从VM提取模板
router.post('/:id/template', async (req, res) => {
  try {
    const tpl = await req.app.locals.driver.createTemplateFromVM(req.params.id, req.body.name);
    res.status(201).json(tpl);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

module.exports = router;
