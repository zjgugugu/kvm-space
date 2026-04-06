const express = require('express');
const router = express.Router();
const { v4: uuidv4 } = require('uuid');

// GET /api/desktop-pools — 列表
router.get('/', async (req, res) => {
  const db = req.app.locals.db;
  const rows = db.prepare('SELECT * FROM desktop_pools ORDER BY created_at DESC').all();
  res.json({ data: rows, total: rows.length });
});

// GET /api/desktop-pools/:id — 详情
router.get('/:id', async (req, res) => {
  const db = req.app.locals.db;
  const row = db.prepare('SELECT * FROM desktop_pools WHERE id = ?').get(req.params.id);
  if (!row) return res.status(404).json({ error: '桌面池不存在' });
  res.json(row);
});

// POST /api/desktop-pools — 创建
router.post('/', async (req, res) => {
  const db = req.app.locals.db;
  const id = uuidv4();
  const { name, type, template_id, spec_id, min_count, max_count, spare_count, prefix, description } = req.body;
  db.prepare('INSERT INTO desktop_pools (id, name, type, template_id, spec_id, min_count, max_count, spare_count, prefix, description) VALUES (?,?,?,?,?,?,?,?,?,?)')
    .run(id, name, type || 'dynamic', template_id || '', spec_id || '', min_count || 0, max_count || 10, spare_count || 2, prefix || 'pool-', description || '');
  res.json({ id, message: '桌面池创建成功' });
});

// PUT /api/desktop-pools/:id — 更新
router.put('/:id', async (req, res) => {
  const db = req.app.locals.db;
  const fields = req.body;
  const sets = Object.keys(fields).map(k => `${k} = ?`).join(', ');
  if (!sets) return res.status(400).json({ error: '无更新字段' });
  db.prepare(`UPDATE desktop_pools SET ${sets} WHERE id = ?`).run(...Object.values(fields), req.params.id);
  res.json({ message: '更新成功' });
});

// DELETE /api/desktop-pools/:id — 删除
router.delete('/:id', async (req, res) => {
  const db = req.app.locals.db;
  db.prepare('DELETE FROM desktop_pools WHERE id = ?').run(req.params.id);
  res.json({ message: '删除成功' });
});

module.exports = router;
