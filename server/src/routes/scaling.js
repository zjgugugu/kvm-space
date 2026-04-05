const express = require('express');
const router = express.Router();
const { v4: uuidv4 } = require('uuid');

// ==================== 自动伸缩策略 ====================
router.get('/strategies', (req, res) => {
  const db = req.app.locals.db;
  res.json(db.prepare('SELECT * FROM scaling_strategies ORDER BY created_at DESC').all());
});

router.post('/strategies', (req, res) => {
  const db = req.app.locals.db;
  const id = uuidv4();
  const { name, metric, threshold_up, threshold_down, cooldown, description } = req.body;
  db.prepare('INSERT INTO scaling_strategies (id, name, metric, threshold_up, threshold_down, cooldown, description) VALUES (?,?,?,?,?,?,?)')
    .run(id, name, metric || 'cpu', threshold_up || 80, threshold_down || 20, cooldown || 300, description || '');
  res.json({ id, message: '策略创建成功' });
});

router.put('/strategies/:id', (req, res) => {
  const db = req.app.locals.db;
  const fields = req.body;
  const sets = Object.keys(fields).map(k => `${k} = ?`).join(', ');
  if (!sets) return res.status(400).json({ error: '无更新字段' });
  db.prepare(`UPDATE scaling_strategies SET ${sets} WHERE id = ?`).run(...Object.values(fields), req.params.id);
  res.json({ message: '更新成功' });
});

router.delete('/strategies/:id', (req, res) => {
  const db = req.app.locals.db;
  db.prepare('DELETE FROM scaling_strategies WHERE id = ?').run(req.params.id);
  res.json({ message: '删除成功' });
});

// ==================== 自动伸缩组 ====================
router.get('/groups', (req, res) => {
  const db = req.app.locals.db;
  res.json(db.prepare('SELECT sg.*, ss.name as strategy_name FROM scaling_groups sg LEFT JOIN scaling_strategies ss ON sg.strategy_id = ss.id ORDER BY sg.created_at DESC').all());
});

router.post('/groups', (req, res) => {
  const db = req.app.locals.db;
  const id = uuidv4();
  const { name, strategy_id, template_id, min_instances, max_instances, description } = req.body;
  db.prepare('INSERT INTO scaling_groups (id, name, strategy_id, template_id, min_instances, max_instances, description) VALUES (?,?,?,?,?,?,?)')
    .run(id, name, strategy_id || '', template_id || '', min_instances || 1, max_instances || 10, description || '');
  res.json({ id, message: '伸缩组创建成功' });
});

router.put('/groups/:id', (req, res) => {
  const db = req.app.locals.db;
  const fields = req.body;
  const sets = Object.keys(fields).map(k => `${k} = ?`).join(', ');
  if (!sets) return res.status(400).json({ error: '无更新字段' });
  db.prepare(`UPDATE scaling_groups SET ${sets} WHERE id = ?`).run(...Object.values(fields), req.params.id);
  res.json({ message: '更新成功' });
});

router.delete('/groups/:id', (req, res) => {
  const db = req.app.locals.db;
  db.prepare('DELETE FROM scaling_groups WHERE id = ?').run(req.params.id);
  res.json({ message: '删除成功' });
});

// ==================== 负载均衡 ====================
router.get('/load-balancers', (req, res) => {
  const db = req.app.locals.db;
  res.json(db.prepare('SELECT * FROM load_balancers ORDER BY created_at DESC').all());
});

router.get('/load-balancers/:id', (req, res) => {
  const db = req.app.locals.db;
  const lb = db.prepare('SELECT * FROM load_balancers WHERE id = ?').get(req.params.id);
  if (!lb) return res.status(404).json({ error: '负载均衡不存在' });
  lb.members = db.prepare('SELECT * FROM load_balancer_members WHERE lb_id = ?').all(req.params.id);
  res.json(lb);
});

router.post('/load-balancers', (req, res) => {
  const db = req.app.locals.db;
  const id = uuidv4();
  const { name, algorithm, vip, port, description } = req.body;
  db.prepare('INSERT INTO load_balancers (id, name, algorithm, vip, port, description) VALUES (?,?,?,?,?,?)')
    .run(id, name, algorithm || 'round_robin', vip || '', port || 0, description || '');
  res.json({ id, message: '负载均衡创建成功' });
});

router.put('/load-balancers/:id', (req, res) => {
  const db = req.app.locals.db;
  const fields = req.body;
  const sets = Object.keys(fields).map(k => `${k} = ?`).join(', ');
  if (!sets) return res.status(400).json({ error: '无更新字段' });
  db.prepare(`UPDATE load_balancers SET ${sets} WHERE id = ?`).run(...Object.values(fields), req.params.id);
  res.json({ message: '更新成功' });
});

router.delete('/load-balancers/:id', (req, res) => {
  const db = req.app.locals.db;
  db.prepare('DELETE FROM load_balancer_members WHERE lb_id = ?').run(req.params.id);
  db.prepare('DELETE FROM load_balancers WHERE id = ?').run(req.params.id);
  res.json({ message: '删除成功' });
});

// 负载均衡成员管理
router.post('/load-balancers/:id/members', (req, res) => {
  const db = req.app.locals.db;
  const memberId = uuidv4();
  const { server_ip, server_port, weight } = req.body;
  db.prepare('INSERT INTO load_balancer_members (id, lb_id, server_ip, server_port, weight) VALUES (?,?,?,?,?)')
    .run(memberId, req.params.id, server_ip || '', server_port || 0, weight || 1);
  res.json({ id: memberId, message: '成员添加成功' });
});

router.delete('/load-balancers/:id/members/:memberId', (req, res) => {
  const db = req.app.locals.db;
  db.prepare('DELETE FROM load_balancer_members WHERE id = ? AND lb_id = ?').run(req.params.memberId, req.params.id);
  res.json({ message: '成员删除成功' });
});

// ==================== DRS (分布式资源调度) ====================
router.get('/drs', (req, res) => {
  const db = req.app.locals.db;
  res.json(db.prepare('SELECT * FROM drs_rules ORDER BY created_at DESC').all());
});

router.post('/drs', (req, res) => {
  const db = req.app.locals.db;
  const id = uuidv4();
  const { name, mode, threshold, check_interval, description } = req.body;
  db.prepare('INSERT INTO drs_rules (id, name, mode, threshold, check_interval, description) VALUES (?,?,?,?,?,?)')
    .run(id, name, mode || '全自动', threshold || 70, check_interval || 5, description || '');
  res.json({ id, message: 'DRS规则创建成功' });
});

router.put('/drs/:id', (req, res) => {
  const db = req.app.locals.db;
  const fields = req.body;
  const sets = Object.keys(fields).map(k => `${k} = ?`).join(', ');
  if (!sets) return res.status(400).json({ error: '无更新字段' });
  db.prepare(`UPDATE drs_rules SET ${sets} WHERE id = ?`).run(...Object.values(fields), req.params.id);
  res.json({ message: '更新成功' });
});

router.delete('/drs/:id', (req, res) => {
  const db = req.app.locals.db;
  db.prepare('DELETE FROM drs_rules WHERE id = ?').run(req.params.id);
  res.json({ message: '删除成功' });
});

// ==================== DPM (分布式电源管理) ====================
router.get('/dpm', (req, res) => {
  const db = req.app.locals.db;
  res.json(db.prepare('SELECT * FROM dpm_policies ORDER BY created_at DESC').all());
});

router.post('/dpm', (req, res) => {
  const db = req.app.locals.db;
  const id = uuidv4();
  const { name, mode, low_threshold, high_threshold, description } = req.body;
  db.prepare('INSERT INTO dpm_policies (id, name, mode, low_threshold, high_threshold, description) VALUES (?,?,?,?,?,?)')
    .run(id, name, mode || '自动', low_threshold || 20, high_threshold || 80, description || '');
  res.json({ id, message: 'DPM策略创建成功' });
});

router.put('/dpm/:id', (req, res) => {
  const db = req.app.locals.db;
  const fields = req.body;
  const sets = Object.keys(fields).map(k => `${k} = ?`).join(', ');
  if (!sets) return res.status(400).json({ error: '无更新字段' });
  db.prepare(`UPDATE dpm_policies SET ${sets} WHERE id = ?`).run(...Object.values(fields), req.params.id);
  res.json({ message: '更新成功' });
});

router.delete('/dpm/:id', (req, res) => {
  const db = req.app.locals.db;
  db.prepare('DELETE FROM dpm_policies WHERE id = ?').run(req.params.id);
  res.json({ message: '删除成功' });
});

module.exports = router;
