// 事件/日志 API
const express = require('express');
const router = express.Router();

// 事件列表（分页+筛选）
router.get('/', (req, res) => {
  const db = req.app.locals.db;
  const { type, level, page = 1, page_size = 20 } = req.query;
  const limit = Math.min(parseInt(page_size) || 20, 100);
  const offset = ((parseInt(page) || 1) - 1) * limit;

  let where = [];
  let params = [];
  if (type) { where.push('type = ?'); params.push(type); }
  if (level) { where.push('level = ?'); params.push(level); }

  const whereClause = where.length ? `WHERE ${where.join(' AND ')}` : '';
  const total = db.prepare(`SELECT COUNT(*) as cnt FROM events ${whereClause}`).get(...params).cnt;
  const events = db.prepare(`SELECT * FROM events ${whereClause} ORDER BY created_at DESC LIMIT ? OFFSET ?`).all(...params, limit, offset);

  res.json({ data: events, total, page: parseInt(page), page_size: limit });
});

// 任务列表
router.get('/tasks', (req, res) => {
  const db = req.app.locals.db;
  const { status, type, page = 1, page_size = 20 } = req.query;
  const limit = Math.min(parseInt(page_size) || 20, 100);
  const offset = ((parseInt(page) || 1) - 1) * limit;

  let where = [];
  let params = [];
  if (status) { where.push('status = ?'); params.push(status); }
  if (type) { where.push('type = ?'); params.push(type); }

  const whereClause = where.length ? `WHERE ${where.join(' AND ')}` : '';
  const total = db.prepare(`SELECT COUNT(*) as cnt FROM tasks ${whereClause}`).get(...params).cnt;
  const tasks = db.prepare(`SELECT * FROM tasks ${whereClause} ORDER BY created_at DESC LIMIT ? OFFSET ?`).all(...params, limit, offset);

  res.json({ data: tasks, total, page: parseInt(page), page_size: limit });
});

// 任务详情
router.get('/tasks/:id', (req, res) => {
  const db = req.app.locals.db;
  const task = db.prepare('SELECT * FROM tasks WHERE id = ?').get(req.params.id);
  if (!task) return res.status(404).json({ error: '任务不存在' });
  res.json(task);
});

// 重试失败任务
router.post('/tasks/:id/retry', (req, res) => {
  const db = req.app.locals.db;
  const task = db.prepare('SELECT * FROM tasks WHERE id = ?').get(req.params.id);
  if (!task) return res.status(404).json({ error: '任务不存在' });
  if (task.status !== 'failed') return res.status(400).json({ error: '只能重试失败的任务' });
  db.prepare('UPDATE tasks SET status = ?, progress = 0, started_at = datetime(\'now\'), finished_at = NULL WHERE id = ?').run('pending', req.params.id);
  // Simulate completion after short delay
  setTimeout(() => {
    db.prepare('UPDATE tasks SET status = ?, progress = 100, finished_at = datetime(\'now\'), message = ? WHERE id = ?').run('completed', task.message.replace('失败', '完成'), req.params.id);
  }, 1000);
  res.json({ success: true, message: '任务已重新提交' });
});

// 删除/归档任务
router.delete('/tasks/:id', (req, res) => {
  const db = req.app.locals.db;
  const task = db.prepare('SELECT * FROM tasks WHERE id = ?').get(req.params.id);
  if (!task) return res.status(404).json({ error: '任务不存在' });
  db.prepare('DELETE FROM tasks WHERE id = ?').run(req.params.id);
  res.json({ success: true });
});

// ===== 审批管理 =====
router.get('/approvals', (req, res) => {
  const db = req.app.locals.db;
  const { status, page = 1, page_size = 20 } = req.query;
  const limit = Math.min(parseInt(page_size) || 20, 100);
  const offset = ((parseInt(page) || 1) - 1) * limit;

  let where = [];
  let params = [];
  if (status) { where.push('status = ?'); params.push(status); }

  const whereClause = where.length ? `WHERE ${where.join(' AND ')}` : '';
  const total = db.prepare(`SELECT COUNT(*) as cnt FROM approvals ${whereClause}`).get(...params).cnt;
  const approvals = db.prepare(`SELECT * FROM approvals ${whereClause} ORDER BY created_at DESC LIMIT ? OFFSET ?`).all(...params, limit, offset);

  res.json({ data: approvals, total, page: parseInt(page), page_size: limit });
});

// 审批通过
router.post('/approvals/:id/approve', (req, res) => {
  const db = req.app.locals.db;
  const approval = db.prepare('SELECT * FROM approvals WHERE id = ?').get(req.params.id);
  if (!approval) return res.status(404).json({ error: '审批不存在' });
  if (approval.status !== 'pending') return res.status(400).json({ error: '该审批已处理' });
  db.prepare('UPDATE approvals SET status = ?, approver = ?, reason = ?, resolved_at = datetime(\'now\') WHERE id = ?')
    .run('approved', req.user?.username || 'admin', req.body.reason || '', req.params.id);
  res.json({ success: true, message: '已批准' });
});

// 审批拒绝
router.post('/approvals/:id/reject', (req, res) => {
  const db = req.app.locals.db;
  const approval = db.prepare('SELECT * FROM approvals WHERE id = ?').get(req.params.id);
  if (!approval) return res.status(404).json({ error: '审批不存在' });
  if (approval.status !== 'pending') return res.status(400).json({ error: '该审批已处理' });
  db.prepare('UPDATE approvals SET status = ?, approver = ?, reason = ?, resolved_at = datetime(\'now\') WHERE id = ?')
    .run('rejected', req.user?.username || 'admin', req.body.reason || '', req.params.id);
  res.json({ success: true, message: '已拒绝' });
});

module.exports = router;
