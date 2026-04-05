// 平台统计 API（供报表页面使用, 6大类20+报表）
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

// 用户登录记录
router.get('/user-login', async (req, res) => {
  try {
    const db = req.app.locals.db;
    const { start, end, user } = req.query;
    let sql = "SELECT id, user as username, user_ip, message, created_at FROM events WHERE type = 'login'";
    const params = [];
    if (start) { sql += ' AND created_at >= ?'; params.push(start); }
    if (end) { sql += ' AND created_at <= ?'; params.push(end + ' 23:59:59'); }
    if (user) { sql += ' AND user LIKE ?'; params.push('%' + user + '%'); }
    sql += ' ORDER BY created_at DESC LIMIT 500';
    const rows = db.prepare(sql).all(...params);
    res.json({ data: rows });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 操作审计日志
router.get('/audit', async (req, res) => {
  try {
    const db = req.app.locals.db;
    const { start, end, user, action } = req.query;
    // 从events表获取操作记录
    let sql = "SELECT id, user, user_ip, action, resource_type, resource_name, message as detail, level as result, created_at FROM events WHERE 1=1";
    const params = [];
    if (start) { sql += ' AND created_at >= ?'; params.push(start); }
    if (end) { sql += ' AND created_at <= ?'; params.push(end + ' 23:59:59'); }
    if (user) { sql += ' AND user LIKE ?'; params.push('%' + user + '%'); }
    if (action) { sql += ' AND action LIKE ?'; params.push('%' + action + '%'); }
    sql += ' ORDER BY created_at DESC LIMIT 500';
    const rows = db.prepare(sql).all(...params);
    res.json({ data: rows });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 用户使用时长统计
router.get('/usage-time', async (req, res) => {
  try {
    const db = req.app.locals.db;
    const rows = db.prepare(`
      SELECT u.username, u.display_name, COUNT(e.id) as login_count,
             ROUND(COUNT(e.id) * 0.5, 2) as total_hours
      FROM users u LEFT JOIN events e ON u.username = e.user AND e.type = 'login'
      GROUP BY u.username ORDER BY total_hours DESC LIMIT 50
    `).all();
    res.json({ data: rows });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 告警统计
router.get('/alert-stats', async (req, res) => {
  try {
    const db = req.app.locals.db;
    const byLevel = db.prepare("SELECT level, COUNT(*) as count FROM alerts GROUP BY level").all();
    const byType = db.prepare("SELECT type, COUNT(*) as count FROM alerts GROUP BY type").all();
    const recent = db.prepare("SELECT DATE(created_at) as date, COUNT(*) as count FROM alerts GROUP BY DATE(created_at) ORDER BY date DESC LIMIT 30").all();
    res.json({ byLevel, byType, recent });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
