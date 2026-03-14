// 备份管理 API（备份服务器 + 备份任务）
const express = require('express');
const router = express.Router();

// ===== 备份服务器 =====
router.get('/servers', async (req, res) => {
  try {
    const servers = await req.app.locals.driver.listBackupServers();
    res.json({ data: servers, total: servers.length });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/servers', async (req, res) => {
  try {
    const server = await req.app.locals.driver.addBackupServer(req.body);
    res.status(201).json(server);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

router.put('/servers/:id', async (req, res) => {
  try {
    const server = await req.app.locals.driver.editBackupServer(req.params.id, req.body);
    res.json(server);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

router.delete('/servers/:id', async (req, res) => {
  try {
    const result = await req.app.locals.driver.deleteBackupServer(req.params.id);
    res.json(result);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// ===== 备份任务 =====
router.get('/', async (req, res) => {
  try {
    const backups = await req.app.locals.driver.listBackups();
    let data = backups;
    if (req.query.vm_id) data = data.filter(b => b.vm_id === req.query.vm_id);
    if (req.query.status) data = data.filter(b => b.status === req.query.status);
    res.json({ data, total: data.length });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/', async (req, res) => {
  try {
    const backup = await req.app.locals.driver.createBackup(req.body);
    res.status(201).json(backup);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

router.post('/:id/restore', async (req, res) => {
  try {
    const result = await req.app.locals.driver.restoreBackup(req.params.id);
    res.json(result);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

router.delete('/:id', async (req, res) => {
  try {
    const result = await req.app.locals.driver.deleteBackup(req.params.id);
    res.json(result);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

module.exports = router;
