// Cockpit 本地服务器管理 API
// 对应真实 Cockpit shell 的系统概览、服务、日志、网络、存储功能
var express = require('express');
var router = express.Router();
var { execSync } = require('child_process');

function exec(cmd) {
  try { return execSync(cmd, { encoding: 'utf8', timeout: 5000 }).trim(); } catch (e) { return ''; }
}

// ===== 系统概览 =====
router.get('/overview', function (req, res) {
  var hostname = exec('hostname');
  var uptime = exec('uptime -p') || exec('uptime');
  var osName = exec("cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d '\"'");
  var kernel = exec('uname -r');
  var arch = exec('uname -m');

  // CPU
  var cpuModel = exec("lscpu | grep -E 'Model name|型号名称' | sed 's/.*：\\s*//' | sed 's/.*:\\s*//'");
  var cpuCores = parseInt(exec('nproc')) || 0;
  var cpuUsageLine = exec("top -bn1 | grep 'Cpu(s)' | awk '{print $2}'");
  var cpuUsage = parseFloat(cpuUsageLine) || 0;
  var loadAvg = exec('cat /proc/loadavg').split(' ').slice(0, 3).join(' ');

  // Memory
  var memLine = exec("free -m | awk '/Mem:/ {print $2,$3,$4,$7}'").split(' ');
  var memTotal = parseInt(memLine[0]) || 0;
  var memUsed = parseInt(memLine[1]) || 0;
  var memFree = parseInt(memLine[2]) || 0;
  var memAvail = parseInt(memLine[3]) || 0;

  // Swap
  var swapLine = exec("free -m | awk '/Swap:/ {print $2,$3,$4}'").split(' ');
  var swapTotal = parseInt(swapLine[0]) || 0;
  var swapUsed = parseInt(swapLine[1]) || 0;

  // Disk
  var diskLines = exec("df -h --output=source,fstype,size,used,avail,pcent,target -x tmpfs -x devtmpfs -x overlay 2>/dev/null || df -h | grep -vE '(tmpfs|devtmpfs)'");
  var disks = [];
  diskLines.split('\n').forEach(function (line, i) {
    if (i === 0) return; // header
    var parts = line.trim().split(/\s+/);
    if (parts.length >= 7) {
      disks.push({ device: parts[0], fstype: parts[1], size: parts[2], used: parts[3], avail: parts[4], use_pct: parts[5], mount: parts[6] });
    } else if (parts.length >= 6) {
      disks.push({ device: parts[0], fstype: '', size: parts[1], used: parts[2], avail: parts[3], use_pct: parts[4], mount: parts[5] });
    }
  });

  // Network interfaces
  var ifaceText = exec("ip -o -4 addr show scope global | awk '{print $2,$4}'");
  var ifaces = [];
  ifaceText.split('\n').forEach(function (line) {
    var parts = line.trim().split(' ');
    if (parts.length >= 2) {
      ifaces.push({ name: parts[0], addr: parts[1] });
    }
  });

  res.json({
    hostname: hostname, uptime: uptime, os: osName, kernel: kernel, arch: arch,
    cpu: { model: cpuModel, cores: cpuCores, usage: cpuUsage, load_avg: loadAvg },
    memory: { total_mb: memTotal, used_mb: memUsed, free_mb: memFree, avail_mb: memAvail },
    swap: { total_mb: swapTotal, used_mb: swapUsed },
    disks: disks,
    interfaces: ifaces
  });
});

// ===== 服务管理 =====
router.get('/services', function (req, res) {
  var output = exec("systemctl list-units --type=service --no-pager --no-legend -a | head -80");
  var services = [];
  output.split('\n').forEach(function (line) {
    var parts = line.trim().split(/\s+/);
    if (parts.length >= 4) {
      var name = parts[0].replace('.service', '');
      services.push({
        name: name,
        load: parts[1],
        active: parts[2],
        sub: parts[3],
        description: parts.slice(4).join(' ')
      });
    }
  });
  res.json({ data: services });
});

router.get('/services/:name', function (req, res) {
  var name = req.params.name.replace(/[^a-zA-Z0-9._@-]/g, '');
  var status = exec('systemctl status ' + name + '.service --no-pager 2>&1 | head -20');
  var enabled = exec('systemctl is-enabled ' + name + '.service 2>/dev/null');
  var active = exec('systemctl is-active ' + name + '.service 2>/dev/null');
  res.json({ name: name, status: status, enabled: enabled, active: active });
});

router.post('/services/:name/:action', function (req, res) {
  var name = req.params.name.replace(/[^a-zA-Z0-9._@-]/g, '');
  var action = req.params.action;
  if (['start', 'stop', 'restart', 'enable', 'disable'].indexOf(action) === -1) {
    return res.status(400).json({ error: '不支持的操作' });
  }
  try {
    execSync('systemctl ' + action + ' ' + name + '.service', { encoding: 'utf8', timeout: 15000 });
    res.json({ success: true, message: name + ' ' + action + ' 完成' });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

// ===== 系统日志 =====
router.get('/logs', function (req, res) {
  var priority = req.query.priority || '';
  var unit = req.query.unit || '';
  var lines = parseInt(req.query.lines) || 100;
  if (lines > 500) lines = 500;

  var cmd = 'journalctl --no-pager -o json -n ' + lines;
  if (priority) cmd += ' -p ' + priority.replace(/[^0-9]/g, '');
  if (unit) cmd += ' -u ' + unit.replace(/[^a-zA-Z0-9._@-]/g, '');
  cmd += ' 2>/dev/null || journalctl --no-pager -n ' + lines;

  var output = exec(cmd);
  var logs = [];
  output.split('\n').forEach(function (line) {
    try {
      var obj = JSON.parse(line);
      logs.push({
        timestamp: obj.__REALTIME_TIMESTAMP ? new Date(parseInt(obj.__REALTIME_TIMESTAMP) / 1000).toISOString() : '',
        priority: obj.PRIORITY || '',
        unit: obj._SYSTEMD_UNIT || obj.SYSLOG_IDENTIFIER || '',
        message: obj.MESSAGE || ''
      });
    } catch (e) {
      if (line.trim()) logs.push({ timestamp: '', priority: '', unit: '', message: line });
    }
  });
  res.json({ data: logs });
});

// ===== 网络管理 =====
router.get('/networking', function (req, res) {
  // Interfaces
  var ifText = exec("ip -j addr show 2>/dev/null");
  var interfaces = [];
  if (ifText) {
    try {
      var ifData = JSON.parse(ifText);
      ifData.forEach(function (iface) {
        var addrs = (iface.addr_info || []).filter(function (a) { return a.family === 'inet'; });
        interfaces.push({
          name: iface.ifname,
          state: iface.operstate,
          mac: iface.address,
          mtu: iface.mtu,
          addresses: addrs.map(function (a) { return a.local + '/' + a.prefixlen; })
        });
      });
    } catch (e) {}
  }
  if (!interfaces.length) {
    // fallback: parse ip addr line by line
    var ifLines = exec("ip -o addr show | awk '{print $2, $3, $4}'");
    var ifMap = {};
    ifLines.split('\n').forEach(function (line) {
      var parts = line.trim().split(/\s+/);
      if (parts.length >= 3) {
        var name = parts[0];
        var family = parts[1];
        var addr = parts[2];
        if (!ifMap[name]) ifMap[name] = { name: name, state: '', mac: '', mtu: 0, addresses: [] };
        if (family === 'inet') ifMap[name].addresses.push(addr);
      }
    });
    // get state separately
    var stateLines = exec("ip -o link show | awk -F'[<>]' '{print $1, $2}'");
    stateLines.split('\n').forEach(function (line) {
      var m = line.match(/^\d+:\s+(\S+)/);
      if (m) {
        var name = m[1].replace(':', '');
        var up = line.indexOf('UP') !== -1;
        if (ifMap[name]) ifMap[name].state = up ? 'UP' : 'DOWN';
      }
    });
    interfaces = Object.keys(ifMap).map(function (k) { return ifMap[k]; });
  }

  // Routes
  var routeText = exec("ip route show");
  var routes = [];
  routeText.split('\n').forEach(function (line) {
    if (line.trim()) routes.push(line.trim());
  });

  // DNS
  var dns = exec("cat /etc/resolv.conf 2>/dev/null | grep nameserver | awk '{print $2}'").split('\n').filter(Boolean);
  var hostname = exec('hostname');
  var fqdn = exec('hostname -f 2>/dev/null') || hostname;

  res.json({
    hostname: hostname,
    fqdn: fqdn,
    interfaces: interfaces,
    routes: routes,
    dns: dns
  });
});

// ===== 存储管理 =====
router.get('/storage', function (req, res) {
  // Block devices
  var lsblkText = exec("lsblk -J -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT,MODEL 2>/dev/null");
  var blockDevices = [];
  if (lsblkText) {
    try { blockDevices = JSON.parse(lsblkText).blockdevices || []; } catch (e) {}
  }
  if (!blockDevices.length) {
    // fallback: parse lsblk text output
    var lsblkLines = exec("lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT 2>/dev/null");
    lsblkLines.split('\n').forEach(function (line, i) {
      if (i === 0) return;
      var parts = line.replace(/[├└│─]/g, '').trim().split(/\s+/);
      if (parts.length >= 3) {
        blockDevices.push({
          name: parts[0], size: parts[1], type: parts[2],
          fstype: parts[3] || '', mountpoint: parts[4] || ''
        });
      }
    });
  }

  // Filesystems
  var dfText = exec("df -hT --output=source,fstype,size,used,avail,pcent,target -x tmpfs -x devtmpfs 2>/dev/null || df -hT | grep -vE '(tmpfs|devtmpfs)'");
  var filesystems = [];
  dfText.split('\n').forEach(function (line, i) {
    if (i === 0) return;
    var parts = line.trim().split(/\s+/);
    if (parts.length >= 7) {
      filesystems.push({ device: parts[0], fstype: parts[1], size: parts[2], used: parts[3], avail: parts[4], use_pct: parts[5], mount: parts[6] });
    }
  });

  // LVM
  var vgs = exec("vgs --noheadings -o vg_name,vg_size,vg_free 2>/dev/null");
  var volumeGroups = [];
  vgs.split('\n').forEach(function (line) {
    var parts = line.trim().split(/\s+/);
    if (parts.length >= 3) {
      volumeGroups.push({ name: parts[0], size: parts[1], free: parts[2] });
    }
  });

  res.json({
    block_devices: blockDevices,
    filesystems: filesystems,
    volume_groups: volumeGroups
  });
});

// ===== 账户管理 =====
router.get('/accounts', function (req, res) {
  var usersText = exec("awk -F: '$3 >= 1000 || $3 == 0 {print $1,$3,$4,$5,$6,$7}' /etc/passwd");
  var users = [];
  usersText.split('\n').forEach(function (line) {
    var parts = line.split(' ');
    if (parts.length >= 6) {
      var lastLogin = exec("last -1 " + parts[0].replace(/[^a-zA-Z0-9_.-]/g, '') + " 2>/dev/null | head -1");
      users.push({
        username: parts[0],
        uid: parseInt(parts[1]),
        gid: parseInt(parts[2]),
        comment: parts[3],
        home: parts[4],
        shell: parts[5],
        last_login: lastLogin || '从未登录'
      });
    }
  });
  res.json({ data: users });
});

module.exports = router;
