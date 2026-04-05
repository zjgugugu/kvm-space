// Cockpit 存储维护 API
// 对应真实Cockpit的 maintain 模块
var express = require('express');
var router = express.Router();

// ===== 脑裂恢复 =====
router.get('/recovery/status', function (req, res) {
  res.json({ data: { has_split_brain: false, files: [] } });
});

router.post('/recovery/scan', function (req, res) {
  res.json({ success: true, message: '扫描完成', files: [] });
});

router.post('/recovery/heal', function (req, res) {
  res.json({ success: true, message: '修复完成（模拟）' });
});

// ===== 备份管理 =====
router.get('/backups', function (req, res) {
  var db = req.app.locals.db;
  var tasks = db.prepare("SELECT * FROM cockpit_maintain_tasks WHERE type = 'backup' ORDER BY created_at DESC").all();
  res.json({ data: tasks });
});

router.post('/backups', function (req, res) {
  var db = req.app.locals.db;
  var { v4: uuidv4 } = require('uuid');
  db.prepare("INSERT INTO cockpit_maintain_tasks (type, status, progress, message) VALUES ('backup', 'completed', 100, '备份完成（模拟）')").run();
  res.json({ success: true, message: '备份任务已创建' });
});

router.delete('/backups/:id', function (req, res) {
  var db = req.app.locals.db;
  db.prepare('DELETE FROM cockpit_maintain_tasks WHERE id = ?').run(parseInt(req.params.id));
  res.json({ success: true });
});

// ===== 日志记录 =====
router.get('/logs', function (req, res) {
  var db = req.app.locals.db;
  var logs = db.prepare('SELECT * FROM cockpit_maintain_logs ORDER BY created_at DESC LIMIT 100').all();
  res.json({ data: logs });
});

// ===== 网络监测 =====
router.get('/network-detect', function (req, res) {
  var db = req.app.locals.db;
  var nodes = db.prepare('SELECT ip, name FROM cockpit_nodes').all();
  var results = nodes.map(function (n) {
    return { ip: n.ip, hostname: n.name, reachable: true, latency: Math.floor(Math.random() * 5) + 1 };
  });
  res.json({ data: results });
});

router.post('/network-detect', function (req, res) {
  var { target_ip } = req.body;
  if (!target_ip) return res.status(400).json({ error: '请输入目标IP' });
  try {
    var { execSync } = require('child_process');
    var output = execSync('ping -c 3 -W 3 ' + target_ip, { encoding: 'utf8', timeout: 10000 });
    var match = output.match(/time=(\d+\.?\d*)/);
    res.json({ reachable: true, latency: match ? parseFloat(match[1]) : 0, output: output });
  } catch (e) {
    res.json({ reachable: false, latency: 0, output: e.message });
  }
});

// ===== 任务列表 =====
router.get('/tasks', function (req, res) {
  var db = req.app.locals.db;
  var tasks = db.prepare("SELECT * FROM cockpit_maintain_tasks WHERE status != 'completed' ORDER BY created_at DESC").all();
  res.json({ data: tasks });
});

module.exports = router;
