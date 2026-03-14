// 系统配置管理 API
const express = require('express');
const router = express.Router();

// 获取系统配置列表
router.get('/config', async (req, res) => {
  try {
    const config = await req.app.locals.driver.getSysConfig();
    res.json({ data: config });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 更新系统配置
router.put('/config/:key', async (req, res) => {
  try {
    const result = await req.app.locals.driver.updateSysConfig(req.params.key, req.body.value);
    res.json(result);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

module.exports = router;
