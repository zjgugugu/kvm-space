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
  const { status, page = 1, page_size = 20 } = req.query;
  const limit = Math.min(parseInt(page_size) || 20, 100);
  const offset = ((parseInt(page) || 1) - 1) * limit;

  let where = [];
  let params = [];
  if (status) { where.push('status = ?'); params.push(status); }

  const whereClause = where.length ? `WHERE ${where.join(' AND ')}` : '';
  const total = db.prepare(`SELECT COUNT(*) as cnt FROM tasks ${whereClause}`).get(...params).cnt;
  const tasks = db.prepare(`SELECT * FROM tasks ${whereClause} ORDER BY created_at DESC LIMIT ? OFFSET ?`).all(...params, limit, offset);

  res.json({ data: tasks, total, page: parseInt(page), page_size: limit });
});

module.exports = router;
