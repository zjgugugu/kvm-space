// 系统配置管理 API
const express = require('express');
const router = express.Router();

// 获取系统配置列表(支持category过滤)
router.get('/config', async (req, res) => {
  try {
    const config = await req.app.locals.driver.getSysConfig();
    res.json({ data: config });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 获取全局策略列表
router.get('/policies', async (req, res) => {
  try {
    const db = req.app.locals.db;
    const policies = db.prepare('SELECT key, value, description, category FROM sys_config ORDER BY key').all();
    res.json({ data: policies });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 批量更新策略
router.put('/policies', async (req, res) => {
  try {
    const db = req.app.locals.db;
    const updates = req.body;
    const stmt = db.prepare('INSERT OR REPLACE INTO sys_config (key, value, description, category, updated_at) VALUES (?, ?, COALESCE((SELECT description FROM sys_config WHERE key = ?), ?), COALESCE((SELECT category FROM sys_config WHERE key = ?), ?), datetime(\'now\'))');
    const tx = db.transaction(() => {
      for (const [key, value] of Object.entries(updates)) {
        stmt.run(key, String(value), key, '', key, 'general');
      }
    });
    tx();
    res.json({ success: true });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// 更新单个系统配置
router.put('/config/:key', async (req, res) => {
  try {
    const result = await req.app.locals.driver.updateSysConfig(req.params.key, req.body.value);
    res.json(result);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// ===== 密码策略 =====
router.get('/password-policy', async (req, res) => {
  try {
    const data = await req.app.locals.driver.getSettingGroup('password_policy');
    res.json({ data });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

router.put('/password-policy', async (req, res) => {
  try {
    const result = await req.app.locals.driver.saveSettingGroup('password_policy', req.body);
    res.json({ data: result });
  } catch (err) { res.status(400).json({ error: err.message }); }
});

// ===== 访问策略 =====
router.get('/access-policy', async (req, res) => {
  try {
    const data = await req.app.locals.driver.getSettingGroup('access_policy');
    res.json({ data });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

router.put('/access-policy', async (req, res) => {
  try {
    const result = await req.app.locals.driver.saveSettingGroup('access_policy', req.body);
    res.json({ data: result });
  } catch (err) { res.status(400).json({ error: err.message }); }
});

// ===== SMTP 配置 =====
router.get('/smtp', async (req, res) => {
  try {
    const data = await req.app.locals.driver.getSettingGroup('smtp');
    res.json({ data });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

router.put('/smtp', async (req, res) => {
  try {
    const result = await req.app.locals.driver.saveSettingGroup('smtp', req.body);
    res.json({ data: result });
  } catch (err) { res.status(400).json({ error: err.message }); }
});

router.post('/smtp/test', async (req, res) => {
  // 模拟发送测试邮件（无真实SMTP连接）
  res.json({ success: true, message: '测试邮件已发送（模拟）' });
});

// ===== 通知配置 =====
router.get('/notify-config', async (req, res) => {
  try {
    const data = await req.app.locals.driver.getSettingGroup('notify');
    res.json({ data });
  } catch (err) { res.status(500).json({ error: err.message }); }
});

router.put('/notify-config', async (req, res) => {
  try {
    const result = await req.app.locals.driver.saveSettingGroup('notify', req.body);
    res.json({ data: result });
  } catch (err) { res.status(400).json({ error: err.message }); }
});

module.exports = router;
