// 平台统计 API（供报表页面使用）
const express = require('express');
const router = express.Router();

// GET /api/stats — 返回平台概览统计数据
router.get('/', async (req, res) => {
  try {
    const overview = await req.app.locals.driver.getDashboardOverview();
    res.json({
      cpu_usage: overview.cluster.cpu.usage,
      mem_usage: overview.cluster.memory.usage,
      storage_usage: overview.cluster.storage.usage,
      hosts_total: overview.hosts.total,
      hosts_online: overview.hosts.online,
      vms_total: overview.vms.total,
      vms_running: overview.vms.running,
      users_total: overview.users.total,
      alerts_active: overview.alerts.active,
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
