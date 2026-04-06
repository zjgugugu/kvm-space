const express = require('express');
const router = express.Router();
const { v4: uuidv4 } = require('uuid');

// ==================== 应用程序层 ====================
router.get('/layers', (req, res) => {
  const db = req.app.locals.db;
  const rows = db.prepare('SELECT * FROM app_layers ORDER BY created_at DESC').all();
  res.json({ data: rows, total: rows.length });
});

router.post('/layers', (req, res) => {
  const db = req.app.locals.db;
  const id = uuidv4();
  const { name, version, os_type, size, description } = req.body;
  db.prepare('INSERT INTO app_layers (id, name, version, os_type, size, description) VALUES (?,?,?,?,?,?)')
    .run(id, name, version || '1.0', os_type || 'linux', size || 0, description || '');
  res.json({ id, message: '创建成功' });
});

router.put('/layers/:id', (req, res) => {
  const db = req.app.locals.db;
  const fields = req.body;
  const sets = Object.keys(fields).map(k => `${k} = ?`).join(', ');
  if (!sets) return res.status(400).json({ error: '无更新字段' });
  db.prepare(`UPDATE app_layers SET ${sets} WHERE id = ?`).run(...Object.values(fields), req.params.id);
  res.json({ message: '更新成功' });
});

router.delete('/layers/:id', (req, res) => {
  const db = req.app.locals.db;
  db.prepare('DELETE FROM app_layers WHERE id = ?').run(req.params.id);
  res.json({ message: '删除成功' });
});

// ==================== 软件库 ====================
router.get('/software', (req, res) => {
  const db = req.app.locals.db;
  const rows = db.prepare('SELECT * FROM software_library ORDER BY created_at DESC').all();
  res.json({ data: rows, total: rows.length });
});

router.post('/software', (req, res) => {
  const db = req.app.locals.db;
  const id = uuidv4();
  const { name, version, category, size, file_path, description } = req.body;
  db.prepare('INSERT INTO software_library (id, name, version, category, size, file_path, description) VALUES (?,?,?,?,?,?,?)')
    .run(id, name, version || '', category || '', size || 0, file_path || '', description || '');
  res.json({ id, message: '创建成功' });
});

router.put('/software/:id', (req, res) => {
  const db = req.app.locals.db;
  const fields = req.body;
  const sets = Object.keys(fields).map(k => `${k} = ?`).join(', ');
  if (!sets) return res.status(400).json({ error: '无更新字段' });
  db.prepare(`UPDATE software_library SET ${sets} WHERE id = ?`).run(...Object.values(fields), req.params.id);
  res.json({ message: '更新成功' });
});

router.delete('/software/:id', (req, res) => {
  const db = req.app.locals.db;
  db.prepare('DELETE FROM software_library WHERE id = ?').run(req.params.id);
  res.json({ message: '删除成功' });
});

// ==================== 软件发布 ====================
router.get('/software-publish', (req, res) => {
  const db = req.app.locals.db;
  const rows = db.prepare('SELECT sp.*, sl.name as software_name FROM software_publish sp LEFT JOIN software_library sl ON sp.software_id = sl.id ORDER BY sp.created_at DESC').all();
  res.json({ data: rows, total: rows.length });
});

router.post('/software-publish', (req, res) => {
  const db = req.app.locals.db;
  const id = uuidv4();
  const { software_id, target_type, target_id, target_name } = req.body;
  db.prepare('INSERT INTO software_publish (id, software_id, target_type, target_id, target_name) VALUES (?,?,?,?,?)')
    .run(id, software_id || '', target_type || 'template', target_id || '', target_name || '');
  res.json({ id, message: '发布成功' });
});

router.delete('/software-publish/:id', (req, res) => {
  const db = req.app.locals.db;
  db.prepare('DELETE FROM software_publish WHERE id = ?').run(req.params.id);
  res.json({ message: '删除成功' });
});

// ==================== 应用管控 ====================
router.get('/control-rules', (req, res) => {
  const db = req.app.locals.db;
  const type = req.query.type; // 'builtin' or 'custom'
  const sql = type ? 'SELECT * FROM app_control_rules WHERE type = ? ORDER BY created_at DESC' : 'SELECT * FROM app_control_rules ORDER BY created_at DESC';
  const rows = type ? db.prepare(sql).all(type) : db.prepare(sql).all();
  res.json({ data: rows, total: rows.length });
});

router.post('/control-rules', (req, res) => {
  const db = req.app.locals.db;
  const id = uuidv4();
  const { name, type, category, action, process_name, hash, description } = req.body;
  db.prepare('INSERT INTO app_control_rules (id, name, type, category, action, process_name, hash, description) VALUES (?,?,?,?,?,?,?,?)')
    .run(id, name, type || 'custom', category || '', action || 'block', process_name || '', hash || '', description || '');
  res.json({ id, message: '创建成功' });
});

router.put('/control-rules/:id', (req, res) => {
  const db = req.app.locals.db;
  const fields = req.body;
  const sets = Object.keys(fields).map(k => `${k} = ?`).join(', ');
  if (!sets) return res.status(400).json({ error: '无更新字段' });
  db.prepare(`UPDATE app_control_rules SET ${sets} WHERE id = ?`).run(...Object.values(fields), req.params.id);
  res.json({ message: '更新成功' });
});

router.delete('/control-rules/:id', (req, res) => {
  const db = req.app.locals.db;
  db.prepare('DELETE FROM app_control_rules WHERE id = ?').run(req.params.id);
  res.json({ message: '删除成功' });
});

// ==================== 应用发布 - 应用组 ====================
router.get('/virtual-groups', (req, res) => {
  const db = req.app.locals.db;
  const rows = db.prepare('SELECT * FROM virtual_app_groups ORDER BY created_at DESC').all();
  res.json({ data: rows, total: rows.length });
});

router.post('/virtual-groups', (req, res) => {
  const db = req.app.locals.db;
  const id = uuidv4();
  const { name, app_type, description } = req.body;
  db.prepare('INSERT INTO virtual_app_groups (id, name, app_type, description) VALUES (?,?,?,?)')
    .run(id, name, app_type || 'desktop', description || '');
  res.json({ id, message: '创建成功' });
});

router.put('/virtual-groups/:id', (req, res) => {
  const db = req.app.locals.db;
  const fields = req.body;
  const sets = Object.keys(fields).map(k => `${k} = ?`).join(', ');
  if (!sets) return res.status(400).json({ error: '无更新字段' });
  db.prepare(`UPDATE virtual_app_groups SET ${sets} WHERE id = ?`).run(...Object.values(fields), req.params.id);
  res.json({ message: '更新成功' });
});

router.delete('/virtual-groups/:id', (req, res) => {
  const db = req.app.locals.db;
  db.prepare('DELETE FROM virtual_app_groups WHERE id = ?').run(req.params.id);
  res.json({ message: '删除成功' });
});

// ==================== 应用发布 - 应用会话 ====================
router.get('/virtual-sessions', (req, res) => {
  const db = req.app.locals.db;
  const rows = db.prepare('SELECT * FROM virtual_app_sessions ORDER BY started_at DESC').all();
  res.json({ data: rows, total: rows.length });
});

router.post('/virtual-sessions', (req, res) => {
  const db = req.app.locals.db;
  const id = uuidv4();
  const { group_id, user_id, username, app_name } = req.body;
  db.prepare('INSERT INTO virtual_app_sessions (id, group_id, user_id, username, app_name) VALUES (?,?,?,?,?)')
    .run(id, group_id || '', user_id || '', username || '', app_name || '');
  res.json({ id, message: '创建成功' });
});

router.delete('/virtual-sessions/:id', (req, res) => {
  const db = req.app.locals.db;
  db.prepare('DELETE FROM virtual_app_sessions WHERE id = ?').run(req.params.id);
  res.json({ message: '删除成功' });
});

module.exports = router;
