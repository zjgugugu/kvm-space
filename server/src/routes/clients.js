const express = require('express');
const router = express.Router();
const { v4: uuidv4 } = require('uuid');

// GET /api/clients — 终端列表
router.get('/', (req, res) => {
  const db = req.app.locals.db;
  const { status, keyword } = req.query;
  let sql = 'SELECT * FROM terminals WHERE 1=1';
  const params = [];
  if (status) { sql += ' AND status = ?'; params.push(status); }
  if (keyword) { sql += ' AND (name LIKE ? OR ip LIKE ? OR mac LIKE ?)'; params.push(`%${keyword}%`, `%${keyword}%`, `%${keyword}%`); }
  sql += ' ORDER BY created_at DESC';
  res.json(db.prepare(sql).all(...params));
});

// GET /api/clients/:id — 终端详情
router.get('/:id', (req, res) => {
  const db = req.app.locals.db;
  const row = db.prepare('SELECT * FROM terminals WHERE id = ?').get(req.params.id);
  if (!row) return res.status(404).json({ error: '终端不存在' });
  res.json(row);
});

// POST /api/clients — 添加终端
router.post('/', (req, res) => {
  const db = req.app.locals.db;
  const id = uuidv4();
  const { name, ip, mac, type, os, version } = req.body;
  db.prepare('INSERT INTO terminals (id, name, ip, mac, type, os, version) VALUES (?,?,?,?,?,?,?)')
    .run(id, name, ip || '', mac || '', type || 'TC', os || '', version || '');
  res.json({ id, message: '终端添加成功' });
});

// PUT /api/clients/:id — 更新终端
router.put('/:id', (req, res) => {
  const db = req.app.locals.db;
  const fields = req.body;
  const sets = Object.keys(fields).map(k => `${k} = ?`).join(', ');
  if (!sets) return res.status(400).json({ error: '无更新字段' });
  db.prepare(`UPDATE terminals SET ${sets} WHERE id = ?`).run(...Object.values(fields), req.params.id);
  res.json({ message: '更新成功' });
});

// DELETE /api/clients/:id — 删除终端
router.delete('/:id', (req, res) => {
  const db = req.app.locals.db;
  db.prepare('DELETE FROM terminals WHERE id = ?').run(req.params.id);
  res.json({ message: '删除成功' });
});

// POST /api/clients/:id/action — 终端操作(重启/关机/升级)
router.post('/:id/action', (req, res) => {
  const db = req.app.locals.db;
  const { action } = req.body;
  const terminal = db.prepare('SELECT * FROM terminals WHERE id = ?').get(req.params.id);
  if (!terminal) return res.status(404).json({ error: '终端不存在' });

  const taskId = uuidv4();
  db.prepare('INSERT INTO terminal_tasks (id, terminal_id, terminal_name, type, status) VALUES (?,?,?,?,?)')
    .run(taskId, req.params.id, terminal.name, action || 'restart', 'pending');
  res.json({ task_id: taskId, message: `终端${action}任务已创建` });
});

// POST /api/clients/batch-action — 批量操作
router.post('/batch-action', (req, res) => {
  const db = req.app.locals.db;
  const { ids, action } = req.body;
  if (!ids || !ids.length) return res.status(400).json({ error: '未选择终端' });
  const tasks = [];
  for (const id of ids) {
    const terminal = db.prepare('SELECT * FROM terminals WHERE id = ?').get(id);
    if (terminal) {
      const taskId = uuidv4();
      db.prepare('INSERT INTO terminal_tasks (id, terminal_id, terminal_name, type, status) VALUES (?,?,?,?,?)')
        .run(taskId, id, terminal.name, action || 'restart', 'pending');
      tasks.push(taskId);
    }
  }
  res.json({ task_ids: tasks, message: `已创建${tasks.length}个任务` });
});

// GET /api/clients/tasks/list — 终端任务列表
router.get('/tasks/list', (req, res) => {
  const db = req.app.locals.db;
  res.json(db.prepare('SELECT * FROM terminal_tasks ORDER BY created_at DESC LIMIT 200').all());
});

module.exports = router;
