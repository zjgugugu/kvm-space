// 仪表盘 API
const express = require('express');
const router = express.Router();

// 仪表盘概览（调用 driver 统一方法）
router.get('/overview', async (req, res) => {
  try {
    const overview = await req.app.locals.driver.getDashboardOverview();
    res.json(overview);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
