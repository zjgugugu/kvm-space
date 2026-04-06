// Cockpit 总控虚拟化界面 - 主服务
var express = require('express');
var cors = require('cors');
var path = require('path');
var fs = require('fs');
var https = require('https');
var { execSync } = require('child_process');
var { openDatabase } = require('../../../server/src/db/sqlite-wrapper');
var { initSchema, initDefaultData } = require('./schema');
var { router: authRoutes, authMiddleware } = require('./routes/auth');
var clusterRoutes = require('./routes/cluster');
var configRoutes = require('./routes/config');
var maintainRoutes = require('./routes/maintain');

var PORT = parseInt(process.env.COCKPIT_PORT) || 9091;

async function main() {
  // 初始化数据库
  var dbPath = path.join(__dirname, '..', 'data', 'cockpit.db');
  var db = await openDatabase(dbPath);
  initSchema(db);
  initDefaultData(db);
  console.log('[Cockpit] 数据库初始化完成');

  // 自动发现本机信息
  autoDetectHost(db);

  var app = express();
  app.use(cors());
  app.use(express.json());
  app.locals.db = db;

  // API 路由
  app.use('/api/auth', authMiddleware, authRoutes);
  app.use('/api/cluster', authMiddleware, clusterRoutes);
  app.use('/api/config', authMiddleware, configRoutes);
  app.use('/api/maintain', authMiddleware, maintainRoutes);

  // 系统信息（无需认证）
  app.get('/api/info', function (req, res) {
    try {
      var hostname = execSync('hostname', { encoding: 'utf8', timeout: 3000 }).trim();
      var ip = getManagementIP();
      var os = '';
      try { os = execSync('cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d \'"\'', { encoding: 'utf8', timeout: 3000 }).trim(); } catch (e) {}
      var cpuModel = '';
      try { cpuModel = execSync("lscpu | grep -E 'Model name|型号名称' | sed 's/.*：\\s*//' | sed 's/.*:\\s*//'", { encoding: 'utf8', timeout: 3000 }).trim(); } catch (e) {}
      var cpuCount = 0;
      try { cpuCount = parseInt(execSync('nproc', { encoding: 'utf8', timeout: 3000 }).trim()); } catch (e) {}
      var memTotal = 0;
      try { memTotal = parseInt(execSync("free -m | awk '/Mem:/ {print $2}'", { encoding: 'utf8', timeout: 3000 }).trim()); } catch (e) {}
      res.json({
        hostname: hostname, ip: ip, os: os, cpu_model: cpuModel,
        cpu_count: cpuCount, mem_total_mb: memTotal,
        version: '1.0.0', name: '总控虚拟化界面'
      });
    } catch (e) {
      res.json({ hostname: '', ip: '', os: '', version: '1.0.0', name: '总控虚拟化界面' });
    }
  });

  // 静态文件（前端）
  var distDir = path.join(__dirname, '..', '..', 'web');
  app.use(express.static(distDir));

  // SPA 回退
  app.get('*', function (req, res) {
    res.sendFile(path.join(distDir, 'index.html'));
  });

  // HTTPS or HTTP
  var certDir = path.join(__dirname, '..', '..', '..', 'certs');
  var keyPath = path.join(certDir, 'server.key');
  var crtPath = path.join(certDir, 'server.crt');

  if (fs.existsSync(keyPath) && fs.existsSync(crtPath)) {
    var sslOptions = {
      key: fs.readFileSync(keyPath),
      cert: fs.readFileSync(crtPath)
    };
    https.createServer(sslOptions, app).listen(PORT, '0.0.0.0', function () {
      console.log('[Cockpit] 总控虚拟化界面启动于 https://0.0.0.0:' + PORT);
    });
  } else {
    app.listen(PORT, '0.0.0.0', function () {
      console.log('[Cockpit] 总控虚拟化界面启动于 http://0.0.0.0:' + PORT + ' (无SSL证书)');
    });
  }
}

// 获取管理网络IP（优先10.126.x.x等非内部地址）
function getManagementIP() {
  try {
    var allIPs = execSync('hostname -I', { encoding: 'utf8', timeout: 3000 }).trim().split(/\s+/);
    // 优先选择非 10.0.x.x / 172.17.x.x (docker) 的管理IP
    var mgmtIP = allIPs.find(function (ip) {
      return ip && !ip.startsWith('10.0.') && !ip.startsWith('172.17.') && !ip.startsWith('127.');
    });
    return mgmtIP || allIPs[0] || '';
  } catch (e) {
    return '';
  }
}

function autoDetectHost(db) {
  try {
    // 如果已有节点数据（种子数据），不再自动添加
    var nodeCount = db.prepare('SELECT COUNT(*) as cnt FROM cockpit_nodes').get();
    if (nodeCount.cnt > 0) return;

    var hostname = execSync('hostname', { encoding: 'utf8', timeout: 3000 }).trim();
    var ip = getManagementIP();
    if (!ip) return;
    db.prepare('INSERT INTO cockpit_nodes (name, ip, role, status, is_docker_node) VALUES (?,?,?,?,?)')
      .run(hostname, ip, 'CM_VDI', 'active', 1);
    db.prepare('UPDATE cockpit_deploy_status SET status = 1').run();
    console.log('[Cockpit] 自动添加本机: ' + hostname + ' (' + ip + ')');
  } catch (e) {
    console.log('[Cockpit] 自动发现失败:', e.message);
  }
}

main().catch(function (err) {
  console.error('[Cockpit] 启动失败:', err);
  process.exit(1);
});
