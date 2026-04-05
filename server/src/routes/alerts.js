// 告警管理 API
const express = require('express');
const router = express.Router();

// 告警列表
router.get('/', async (req, res) => {
  try {
    const alerts = await req.app.locals.driver.listAlerts();
    let data = alerts;
    if (req.query.level) data = data.filter(a => a.level === req.query.level);
    if (req.query.status) data = data.filter(a => a.status === req.query.status);
    res.json({ data, total: data.length });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// ===== 告警设置（放在 /:id 之前避免路由冲突） =====
router.get('/settings', async (req, res) => {
  try {
    const settings = await req.app.locals.driver.listAlertSettings();
    res.json({ data: settings, total: settings.length });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/settings', async (req, res) => {
  try {
    const setting = await req.app.locals.driver.createAlertSetting(req.body);
    res.json(setting);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

router.put('/settings/:id', async (req, res) => {
  try {
    const setting = await req.app.locals.driver.updateAlertSetting(req.params.id, req.body);
    res.json(setting);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

router.delete('/settings/:id', async (req, res) => {
  try {
    const result = await req.app.locals.driver.deleteAlertSetting(req.params.id);
    res.json(result);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// 确认告警
router.post('/:id/acknowledge', async (req, res) => {
  try {
    const result = await req.app.locals.driver.acknowledgeAlert(req.params.id);
    res.json(result);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// 解决告警
router.post('/:id/resolve', async (req, res) => {
  try {
    const result = await req.app.locals.driver.resolveAlert(req.params.id);
    res.json(result);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

module.exports = router;
