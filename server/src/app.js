const express = require('express');
const cors = require('cors');
const path = require('path');
const zlib = require('zlib');
const { openDatabase } = require('./db/sqlite-wrapper');
const { initSchema, initDefaultData } = require('./db/schema');
const MockDriver = require('./virt/mock-driver');
const LibvirtDriver = require('./virt/libvirt-driver');
const { router: authRoutes, authMiddleware } = require('./routes/auth');
const dashboardRoutes = require('./routes/dashboard');
const vmRoutes = require('./routes/vms');
const hostRoutes = require('./routes/hosts');
const templateRoutes = require('./routes/templates');
const networkRoutes = require('./routes/networks');
const storageRoutes = require('./routes/storage');
const userRoutes = require('./routes/users');
const eventRoutes = require('./routes/events');
const specRoutes = require('./routes/specs');
const publishRuleRoutes = require('./routes/publish-rules');
const backupRoutes = require('./routes/backups');
const alertRoutes = require('./routes/alerts');
const systemRoutes = require('./routes/system');
const snapshotPolicyRoutes = require('./routes/snapshot-policies');
const statsRoutes = require('./routes/stats');

const MODE = process.env.KVM_MODE || 'mock';
const PORT = parseInt(process.env.PORT) || 3000;

async function main() {
  // 初始化数据库（sql.js 需要异步加载 WASM）
  const dbPath = path.join(__dirname, '..', 'data', 'kvm-cloud.db');
  const db = await openDatabase(dbPath);
  initSchema(db);
  initDefaultData(db);
  console.log('[启动] 数据库初始化完成');

  // 初始化虚拟化驱动
  let driver;
  if (MODE === 'libvirt') {
    driver = new LibvirtDriver(db);
    await driver.init();
    console.log('[启动] 模式: libvirt (真实 KVM/libvirt)');
  } else if (MODE === 'mock') {
    driver = new MockDriver(db);
    driver.init();
    console.log('[启动] 模式: mock (模拟数据)');
  } else {
    driver = new MockDriver(db);
    driver.init();
    console.log(`[启动] 模式: ${MODE} (暂未实现，回退 mock)`);
  }

  const app = express();

  app.use(cors());
  app.use(express.json());

  // 挂载公共对象
  app.locals.db = db;
  app.locals.driver = driver;
  app.locals.mode = MODE;

  // Gzip 压缩 - 为静态资源提供压缩传输
  const distDir = path.join(__dirname, '..', '..', 'web', 'dist');
  const gzCache = {};
  app.use((req, res, next) => {
    if (!req.path.match(/\.(js|css|html)$/) || req.path.includes('..')) return next();
    const ae = req.headers['accept-encoding'] || '';
    if (!ae.includes('gzip')) return next();
    const filePath = path.resolve(distDir, '.' + req.path);
    if (!filePath.startsWith(path.resolve(distDir))) return next();
    const fs = require('fs');
    if (!fs.existsSync(filePath)) return next();
    if (gzCache[filePath]) {
      const types = { '.js': 'application/javascript; charset=utf-8', '.css': 'text/css; charset=utf-8', '.html': 'text/html; charset=utf-8' };
      res.setHeader('Content-Type', types[path.extname(req.path)] || 'application/octet-stream');
      res.setHeader('Content-Encoding', 'gzip');
      res.setHeader('Vary', 'Accept-Encoding');
      return res.end(gzCache[filePath]);
    }
    const raw = fs.readFileSync(filePath);
    zlib.gzip(raw, (err, compressed) => {
      if (err) return next();
      gzCache[filePath] = compressed;
      const types = { '.js': 'application/javascript; charset=utf-8', '.css': 'text/css; charset=utf-8', '.html': 'text/html; charset=utf-8' };
      res.setHeader('Content-Type', types[path.extname(req.path)] || 'application/octet-stream');
      res.setHeader('Content-Encoding', 'gzip');
      res.setHeader('Vary', 'Accept-Encoding');
      res.end(compressed);
    });
  });

  // 静态文件（前端构建输出）
  app.use(express.static(distDir));

  // API 路由
  app.use('/api/auth', authRoutes);
  app.use('/api/dashboard', authMiddleware, dashboardRoutes);
  app.use('/api/vms', authMiddleware, vmRoutes);
  app.use('/api/hosts', authMiddleware, hostRoutes);
  app.use('/api/templates', authMiddleware, templateRoutes);
  app.use('/api/networks', authMiddleware, networkRoutes);
  app.use('/api/storage', authMiddleware, storageRoutes);
  app.use('/api/users', authMiddleware, userRoutes);
  app.use('/api/events', authMiddleware, eventRoutes);
  app.use('/api/specs', authMiddleware, specRoutes);
  app.use('/api/publish-rules', authMiddleware, publishRuleRoutes);
  app.use('/api/backups', authMiddleware, backupRoutes);
  app.use('/api/alerts', authMiddleware, alertRoutes);
  app.use('/api/system', authMiddleware, systemRoutes);
  app.use('/api/snapshot-policies', authMiddleware, snapshotPolicyRoutes);
  app.use('/api/stats', authMiddleware, statsRoutes);

  // 模式信息（无需认证）
  app.get('/api/info', (req, res) => {
    res.json({ mode: MODE, version: '0.2.2', name: 'KVM Cloud 虚拟化管理平台' });
  });

  // SPA 回退
  app.get('*', (req, res) => {
    const indexPath = path.join(distDir, 'index.html');
    const fs = require('fs');
    if (fs.existsSync(indexPath)) {
      res.sendFile(indexPath);
    } else {
      res.json({ message: 'KVM Cloud API 服务运行中', mode: MODE, docs: '/api/info' });
    }
  });

  app.listen(PORT, () => {
    console.log(`[KVM Cloud] 服务启动于 http://localhost:${PORT}`);
    console.log(`[KVM Cloud] 运行模式: ${MODE}`);
  });
}

main().catch(err => {
  console.error('[启动失败]', err);
  process.exit(1);
});
