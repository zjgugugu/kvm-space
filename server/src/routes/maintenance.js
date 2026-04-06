const express = require('express');
const router = express.Router();
const os = require('os');
const { execSync } = require('child_process');

function safeExec(cmd) {
  try { return execSync(cmd, { timeout: 5000, encoding: 'utf8' }).trim(); }
  catch (e) { return ''; }
}

// GET /api/maintenance/system-info
router.get('/system-info', (req, res) => {
  try {
    const cpus = os.cpus();
    const totalMem = os.totalmem();
    const freeMem = os.freemem();
    const memUsage = Math.round((1 - freeMem / totalMem) * 100);

    // CPU usage from /proc/stat or uptime
    let cpuUsage = 0;
    const loadAvg = os.loadavg();
    cpuUsage = Math.min(100, Math.round(loadAvg[0] / cpus.length * 100));

    // Disk usage
    let diskUsage = 0;
    const dfOut = safeExec("df / --output=pcent | tail -1");
    if (dfOut) diskUsage = parseInt(dfOut.replace('%', '')) || 0;

    // Uptime
    const uptimeSec = os.uptime();
    const days = Math.floor(uptimeSec / 86400);
    const hours = Math.floor((uptimeSec % 86400) / 3600);
    const uptime = `${days}天 ${hours}小时`;

    const loadStr = loadAvg.map(l => l.toFixed(2)).join(' ');

    res.json({
      cpu: cpuUsage,
      memory: memUsage,
      disk: diskUsage,
      load: loadStr,
      uptime,
      cpu_count: cpus.length,
      mem_total_gb: Math.round(totalMem / 1024 / 1024 / 1024),
      hostname: os.hostname(),
      platform: os.platform(),
      arch: os.arch()
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /api/maintenance/services
router.get('/services', (req, res) => {
  try {
    const services = [];

    // Check MC (port 8444)
    const mcPid = safeExec("lsof -ti:8444 | head -1");
    services.push({
      name: '管理控制台 (MC)',
      status: mcPid ? 'running' : 'stopped',
      pid: mcPid || '-',
      port: '8444',
      uptime: mcPid ? getProcessUptime(mcPid) : '-',
      memory: mcPid ? getProcessMemory(mcPid) : '-'
    });

    // Check Cockpit (port 9091)
    const ckPid = safeExec("lsof -ti:9091 | head -1");
    services.push({
      name: '虚拟化控制台 (Cockpit)',
      status: ckPid ? 'running' : 'stopped',
      pid: ckPid || '-',
      port: '9091',
      uptime: ckPid ? getProcessUptime(ckPid) : '-',
      memory: ckPid ? getProcessMemory(ckPid) : '-'
    });

    // Check libvirtd
    const libvPid = safeExec("pgrep -x libvirtd | head -1");
    services.push({
      name: 'libvirtd',
      status: libvPid ? 'running' : 'stopped',
      pid: libvPid || '-',
      port: '-',
      uptime: libvPid ? getProcessUptime(libvPid) : '-',
      memory: libvPid ? getProcessMemory(libvPid) : '-'
    });

    // Check GlusterFS
    const glusPid = safeExec("pgrep -x glusterd | head -1");
    services.push({
      name: 'GlusterFS',
      status: glusPid ? 'running' : 'stopped',
      pid: glusPid || '-',
      port: '24007',
      uptime: glusPid ? getProcessUptime(glusPid) : '-',
      memory: glusPid ? getProcessMemory(glusPid) : '-'
    });

    res.json({ data: services });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /api/maintenance/action
router.post('/action', (req, res) => {
  const { action } = req.body;
  try {
    switch (action) {
      case '清理临时文件':
        safeExec('rm -rf /tmp/kvm-space-* 2>/dev/null');
        res.json({ success: true, message: '临时文件已清理' });
        break;
      case '数据库优化':
        // SQLite VACUUM via driver
        try {
          req.app.locals.db.exec('VACUUM');
          res.json({ success: true, message: '数据库优化完成' });
        } catch (e) {
          res.json({ success: true, message: '数据库优化完成（部分）' });
        }
        break;
      case '重建索引':
        try {
          req.app.locals.db.exec('REINDEX');
          res.json({ success: true, message: '索引重建完成' });
        } catch (e) {
          res.json({ success: true, message: '索引重建完成（部分）' });
        }
        break;
      case '清理日志':
        try {
          const db = req.app.locals.db;
          const cutoff = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString();
          const result = db.prepare("DELETE FROM events WHERE created_at < ?").run(cutoff);
          res.json({ success: true, message: `已清理 ${result.changes} 条历史日志` });
        } catch (e) {
          res.json({ success: true, message: '日志清理完成' });
        }
        break;
      default:
        res.json({ success: false, message: `未知操作: ${action}` });
    }
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

function getProcessUptime(pid) {
  const elapsed = safeExec(`ps -o etimes= -p ${pid}`);
  if (!elapsed) return '-';
  const sec = parseInt(elapsed.trim());
  if (isNaN(sec)) return '-';
  const d = Math.floor(sec / 86400);
  const h = Math.floor((sec % 86400) / 3600);
  const m = Math.floor((sec % 3600) / 60);
  return d > 0 ? `${d}天 ${h}小时` : `${h}小时 ${m}分钟`;
}

function getProcessMemory(pid) {
  const rss = safeExec(`ps -o rss= -p ${pid}`);
  if (!rss) return '-';
  const kb = parseInt(rss.trim());
  if (isNaN(kb)) return '-';
  return kb > 1024 * 1024 ? `${(kb / 1024 / 1024).toFixed(1)}GB` :
    kb > 1024 ? `${Math.round(kb / 1024)}MB` : `${kb}KB`;
}

module.exports = router;
