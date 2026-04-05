const express = require('express');
const router = express.Router();
const { v4: uuidv4 } = require('uuid');

// 终端用户绑定列表
router.get('/', (req, res) => {
  const db = req.app.locals.db;
  res.json(db.prepare('SELECT * FROM terminal_user_bindings ORDER BY created_at DESC').all());
});

// 获取单条
router.get('/:id', (req, res) => {
  const db = req.app.locals.db;
  const row = db.prepare('SELECT * FROM terminal_user_bindings WHERE id = ?').get(req.params.id);
  if (!row) return res.status(404).json({ error: '未找到' });
  res.json(row);
});

// 新建绑定
router.post('/', (req, res) => {
  const db = req.app.locals.db;
  const id = uuidv4();
  const { terminal, terminal_ip, user, user_group, pool, bind_type } = req.body;
  db.prepare('INSERT INTO terminal_user_bindings (id, terminal, terminal_ip, user, user_group, pool, bind_type) VALUES (?,?,?,?,?,?,?)')
    .run(id, terminal || '', terminal_ip || '', user || '', user_group || '', pool || '', bind_type || '浮动');
  res.json({ id, message: '绑定创建成功' });
});

// 更新绑定
router.put('/:id', (req, res) => {
  const db = req.app.locals.db;
  const fields = req.body;
  const allowed = ['terminal', 'terminal_ip', 'user', 'user_group', 'pool', 'bind_type', 'status'];
  const sets = [], vals = [];
  for (const k of allowed) {
    if (fields[k] !== undefined) { sets.push(`${k} = ?`); vals.push(fields[k]); }
  }
  if (!sets.length) return res.status(400).json({ error: '无更新字段' });
  db.prepare(`UPDATE terminal_user_bindings SET ${sets.join(', ')} WHERE id = ?`).run(...vals, req.params.id);
  res.json({ message: '更新成功' });
});

// 删除绑定
router.delete('/:id', (req, res) => {
  const db = req.app.locals.db;
  db.prepare('DELETE FROM terminal_user_bindings WHERE id = ?').run(req.params.id);
  res.json({ message: '解绑成功' });
});

module.exports = router;
