const express = require('express');
const router = express.Router();
const { v4: uuidv4 } = require('uuid');
const path = require('path');
const fs = require('fs');

// GET /api/files — 文件列表
router.get('/', (req, res) => {
  const db = req.app.locals.db;
  const { category, type } = req.query;
  let sql = 'SELECT * FROM managed_files WHERE 1=1';
  const params = [];
  if (category) { sql += ' AND category = ?'; params.push(category); }
  if (type) { sql += ' AND type = ?'; params.push(type); }
  sql += ' ORDER BY created_at DESC';
  res.json(db.prepare(sql).all(...params));
});

// GET /api/files/:id — 文件详情
router.get('/:id', (req, res) => {
  const db = req.app.locals.db;
  const row = db.prepare('SELECT * FROM managed_files WHERE id = ?').get(req.params.id);
  if (!row) return res.status(404).json({ error: '文件不存在' });
  res.json(row);
});

// POST /api/files — 上传/登记文件
router.post('/', (req, res) => {
  const db = req.app.locals.db;
  const id = uuidv4();
  const { name, type, category, size, path: filePath, md5 } = req.body;
  db.prepare('INSERT INTO managed_files (id, name, type, category, size, path, md5, upload_user) VALUES (?,?,?,?,?,?,?,?)')
    .run(id, name, type || 'iso', category || 'desktop', size || 0, filePath || '', md5 || '', req.user?.username || 'admin');
  res.json({ id, message: '文件登记成功' });
});

// DELETE /api/files/:id — 删除文件记录
router.delete('/:id', (req, res) => {
  const db = req.app.locals.db;
  const file = db.prepare('SELECT * FROM managed_files WHERE id = ?').get(req.params.id);
  if (!file) return res.status(404).json({ error: '文件不存在' });
  db.prepare('DELETE FROM managed_files WHERE id = ?').run(req.params.id);
  res.json({ message: '文件删除成功' });
});

// PUT /api/files/:id — 更新文件信息
router.put('/:id', (req, res) => {
  const db = req.app.locals.db;
  const fields = req.body;
  const allowed = ['name', 'type', 'category', 'status'];
  const sets = [], vals = [];
  for (const k of allowed) {
    if (fields[k] !== undefined) { sets.push(`${k} = ?`); vals.push(fields[k]); }
  }
  if (!sets.length) return res.status(400).json({ error: '无更新字段' });
  db.prepare(`UPDATE managed_files SET ${sets.join(', ')} WHERE id = ?`).run(...vals, req.params.id);
  res.json({ message: '更新成功' });
});

module.exports = router;
