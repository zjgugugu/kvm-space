// 主机/集群管理 API
const express = require('express');
const router = express.Router();

// ===== 集群管理 (must be before /:id) =====
router.get('/clusters/list', (req, res) => {
  const db = req.app.locals.db;
  const clusters = db.prepare('SELECT * FROM clusters ORDER BY created_at DESC').all();
  res.json({ data: clusters, total: clusters.length });
});

router.post('/clusters', (req, res) => {
  const db = req.app.locals.db;
  const { v4: uuidv4 } = require('uuid');
  const id = uuidv4();
  const { name, description } = req.body;
  if (!name) return res.status(400).json({ error: '集群名称不能为空' });
  db.prepare('INSERT INTO clusters (id, name, description) VALUES (?,?,?)').run(id, name, description || '');
  res.status(201).json(db.prepare('SELECT * FROM clusters WHERE id = ?').get(id));
});

router.put('/clusters/:id', (req, res) => {
  const db = req.app.locals.db;
  const cluster = db.prepare('SELECT * FROM clusters WHERE id = ?').get(req.params.id);
  if (!cluster) return res.status(404).json({ error: '集群不存在' });
  const { name, description } = req.body;
  if (name) db.prepare('UPDATE clusters SET name = ?, description = ? WHERE id = ?').run(name, description || cluster.description, req.params.id);
  res.json(db.prepare('SELECT * FROM clusters WHERE id = ?').get(req.params.id));
});

router.delete('/clusters/:id', (req, res) => {
  const db = req.app.locals.db;
  const cluster = db.prepare('SELECT * FROM clusters WHERE id = ?').get(req.params.id);
  if (!cluster) return res.status(404).json({ error: '集群不存在' });
  db.prepare('DELETE FROM clusters WHERE id = ?').run(req.params.id);
  db.prepare('UPDATE hosts SET cluster_id = NULL WHERE cluster_id = ?').run(req.params.id);
  res.json({ success: true });
});

// ===== 主机管理 =====
// 主机列表
router.get('/', async (req, res) => {
  try {
    const hosts = await req.app.locals.driver.listHosts();
    res.json({ data: hosts, total: hosts.length });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 主机详情（附带VM列表）
router.get('/:id', async (req, res) => {
  try {
    const host = await req.app.locals.driver.getHost(req.params.id);
    if (!host) return res.status(404).json({ error: '主机不存在' });
    const db = req.app.locals.db;
    host.vms = db.prepare('SELECT id, name, status, cpu, memory, ip, owner FROM vms WHERE host_id = ? AND deleted = 0').all(req.params.id);
    res.json(host);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 添加主机
router.post('/', async (req, res) => {
  try {
    const host = await req.app.locals.driver.addHost(req.body);
    res.status(201).json(host);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// 移除主机
router.delete('/:id', async (req, res) => {
  try {
    const result = await req.app.locals.driver.removeHost(req.params.id);
    res.json(result);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// 主机操作（重启/关机）
router.post('/:id/action', async (req, res) => {
  try {
    const { action } = req.body;
    const driver = req.app.locals.driver;
    let result;
    switch (action) {
      case 'reboot': result = await driver.rebootHost(req.params.id); break;
      case 'shutdown': result = await driver.shutdownHost(req.params.id); break;
      default: return res.status(400).json({ error: `未知操作: ${action}` });
    }
    res.json(result);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// 修改主机配置
router.put('/:id', async (req, res) => {
  try {
    const host = await req.app.locals.driver.updateHostConfig(req.params.id, req.body);
    res.json(host);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// 主机性能监控
router.get('/:id/stats', async (req, res) => {
  try {
    const stats = await req.app.locals.driver.getHostStats(req.params.id);
    res.json(stats);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
