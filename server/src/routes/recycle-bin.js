const express = require('express');
const router = express.Router();
const { v4: uuidv4 } = require('uuid');

// GET /api/recycle-bin — 回收站列表
router.get('/', (req, res) => {
  const db = req.app.locals.db;
  const { type } = req.query; // vm, template, network
  let sql = 'SELECT * FROM recycle_bin WHERE 1=1';
  const params = [];
  if (type) { sql += ' AND resource_type = ?'; params.push(type); }
  sql += ' ORDER BY created_at DESC';
  // Also include soft-deleted VMs
  const recycled = db.prepare(sql).all(...params);
  if (!type || type === 'vm') {
    const deletedVMs = db.prepare('SELECT id, name, owner, host_id, cpu, memory, disk, deleted_at as created_at FROM vms WHERE deleted = 1 ORDER BY deleted_at DESC').all();
    for (const vm of deletedVMs) {
      recycled.push({
        id: 'vm-' + vm.id,
        resource_type: 'vm_deleted',
        resource_id: vm.id,
        resource_name: vm.name,
        deleted_by: vm.owner || 'admin',
        original_data: JSON.stringify(vm),
        created_at: vm.created_at
      });
    }
  }
  res.json({ data: recycled, total: recycled.length });
});

// POST /api/recycle-bin/:id/restore — 恢复
router.post('/:id/restore', (req, res) => {
  const db = req.app.locals.db;
  // Check if it's a soft-deleted VM
  if (req.params.id.startsWith('vm-')) {
    const vmId = req.params.id.replace('vm-', '');
    db.prepare('UPDATE vms SET deleted = 0, deleted_at = NULL WHERE id = ?').run(vmId);
    return res.json({ message: '虚拟机已恢复' });
  }
  const item = db.prepare('SELECT * FROM recycle_bin WHERE id = ?').get(req.params.id);
  if (!item) return res.status(404).json({ error: '回收站项目不存在' });
  db.prepare('DELETE FROM recycle_bin WHERE id = ?').run(req.params.id);
  res.json({ message: '已恢复', resource_type: item.resource_type, resource_id: item.resource_id });
});

// DELETE /api/recycle-bin/:id — 永久删除
router.delete('/:id', (req, res) => {
  const db = req.app.locals.db;
  if (req.params.id.startsWith('vm-')) {
    const vmId = req.params.id.replace('vm-', '');
    db.prepare('DELETE FROM vm_disks WHERE vm_id = ?').run(vmId);
    db.prepare('DELETE FROM vm_nics WHERE vm_id = ?').run(vmId);
    db.prepare('DELETE FROM snapshots WHERE vm_id = ?').run(vmId);
    db.prepare('DELETE FROM vms WHERE id = ?').run(vmId);
    return res.json({ message: '虚拟机已永久删除' });
  }
  db.prepare('DELETE FROM recycle_bin WHERE id = ?').run(req.params.id);
  res.json({ message: '已永久删除' });
});

// POST /api/recycle-bin/empty — 清空回收站
router.post('/empty', (req, res) => {
  const db = req.app.locals.db;
  const { type } = req.body;
  if (type === 'vm' || !type) {
    const deleted = db.prepare('SELECT id FROM vms WHERE deleted = 1').all();
    for (const vm of deleted) {
      db.prepare('DELETE FROM vm_disks WHERE vm_id = ?').run(vm.id);
      db.prepare('DELETE FROM vm_nics WHERE vm_id = ?').run(vm.id);
      db.prepare('DELETE FROM snapshots WHERE vm_id = ?').run(vm.id);
    }
    db.prepare('DELETE FROM vms WHERE deleted = 1').run();
  }
  if (type) {
    db.prepare('DELETE FROM recycle_bin WHERE resource_type = ?').run(type);
  } else {
    db.prepare('DELETE FROM recycle_bin').run();
  }
  res.json({ message: '回收站已清空' });
});

module.exports = router;
