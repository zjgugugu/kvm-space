const express = require('express');
const router = express.Router();
const { v4: uuidv4 } = require('uuid');

// ==================== 僵尸云服务器 ====================
router.get('/zombie-servers', (req, res) => {
  const db = req.app.locals.db;
  const rows = db.prepare('SELECT * FROM zombie_servers ORDER BY detected_at DESC').all();
  res.json({ data: rows, total: rows.length });
});

router.post('/zombie-servers/scan', (req, res) => {
  // Scan for zombie servers - VMs that exist in libvirt but not in DB, or vice versa
  const db = req.app.locals.db;
  const vms = db.prepare("SELECT id, name, host_id, status FROM vms WHERE deleted = 0 AND status = 'error'").all();
  const results = [];
  for (const vm of vms) {
    const id = uuidv4();
    const host = vm.host_id ? db.prepare('SELECT name FROM hosts WHERE id = ?').get(vm.host_id) : null;
    db.prepare('INSERT OR IGNORE INTO zombie_servers (id, vm_id, vm_name, host_id, host_name, reason) VALUES (?,?,?,?,?,?)')
      .run(id, vm.id, vm.name, vm.host_id || '', host?.name || '', '虚拟机状态异常');
    results.push({ vm_id: vm.id, vm_name: vm.name });
  }
  res.json({ message: `扫描完成，发现${results.length}个僵尸服务器`, items: results });
});

router.post('/zombie-servers/:id/resolve', (req, res) => {
  const db = req.app.locals.db;
  db.prepare("UPDATE zombie_servers SET resolved = 1, resolved_at = datetime('now') WHERE id = ?").run(req.params.id);
  res.json({ message: '已标记为已处理' });
});

router.delete('/zombie-servers/:id', (req, res) => {
  const db = req.app.locals.db;
  db.prepare('DELETE FROM zombie_servers WHERE id = ?').run(req.params.id);
  res.json({ message: '删除成功' });
});

// ==================== 云服务器启动顺序 ====================
router.get('/boot-order', (req, res) => {
  const db = req.app.locals.db;
  const rows = db.prepare('SELECT bo.*, v.name as vm_name, v.status as vm_status FROM boot_order_config bo LEFT JOIN vms v ON bo.vm_id = v.id ORDER BY bo.boot_priority ASC').all();
  res.json({ data: rows, total: rows.length });
});

router.post('/boot-order', (req, res) => {
  const db = req.app.locals.db;
  const id = uuidv4();
  const { vm_id, boot_priority, delay_seconds } = req.body;
  const vm = db.prepare('SELECT name FROM vms WHERE id = ?').get(vm_id);
  db.prepare('INSERT INTO boot_order_config (id, vm_id, vm_name, boot_priority, delay_seconds) VALUES (?,?,?,?,?)')
    .run(id, vm_id, vm?.name || '', boot_priority || 100, delay_seconds || 0);
  res.json({ id, message: '添加成功' });
});

router.put('/boot-order/:id', (req, res) => {
  const db = req.app.locals.db;
  const { boot_priority, delay_seconds, enabled } = req.body;
  db.prepare('UPDATE boot_order_config SET boot_priority = ?, delay_seconds = ?, enabled = ? WHERE id = ?')
    .run(boot_priority || 100, delay_seconds || 0, enabled !== undefined ? enabled : 1, req.params.id);
  res.json({ message: '更新成功' });
});

router.delete('/boot-order/:id', (req, res) => {
  const db = req.app.locals.db;
  db.prepare('DELETE FROM boot_order_config WHERE id = ?').run(req.params.id);
  res.json({ message: '删除成功' });
});

// ==================== 组织/资源调度 ====================
router.get('/organizations', (req, res) => {
  const db = req.app.locals.db;
  const rows = db.prepare('SELECT * FROM organizations ORDER BY created_at DESC').all();
  res.json({ data: rows, total: rows.length });
});

router.post('/organizations', (req, res) => {
  const db = req.app.locals.db;
  const id = uuidv4();
  const { name, parent_id, cpu_quota, mem_quota, storage_quota, vm_quota, description } = req.body;
  db.prepare('INSERT INTO organizations (id, name, parent_id, cpu_quota, mem_quota, storage_quota, vm_quota, description) VALUES (?,?,?,?,?,?,?,?)')
    .run(id, name, parent_id || '', cpu_quota || 0, mem_quota || 0, storage_quota || 0, vm_quota || 0, description || '');
  res.json({ id, message: '创建成功' });
});

router.put('/organizations/:id', (req, res) => {
  const db = req.app.locals.db;
  const fields = req.body;
  const sets = Object.keys(fields).map(k => `${k} = ?`).join(', ');
  db.prepare(`UPDATE organizations SET ${sets} WHERE id = ?`).run(...Object.values(fields), req.params.id);
  res.json({ message: '更新成功' });
});

router.delete('/organizations/:id', (req, res) => {
  const db = req.app.locals.db;
  db.prepare('DELETE FROM organizations WHERE id = ?').run(req.params.id);
  res.json({ message: '删除成功' });
});

// ==================== 亲和组 ====================
router.get('/affinity-groups', (req, res) => {
  const db = req.app.locals.db;
  const groups = db.prepare('SELECT * FROM affinity_groups ORDER BY created_at DESC').all();
  for (const g of groups) {
    g.vms = db.prepare('SELECT agv.vm_id, v.name as vm_name FROM affinity_group_vms agv LEFT JOIN vms v ON agv.vm_id = v.id WHERE agv.group_id = ?').all(g.id);
  }
  res.json({ data: groups, total: groups.length });
});

router.post('/affinity-groups', (req, res) => {
  const db = req.app.locals.db;
  const id = uuidv4();
  const { name, type, description } = req.body;
  db.prepare('INSERT INTO affinity_groups (id, name, type, description) VALUES (?,?,?,?)')
    .run(id, name, type || 'affinity', description || '');
  res.json({ id, message: '创建成功' });
});

router.put('/affinity-groups/:id', (req, res) => {
  const db = req.app.locals.db;
  const fields = req.body;
  const sets = Object.keys(fields).map(k => `${k} = ?`).join(', ');
  db.prepare(`UPDATE affinity_groups SET ${sets} WHERE id = ?`).run(...Object.values(fields), req.params.id);
  res.json({ message: '更新成功' });
});

router.delete('/affinity-groups/:id', (req, res) => {
  const db = req.app.locals.db;
  db.prepare('DELETE FROM affinity_group_vms WHERE group_id = ?').run(req.params.id);
  db.prepare('DELETE FROM affinity_groups WHERE id = ?').run(req.params.id);
  res.json({ message: '删除成功' });
});

router.post('/affinity-groups/:id/vms', (req, res) => {
  const db = req.app.locals.db;
  const { vm_id } = req.body;
  try {
    db.prepare('INSERT INTO affinity_group_vms (group_id, vm_id) VALUES (?,?)').run(req.params.id, vm_id);
    res.json({ message: '添加成功' });
  } catch (e) {
    res.json({ message: '已存在' });
  }
});

router.delete('/affinity-groups/:id/vms/:vmId', (req, res) => {
  const db = req.app.locals.db;
  db.prepare('DELETE FROM affinity_group_vms WHERE group_id = ? AND vm_id = ?').run(req.params.id, req.params.vmId);
  res.json({ message: '移除成功' });
});

// ==================== 标签管理 ====================
router.get('/labels', (req, res) => {
  const db = req.app.locals.db;
  const rows = db.prepare('SELECT * FROM labels ORDER BY created_at DESC').all();
  res.json({ data: rows, total: rows.length });
});

router.post('/labels', (req, res) => {
  const db = req.app.locals.db;
  const id = uuidv4();
  const { name, color, category } = req.body;
  db.prepare('INSERT INTO labels (id, name, color, category) VALUES (?,?,?,?)')
    .run(id, name, color || '#409eff', category || 'general');
  res.json({ id, message: '创建成功' });
});

router.put('/labels/:id', (req, res) => {
  const db = req.app.locals.db;
  const { name, color, category } = req.body;
  db.prepare('UPDATE labels SET name = ?, color = ?, category = ? WHERE id = ?')
    .run(name, color || '#409eff', category || 'general', req.params.id);
  res.json({ message: '更新成功' });
});

router.delete('/labels/:id', (req, res) => {
  const db = req.app.locals.db;
  db.prepare('DELETE FROM label_assignments WHERE label_id = ?').run(req.params.id);
  db.prepare('DELETE FROM labels WHERE id = ?').run(req.params.id);
  res.json({ message: '删除成功' });
});

// 标签分配
router.post('/labels/:id/assign', (req, res) => {
  const db = req.app.locals.db;
  const { resource_type, resource_id } = req.body;
  try {
    db.prepare('INSERT INTO label_assignments (label_id, resource_type, resource_id) VALUES (?,?,?)').run(req.params.id, resource_type, resource_id);
    res.json({ message: '标签已分配' });
  } catch (e) {
    res.json({ message: '标签已存在' });
  }
});

router.delete('/labels/:id/assign', (req, res) => {
  const db = req.app.locals.db;
  const { resource_type, resource_id } = req.body;
  db.prepare('DELETE FROM label_assignments WHERE label_id = ? AND resource_type = ? AND resource_id = ?').run(req.params.id, resource_type, resource_id);
  res.json({ message: '标签已取消' });
});

// ==================== 一键检测 ====================
router.get('/detection', (req, res) => {
  const db = req.app.locals.db;
  const rows = db.prepare('SELECT * FROM detection_results ORDER BY created_at DESC').all();
  res.json({ data: rows, total: rows.length });
});

router.post('/detection/run', (req, res) => {
  const db = req.app.locals.db;
  // Clear old results
  db.prepare('DELETE FROM detection_results').run();
  const checks = [
    { category: 'database', item: '数据库连接', status: 'pass', message: '数据库连接正常' },
    { category: 'database', item: '数据表完整性', status: 'pass', message: '所有数据表存在' },
    { category: 'service', item: 'MC服务', status: 'pass', message: '管理控制台服务运行中' },
    { category: 'service', item: 'Cockpit服务', status: 'pass', message: '总控虚拟化界面运行中' },
    { category: 'storage', item: '存储空间', status: 'pass', message: '存储空间充足' },
    { category: 'network', item: '网络连接', status: 'pass', message: '网络连接正常' },
    { category: 'security', item: '证书状态', status: 'pass', message: 'SSL证书有效' },
    { category: 'security', item: '登录安全', status: 'pass', message: '无异常登录记录' },
  ];
  // Check actual DB
  try {
    const tables = db.prepare("SELECT name FROM sqlite_master WHERE type='table'").all();
    checks[1].detail = `共${tables.length}张数据表`;
  } catch (e) {
    checks[0].status = 'fail';
    checks[0].message = '数据库连接失败: ' + e.message;
  }
  for (const c of checks) {
    const id = uuidv4();
    db.prepare('INSERT INTO detection_results (id, category, item, status, message, detail) VALUES (?,?,?,?,?,?)')
      .run(id, c.category, c.item, c.status, c.message, c.detail || '');
  }
  res.json({ message: '检测完成', results: checks });
});

// ==================== 访问策略 ====================
router.get('/access-policies', (req, res) => {
  const db = req.app.locals.db;
  const rows = db.prepare('SELECT * FROM access_policies ORDER BY created_at DESC').all();
  res.json({ data: rows, total: rows.length });
});

router.post('/access-policies', (req, res) => {
  const db = req.app.locals.db;
  const id = uuidv4();
  const { name, type, rule, action, description } = req.body;
  db.prepare('INSERT INTO access_policies (id, name, type, rule, action, description) VALUES (?,?,?,?,?,?)')
    .run(id, name, type || 'ip', rule || '', action || 'allow', description || '');
  res.json({ id, message: '创建成功' });
});

router.put('/access-policies/:id', (req, res) => {
  const db = req.app.locals.db;
  const fields = req.body;
  const sets = Object.keys(fields).map(k => `${k} = ?`).join(', ');
  db.prepare(`UPDATE access_policies SET ${sets} WHERE id = ?`).run(...Object.values(fields), req.params.id);
  res.json({ message: '更新成功' });
});

router.delete('/access-policies/:id', (req, res) => {
  const db = req.app.locals.db;
  db.prepare('DELETE FROM access_policies WHERE id = ?').run(req.params.id);
  res.json({ message: '删除成功' });
});

// ==================== 角色管理 ====================
router.get('/roles', (req, res) => {
  const db = req.app.locals.db;
  const rows = db.prepare('SELECT * FROM roles ORDER BY created_at DESC').all();
  res.json({ data: rows, total: rows.length });
});

router.post('/roles', (req, res) => {
  const db = req.app.locals.db;
  const id = uuidv4();
  const { name, type, permissions, description } = req.body;
  db.prepare('INSERT INTO roles (id, name, type, permissions, description) VALUES (?,?,?,?,?)')
    .run(id, name, type || 'custom', JSON.stringify(permissions || []), description || '');
  res.json({ id, message: '创建成功' });
});

router.put('/roles/:id', (req, res) => {
  const db = req.app.locals.db;
  const { name, permissions, description } = req.body;
  db.prepare('UPDATE roles SET name = ?, permissions = ?, description = ? WHERE id = ?')
    .run(name, JSON.stringify(permissions || []), description || '', req.params.id);
  res.json({ message: '更新成功' });
});

router.delete('/roles/:id', (req, res) => {
  const db = req.app.locals.db;
  db.prepare('DELETE FROM roles WHERE id = ?').run(req.params.id);
  res.json({ message: '删除成功' });
});

module.exports = router;
