// 用户管理 API
const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');

// 列出所有用户（仅 sysadmin 可用）
router.get('/', (req, res) => {
  if (req.user.role !== 'sysadmin') {
    return res.status(403).json({ error: '无权限' });
  }
  const db = req.app.locals.db;
  const users = db.prepare('SELECT id, username, role, display_name, email, phone, status, group_id, last_login, login_fail_count, created_at FROM users').all();
  res.json({ data: users, total: users.length });
});

// 创建用户
router.post('/', (req, res) => {
  if (req.user.role !== 'sysadmin') {
    return res.status(403).json({ error: '无权限' });
  }
  const { username, password, role, display_name, email, phone, group_id } = req.body;
  if (!username || !password || !role) {
    return res.status(400).json({ error: '缺少必填字段' });
  }
  const allowedRoles = ['sysadmin', 'secadmin', 'secauditor', 'user'];
  if (!allowedRoles.includes(role)) {
    return res.status(400).json({ error: '无效角色' });
  }
  const db = req.app.locals.db;
  const existing = db.prepare('SELECT id FROM users WHERE username = ?').get(username);
  if (existing) {
    return res.status(409).json({ error: '用户名已存在' });
  }
  const id = uuidv4();
  const hash = bcrypt.hashSync(password, 10);
  db.prepare(`INSERT INTO users (id, username, password_hash, role, display_name, email, phone, group_id, status) VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'active')`)
    .run(id, username, hash, role, display_name || username, email || '', phone || '', group_id || '');
  res.json({ id, username, role });
});

// ===== 用户组 =====
router.get('/groups', (req, res) => {
  const db = req.app.locals.db;
  const groups = db.prepare('SELECT * FROM user_groups ORDER BY name').all();
  res.json({ data: groups, total: groups.length });
});

router.post('/groups', (req, res) => {
  if (req.user.role !== 'sysadmin') return res.status(403).json({ error: '无权限' });
  const { name, parent_id, description } = req.body;
  if (!name) return res.status(400).json({ error: '请输入组名称' });
  const db = req.app.locals.db;
  const id = uuidv4();
  db.prepare(`INSERT INTO user_groups (id,name,parent_id,description) VALUES (?,?,?,?)`).run(id, name, parent_id || '', description || '');
  res.json(db.prepare('SELECT * FROM user_groups WHERE id = ?').get(id));
});

router.put('/groups/:id', async (req, res) => {
  if (req.user.role !== 'sysadmin') return res.status(403).json({ error: '无权限' });
  try {
    const result = await req.app.locals.driver.updateUserGroup(req.params.id, req.body);
    res.json(result);
  } catch (err) { res.status(400).json({ error: err.message }); }
});

router.delete('/groups/:id', (req, res) => {
  if (req.user.role !== 'sysadmin') return res.status(403).json({ error: '无权限' });
  const db = req.app.locals.db;
  db.prepare('DELETE FROM user_groups WHERE id = ?').run(req.params.id);
  res.json({ message: '已删除' });
});

// ===== LDAP 配置 =====
router.get('/ldap', async (req, res) => {
  try {
    const data = await req.app.locals.driver.getSettingGroup('ldap');
    res.json({ data });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

router.put('/ldap', async (req, res) => {
  try {
    const result = await req.app.locals.driver.saveSettingGroup('ldap', req.body);
    res.json({ data: result });
  } catch (err) { res.status(400).json({ error: err.message }); }
});

router.post('/ldap/test', async (req, res) => {
  // 模拟 LDAP 连接测试
  res.json({ success: true, message: 'LDAP连接测试成功（模拟）' });
});

router.post('/ldap/sync', async (req, res) => {
  // 模拟 LDAP 同步
  res.json({ success: true, message: 'LDAP用户同步完成（模拟）', synced: 0, added: 0, updated: 0 });
});

// 获取用户详情
router.get('/:id', (req, res) => {
  const db = req.app.locals.db;
  const user = db.prepare('SELECT id, username, role, display_name, email, phone, status, group_id, last_login, login_fail_count, created_at FROM users WHERE id = ?').get(req.params.id);
  if (!user) return res.status(404).json({ error: '用户不存在' });
  res.json(user);
});

// 编辑用户
router.put('/:id', (req, res) => {
  if (req.user.role !== 'sysadmin') {
    return res.status(403).json({ error: '无权限' });
  }
  const db = req.app.locals.db;
  const user = db.prepare('SELECT id FROM users WHERE id = ?').get(req.params.id);
  if (!user) return res.status(404).json({ error: '用户不存在' });

  const { display_name, email, phone, group_id, role, ip_restriction, time_restriction } = req.body;
  const fields = [];
  const values = [];
  if (display_name !== undefined) { fields.push('display_name = ?'); values.push(display_name); }
  if (email !== undefined) { fields.push('email = ?'); values.push(email); }
  if (phone !== undefined) { fields.push('phone = ?'); values.push(phone); }
  if (group_id !== undefined) { fields.push('group_id = ?'); values.push(group_id); }
  if (role !== undefined) { fields.push('role = ?'); values.push(role); }
  if (ip_restriction !== undefined) { fields.push('ip_restriction = ?'); values.push(ip_restriction); }
  if (time_restriction !== undefined) { fields.push('time_restriction = ?'); values.push(time_restriction); }
  if (fields.length === 0) return res.status(400).json({ error: '无可更新字段' });
  values.push(req.params.id);
  db.prepare(`UPDATE users SET ${fields.join(', ')} WHERE id = ?`).run(...values);
  res.json({ message: '已更新' });
});

// 重置用户密码
router.put('/:id/password', (req, res) => {
  if (req.user.role !== 'sysadmin') {
    return res.status(403).json({ error: '无权限' });
  }
  const { new_password } = req.body;
  if (!new_password) return res.status(400).json({ error: '请输入新密码' });
  const db = req.app.locals.db;
  const hash = bcrypt.hashSync(new_password, 10);
  db.prepare('UPDATE users SET password_hash = ?, login_fail_count = 0 WHERE id = ?').run(hash, req.params.id);
  res.json({ message: '密码已重置' });
});

// 重置密码（POST 方式，供前端 reset-password 按钮调用）
router.post('/:id/reset-password', (req, res) => {
  if (req.user.role !== 'sysadmin') {
    return res.status(403).json({ error: '无权限' });
  }
  const db = req.app.locals.db;
  const user = db.prepare('SELECT id FROM users WHERE id = ?').get(req.params.id);
  if (!user) return res.status(404).json({ error: '用户不存在' });
  const defaultPassword = 'Abc@1234';
  const hash = bcrypt.hashSync(defaultPassword, 10);
  db.prepare('UPDATE users SET password_hash = ?, login_fail_count = 0 WHERE id = ?').run(hash, req.params.id);
  res.json({ message: '密码已重置为默认密码' });
});

// 删除用户
router.delete('/:id', (req, res) => {
  if (req.user.role !== 'sysadmin') {
    return res.status(403).json({ error: '无权限' });
  }
  const db = req.app.locals.db;
  const user = db.prepare('SELECT id, username FROM users WHERE id = ?').get(req.params.id);
  if (!user) return res.status(404).json({ error: '用户不存在' });
  if (['admin', 'secadmin', 'auditor'].includes(user.username)) {
    return res.status(400).json({ error: '不可删除系统默认账号' });
  }
  db.prepare('DELETE FROM users WHERE id = ?').run(req.params.id);
  res.json({ message: '已删除' });
});

// 更新用户状态（启用/禁用）
router.put('/:id/status', (req, res) => {
  if (req.user.role !== 'sysadmin') {
    return res.status(403).json({ error: '无权限' });
  }
  const { status } = req.body;
  if (!['active', 'disabled'].includes(status)) {
    return res.status(400).json({ error: '无效状态' });
  }
  const db = req.app.locals.db;
  db.prepare('UPDATE users SET status = ? WHERE id = ?').run(status, req.params.id);
  res.json({ message: '已更新' });
});

module.exports = router;
