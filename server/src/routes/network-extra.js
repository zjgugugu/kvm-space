const express = require('express');
const router = express.Router();
const { v4: uuidv4 } = require('uuid');

// ==================== VLAN池 ====================
router.get('/vlan-pools', (req, res) => {
  const db = req.app.locals.db;
  res.json(db.prepare('SELECT * FROM vlan_pools ORDER BY created_at DESC').all());
});

router.post('/vlan-pools', (req, res) => {
  const db = req.app.locals.db;
  const id = uuidv4();
  const { name, vlan_start, vlan_end, description } = req.body;
  db.prepare('INSERT INTO vlan_pools (id, name, vlan_start, vlan_end, description) VALUES (?,?,?,?,?)')
    .run(id, name, vlan_start || 1, vlan_end || 4094, description || '');
  res.json({ id, message: '创建成功' });
});

router.put('/vlan-pools/:id', (req, res) => {
  const db = req.app.locals.db;
  const fields = req.body;
  const sets = Object.keys(fields).map(k => `${k} = ?`).join(', ');
  db.prepare(`UPDATE vlan_pools SET ${sets} WHERE id = ?`).run(...Object.values(fields), req.params.id);
  res.json({ message: '更新成功' });
});

router.delete('/vlan-pools/:id', (req, res) => {
  const db = req.app.locals.db;
  db.prepare('DELETE FROM vlan_pools WHERE id = ?').run(req.params.id);
  res.json({ message: '删除成功' });
});

// ==================== 端口镜像 ====================
router.get('/port-mirroring', (req, res) => {
  const db = req.app.locals.db;
  res.json(db.prepare('SELECT * FROM port_mirroring ORDER BY created_at DESC').all());
});

router.post('/port-mirroring', (req, res) => {
  const db = req.app.locals.db;
  const id = uuidv4();
  const { name, source_network, source_port, dest_network, dest_port, direction, description } = req.body;
  db.prepare('INSERT INTO port_mirroring (id, name, source_network, source_port, dest_network, dest_port, direction, description) VALUES (?,?,?,?,?,?,?,?)')
    .run(id, name, source_network || '', source_port || '', dest_network || '', dest_port || '', direction || 'both', description || '');
  res.json({ id, message: '创建成功' });
});

router.put('/port-mirroring/:id', (req, res) => {
  const db = req.app.locals.db;
  const fields = req.body;
  const sets = Object.keys(fields).map(k => `${k} = ?`).join(', ');
  db.prepare(`UPDATE port_mirroring SET ${sets} WHERE id = ?`).run(...Object.values(fields), req.params.id);
  res.json({ message: '更新成功' });
});

router.delete('/port-mirroring/:id', (req, res) => {
  const db = req.app.locals.db;
  db.prepare('DELETE FROM port_mirroring WHERE id = ?').run(req.params.id);
  res.json({ message: '删除成功' });
});

// ==================== 网络配置规则 ====================
router.get('/config-rules', (req, res) => {
  const db = req.app.locals.db;
  res.json(db.prepare('SELECT * FROM network_config_rules ORDER BY created_at DESC').all());
});

router.post('/config-rules', (req, res) => {
  const db = req.app.locals.db;
  const id = uuidv4();
  const { name, type, network_id, bandwidth_limit, priority, description } = req.body;
  db.prepare('INSERT INTO network_config_rules (id, name, type, network_id, bandwidth_limit, priority, description) VALUES (?,?,?,?,?,?,?)')
    .run(id, name, type || 'qos', network_id || '', bandwidth_limit || 0, priority || 0, description || '');
  res.json({ id, message: '创建成功' });
});

router.put('/config-rules/:id', (req, res) => {
  const db = req.app.locals.db;
  const fields = req.body;
  const sets = Object.keys(fields).map(k => `${k} = ?`).join(', ');
  db.prepare(`UPDATE network_config_rules SET ${sets} WHERE id = ?`).run(...Object.values(fields), req.params.id);
  res.json({ message: '更新成功' });
});

router.delete('/config-rules/:id', (req, res) => {
  const db = req.app.locals.db;
  db.prepare('DELETE FROM network_config_rules WHERE id = ?').run(req.params.id);
  res.json({ message: '删除成功' });
});

// ==================== 虚拟防火墙 ====================
router.get('/firewalls', (req, res) => {
  const db = req.app.locals.db;
  res.json(db.prepare('SELECT * FROM virtual_firewalls ORDER BY created_at DESC').all());
});

router.get('/firewalls/:id', (req, res) => {
  const db = req.app.locals.db;
  const fw = db.prepare('SELECT * FROM virtual_firewalls WHERE id = ?').get(req.params.id);
  if (!fw) return res.status(404).json({ error: '虚拟防火墙不存在' });
  fw.rules = db.prepare('SELECT * FROM firewall_rules WHERE firewall_id = ? ORDER BY priority').all(req.params.id);
  res.json(fw);
});

router.post('/firewalls', (req, res) => {
  const db = req.app.locals.db;
  const id = uuidv4();
  const { name, network_id, default_action, description } = req.body;
  db.prepare('INSERT INTO virtual_firewalls (id, name, network_id, default_action, description) VALUES (?,?,?,?,?)')
    .run(id, name, network_id || '', default_action || 'accept', description || '');
  res.json({ id, message: '创建成功' });
});

router.put('/firewalls/:id', (req, res) => {
  const db = req.app.locals.db;
  const fields = req.body;
  const sets = Object.keys(fields).map(k => `${k} = ?`).join(', ');
  db.prepare(`UPDATE virtual_firewalls SET ${sets} WHERE id = ?`).run(...Object.values(fields), req.params.id);
  res.json({ message: '更新成功' });
});

router.delete('/firewalls/:id', (req, res) => {
  const db = req.app.locals.db;
  db.prepare('DELETE FROM firewall_rules WHERE firewall_id = ?').run(req.params.id);
  db.prepare('DELETE FROM virtual_firewalls WHERE id = ?').run(req.params.id);
  res.json({ message: '删除成功' });
});

router.post('/firewalls/:id/rules', (req, res) => {
  const db = req.app.locals.db;
  const ruleId = uuidv4();
  const { direction, protocol, port_range, source, dest, action, priority } = req.body;
  db.prepare('INSERT INTO firewall_rules (id, firewall_id, direction, protocol, port_range, source, dest, action, priority) VALUES (?,?,?,?,?,?,?,?,?)')
    .run(ruleId, req.params.id, direction || 'inbound', protocol || 'tcp', port_range || '', source || '', dest || '', action || 'accept', priority || 100);
  res.json({ id: ruleId, message: '规则添加成功' });
});

router.delete('/firewalls/:fwId/rules/:ruleId', (req, res) => {
  const db = req.app.locals.db;
  db.prepare('DELETE FROM firewall_rules WHERE id = ? AND firewall_id = ?').run(req.params.ruleId, req.params.fwId);
  res.json({ message: '规则删除成功' });
});

// ==================== 端口组 ====================
router.get('/port-groups', (req, res) => {
  const db = req.app.locals.db;
  res.json(db.prepare('SELECT * FROM port_groups ORDER BY created_at DESC').all());
});

router.post('/port-groups', (req, res) => {
  const db = req.app.locals.db;
  const id = uuidv4();
  const { name, network_id, vlan_id, type, description } = req.body;
  db.prepare('INSERT INTO port_groups (id, name, network_id, vlan_id, type, description) VALUES (?,?,?,?,?,?)')
    .run(id, name, network_id || '', vlan_id || 0, type || 'access', description || '');
  res.json({ id, message: '创建成功' });
});

router.put('/port-groups/:id', (req, res) => {
  const db = req.app.locals.db;
  const fields = req.body;
  const sets = Object.keys(fields).map(k => `${k} = ?`).join(', ');
  db.prepare(`UPDATE port_groups SET ${sets} WHERE id = ?`).run(...Object.values(fields), req.params.id);
  res.json({ message: '更新成功' });
});

router.delete('/port-groups/:id', (req, res) => {
  const db = req.app.locals.db;
  db.prepare('DELETE FROM port_groups WHERE id = ?').run(req.params.id);
  res.json({ message: '删除成功' });
});

module.exports = router;
