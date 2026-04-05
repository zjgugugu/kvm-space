// Cockpit 高级配置 API
// 对应真实Cockpit的 advanced_config.sh 调用
var express = require('express');
var router = express.Router();

// 获取NTP配置
router.get('/ntp', function (req, res) {
  var db = req.app.locals.db;
  var ntp = db.prepare('SELECT * FROM cockpit_time_server ORDER BY id DESC LIMIT 1').get();
  res.json({ data: ntp || { server: '0', time_update_interval: 5 } });
});

// 更新NTP配置
router.put('/ntp', function (req, res) {
  var db = req.app.locals.db;
  var { server, time_update_interval } = req.body;
  db.exec('DELETE FROM cockpit_time_server');
  db.prepare('INSERT INTO cockpit_time_server (server, time_update_interval) VALUES (?,?)').run(server || '0', time_update_interval || 5);
  res.json({ success: true });
});

// 获取NFS配置
router.get('/nfs', function (req, res) {
  var db = req.app.locals.db;
  var nfs = db.prepare('SELECT * FROM cockpit_nfs_storage_info LIMIT 1').get();
  res.json({ data: nfs || {} });
});

// 更新NFS配置
router.put('/nfs', function (req, res) {
  var db = req.app.locals.db;
  var { ip, share_dir, version } = req.body;
  if (!ip || !share_dir) return res.status(400).json({ error: '缺少必填字段' });
  db.exec('DELETE FROM cockpit_nfs_storage_info');
  db.prepare('INSERT INTO cockpit_nfs_storage_info (ip, share_dir, version) VALUES (?,?,?)').run(ip, share_dir, version || '4');
  res.json({ success: true });
});

// 获取CIFS配置
router.get('/cifs', function (req, res) {
  var db = req.app.locals.db;
  var cifs = db.prepare('SELECT * FROM cockpit_cifs_storage_info LIMIT 1').get();
  if (cifs) cifs.password = '******';
  res.json({ data: cifs || {} });
});

// 更新CIFS配置
router.put('/cifs', function (req, res) {
  var db = req.app.locals.db;
  var { ip, share_dir, user_name, password, domain, version } = req.body;
  if (!ip || !share_dir || !user_name) return res.status(400).json({ error: '缺少必填字段' });
  db.exec('DELETE FROM cockpit_cifs_storage_info');
  db.prepare('INSERT INTO cockpit_cifs_storage_info (ip, share_dir, user_name, password, domain, version) VALUES (?,?,?,?,?,?)')
    .run(ip, share_dir, user_name, password || '', domain || '', version || '2.0');
  res.json({ success: true });
});

// 获取集中存储服务器配置
router.get('/center-cluster', function (req, res) {
  var db = req.app.locals.db;
  var info = db.prepare('SELECT * FROM cockpit_center_cluster_info LIMIT 1').get();
  if (info) info.password = '******';
  res.json({ data: info || {} });
});

// 更新集中存储服务器配置
router.put('/center-cluster', function (req, res) {
  var db = req.app.locals.db;
  var { ip, user_name, password, data_sync_time } = req.body;
  if (!ip || !user_name) return res.status(400).json({ error: '缺少必填字段' });
  db.exec('DELETE FROM cockpit_center_cluster_info');
  db.prepare('INSERT INTO cockpit_center_cluster_info (ip, user_name, password, data_sync_time) VALUES (?,?,?,?)')
    .run(ip, user_name, password || '', data_sync_time || '00:00');
  res.json({ success: true });
});

// 更新角色
router.put('/roles', function (req, res) {
  var db = req.app.locals.db;
  var { updates } = req.body;
  if (!updates || !Array.isArray(updates)) return res.status(400).json({ error: '无效参数' });
  updates.forEach(function (u) {
    db.prepare('UPDATE cockpit_nodes SET role = ? WHERE id = ?').run(u.role, u.id);
  });
  res.json({ success: true });
});

// 获取管理网络配置
router.get('/network', function (req, res) {
  try {
    var { execSync } = require('child_process');
    var ip = execSync("hostname -I | awk '{print $1}'", { encoding: 'utf8', timeout: 3000 }).trim();
    var gw = execSync("ip route | grep default | awk '{print $3}'", { encoding: 'utf8', timeout: 3000 }).trim();
    var mask = execSync("ip -o -4 addr show scope global | head -1 | awk '{print $4}' | cut -d/ -f2", { encoding: 'utf8', timeout: 3000 }).trim();
    var hostname = execSync('hostname', { encoding: 'utf8', timeout: 3000 }).trim();
    res.json({ data: { ip: ip, gateway: gw, mask: mask, hostname: hostname } });
  } catch (e) {
    res.json({ data: { ip: '0.0.0.0', gateway: '', mask: '24', hostname: '' } });
  }
});

// 更新虚拟存储位置
router.put('/virtual-storage', function (req, res) {
  res.json({ success: true, message: '虚拟存储位置已更新（模拟）' });
});

module.exports = router;
