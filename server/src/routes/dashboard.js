// 仪表盘 API (对标KSVD V7 Dashboard 7大卡片 - KSVD兼容格式)
const express = require('express');
const router = express.Router();

// 仪表盘概览 (KSVD格式: vm/server/cpu/mem/storage/systemType)
router.get('/overview', async (req, res) => {
  try {
    const d = await req.app.locals.driver.getDashboardOverview();
    const vms = d.vms || {};
    const hosts = d.hosts || {};
    const cluster = d.cluster || {};
    const cpu = cluster.cpu || {};
    const mem = cluster.memory || {};
    const sto = cluster.storage || {};

    let storageList = [];
    try {
      const pools = req.app.locals.db.prepare('SELECT * FROM storage_pools').all();
      storageList = pools.map((p, i) => ({
        id: i + 1, name: p.name, state: p.status || 'online',
        totalSize: +(p.total || 0).toFixed(1),
        usedSize: +(p.used || 0).toFixed(1),
        type: { name: 'LOCAL' }, usage: { name: 'DATA' }, status: { name: 'NORMAL' }
      }));
    } catch(e) {}

    res.json({
      vm: {
        connected: vms.running || 0,
        disConnected: (vms.stopped || 0) + (vms.suspended || 0),
        total: vms.total || 0,
        isRunning: 0, unRun: 0, servertotal: 0
      },
      server: { online: hosts.online || 0, offline: hosts.offline || 0 },
      cpu: { used: +(cpu.used || 0), total: +(cpu.total || 0) },
      mem: { used: +((mem.used || 0) / 1024).toFixed(2), total: +((mem.total || 0) / 1024).toFixed(2) },
      storage: { used: Math.round(sto.used || 0), total: Math.round(sto.total || 0), storageList },
      systemType: { normal: 0, vde: 0, tc: 0 }
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 在线趋势图 (KSVD格式: chart.lines[].lineQuery.dataType.name + values[[ts,val]])
router.get('/trends', async (req, res) => {
  try {
    const granularity = (req.query.granularity || 'minute').toUpperCase();
    const numPoints = parseInt(req.query.numDataPoints) || 12;
    const now = Date.now();

    let baseDesktop = 0, baseServer = 1;
    try {
      const overview = await req.app.locals.driver.getDashboardOverview();
      baseDesktop = overview.vms?.running || 0;
      baseServer = overview.hosts?.online || 1;
    } catch(e) {}

    const intervals = { MINUTE: 60000, HOUR: 3600000, DAY: 86400000 };
    const interval = intervals[granularity] || intervals.MINUTE;

    function genLine(dataType, baseFn) {
      const values = [];
      for (let i = numPoints - 1; i >= 0; i--) {
        const ts = now - i * interval;
        values.push([ts, baseFn(new Date(ts))]);
      }
      return {
        lineQuery: { dataType: { name: dataType }, computationType: { name: 'CLUSTER_TOTAL' }, sampleType: { name: 'PEAK' } },
        values
      };
    }

    const timeFactor = (t) => {
      const h = t.getHours();
      return (h >= 8 && h <= 18 ? 1.0 : h >= 6 && h <= 20 ? 0.6 : 0.2) * (0.9 + Math.random() * 0.2);
    };

    const lines = [
      genLine('ONLINE_USER_COUNT', t => Math.max(0, Math.round(baseDesktop * timeFactor(t) * 0.8))),
      genLine('ONLINE_CLINET_COUNT', t => Math.max(0, Math.round(baseDesktop * timeFactor(t) * 0.3))),
      genLine('SESSION_COUNT', t => Math.max(0, Math.round(baseDesktop * timeFactor(t) * 1.2))),
      genLine('SERVER_VIRTUAL_SESSION_COUNT', () => baseServer),
      genLine('CONNECTED_SESSION_COUNT', t => Math.max(0, Math.round(baseDesktop * timeFactor(t)))),
    ];

    res.json({
      chart: { lines },
      granularityMap: { MINUTE: '分钟', HOUR: '小时', DAY: '日', WEEK: '周', MONTH: '月' },
      dataTypeMap: {
        SESSION_COUNT: '虚拟机数', ONLINE_USER_COUNT: '在线用户',
        ONLINE_CLINET_COUNT: '在线终端', CONNECTED_SESSION_COUNT: '会话数',
        SERVER_VIRTUAL_SESSION_COUNT: '云服务器'
      }
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 用户在线统计 (KSVD格式)
router.get('/user-stats', async (req, res) => {
  try {
    const db = req.app.locals.db;
    const total = db.prepare('SELECT COUNT(*) as c FROM users').get().c;
    const now = new Date();
    const monthStart = `${now.getFullYear()}-${String(now.getMonth()+1).padStart(2,'0')}-01`;
    const yearStart = `${now.getFullYear()}-01-01`;
    const monthUsers = db.prepare("SELECT COUNT(DISTINCT user) as c FROM events WHERE type='login' AND created_at >= ?").get(monthStart).c;
    const yearUsers = db.prepare("SELECT COUNT(DISTINCT user) as c FROM events WHERE type='login' AND created_at >= ?").get(yearStart).c;
    const thirtyMinAgo = new Date(now.getTime() - 30*60000).toISOString();
    const online = db.prepare("SELECT COUNT(DISTINCT user) as c FROM events WHERE created_at >= ?").get(thirtyMinAgo).c;
    res.json({ success: true, data: { totalUserNum: total, onlineUserNum: online, monthUserNum: monthUsers, yearUserNum: yearUsers } });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 用户在线时长排名 (KSVD jqGrid格式)
router.get('/user-ranking', async (req, res) => {
  try {
    const db = req.app.locals.db;
    const rows = db.prepare(`
      SELECT u.username, u.display_name, COUNT(e.id) as event_count,
             ROUND(COUNT(e.id) * 0.5, 2) as total_hours
      FROM users u LEFT JOIN events e ON u.username = e.user AND e.type = 'login'
      GROUP BY u.username ORDER BY total_hours DESC LIMIT 20
    `).all();
    res.json({
      total: 1, pager: 1, records: rows.length,
      rows: rows.map((r, i) => ({
        id: i + 1,
        cell: { username: r.username, desktopName: r.display_name || r.username, total: r.total_hours || 0 }
      }))
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 近期告警 (KSVD jqGrid格式)
router.get('/recent-alerts', async (req, res) => {
  try {
    const db = req.app.locals.db;
    const limit = parseInt(req.query.rows) || 20;
    const alerts = db.prepare(`
      SELECT id, level, type, target_name, message, created_at
      FROM alerts WHERE status = 'active'
      ORDER BY created_at DESC LIMIT ?
    `).all(limit);
    const severityMap = { critical: '紧急', warning: '严重', info: '一般' };
    res.json({
      total: Math.ceil(alerts.length / limit), pager: 1, records: alerts.length,
      rows: alerts.map((a, i) => ({
        id: i,
        cell: {
          severity: severityMap[a.level] || '一般',
          date: (a.created_at || '').replace('T', ' ').replace(/\.\d+Z?$/, '').replace(/-/g, '/'),
          objectName: a.target_name || '',
          type: a.type || '',
          objectType: '',
          info: a.message || ''
        }
      }))
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
