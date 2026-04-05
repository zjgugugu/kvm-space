// Cockpit 集群管理 API
// 对应真实Cockpit的 cockpit.script() 调用
var express = require('express');
var router = express.Router();
var { execSync } = require('child_process');

// 获取集群配置/状态（核心API）
router.get('/status', function (req, res) {
  var db = req.app.locals.db;
  var deployStatus = db.prepare('SELECT * FROM cockpit_deploy_status').get();
  var nodes = db.prepare('SELECT * FROM cockpit_nodes ORDER BY id').all();
  var ntp = db.prepare('SELECT * FROM cockpit_time_server ORDER BY id DESC LIMIT 1').get();
  var nfsInfo = db.prepare('SELECT * FROM cockpit_nfs_storage_info LIMIT 1').get();
  var cifsInfo = db.prepare('SELECT * FROM cockpit_cifs_storage_info LIMIT 1').get();
  var centerCluster = db.prepare('SELECT * FROM cockpit_center_cluster_info LIMIT 1').get();

  if (!deployStatus || deployStatus.status === 0) {
    return res.json({ cluster_status: 0 });
  }

  // 构建返回数据（匹配真实Cockpit getClusterDisplay）
  var serviceStatus = nodes.map(function (n) {
    return {
      ip: n.ip,
      status: n.status || 'active',
      role: n.role,
      is_docker_node: n.is_docker_node,
      hostname: n.name,
      docker_ip: n.docker_ip || ''
    };
  });

  // 构建管理存储状态
  var mStorageStatus = {
    volume_name: 'MStorage',
    status: 'Started',
    brick: nodes.filter(function (n) { return n.is_docker_node === 1; }).map(function (n) {
      return { name: n.docker_ip, status: 'Y', director: '/home/M_brick', ip: n.ip };
    })
  };

  // 合并NFS/CIFS信息
  if (nfsInfo) {
    mStorageStatus.nfs_server = nfsInfo.ip;
    mStorageStatus.nfs_share_dir = nfsInfo.share_dir;
    mStorageStatus.nfs_version = nfsInfo.version;
    mStorageStatus.nfs_status = 'connected';
  }
  if (cifsInfo) {
    mStorageStatus.cifs_server = cifsInfo.ip;
    mStorageStatus.cifs_share_dir = cifsInfo.share_dir;
    mStorageStatus.cifs_user_name = cifsInfo.user_name;
    mStorageStatus.cifs_version = cifsInfo.version;
    mStorageStatus.cifs_status = 'connected';
  }

  var result = {
    cluster_status: 1,
    storage_type: deployStatus.manager_storage_type,
    is_branch: deployStatus.is_branch,
    service_status: serviceStatus,
    manager_storage_status: mStorageStatus,
    time_update_interval: ntp ? ntp.time_update_interval : 5,
    NTP: ntp ? ntp.server : '0',
    mmm_vip: deployStatus.mmm_vip || '127.0.0.1'
  };

  if (centerCluster) {
    result.center_cluster = {
      ip: centerCluster.ip,
      user_name: centerCluster.user_name,
      user_password: '******',
      sync_time: centerCluster.data_sync_time
    };
  }

  // 获取网关/子网信息
  try {
    var gw = execSync("ip route | grep default | awk '{print $3}'", { encoding: 'utf8', timeout: 3000 }).trim();
    var mask = execSync("ip -o -4 addr show scope global | head -1 | awk '{print $4}' | cut -d/ -f2", { encoding: 'utf8', timeout: 3000 }).trim();
    result.gateway = gw;
    result.mask = mask;
  } catch (e) {
    result.gateway = '';
    result.mask = '24';
  }

  res.json(result);
});

// 节点列表
router.get('/nodes', function (req, res) {
  var db = req.app.locals.db;
  var nodes = db.prepare('SELECT * FROM cockpit_nodes ORDER BY id').all();
  res.json({ data: nodes });
});

// 添加节点
router.post('/nodes', function (req, res) {
  var db = req.app.locals.db;
  var { name, ip, role, docker_ip, docker_hostname, storage_ip } = req.body;
  if (!name || !ip || !role) return res.status(400).json({ error: '缺少必填字段' });
  db.prepare('INSERT INTO cockpit_nodes (name, ip, role, is_docker_node, docker_ip, docker_hostname, storage_ip) VALUES (?,?,?,?,?,?,?)')
    .run(name, ip, role, docker_ip ? 1 : 0, docker_ip || '', docker_hostname || '', storage_ip || '');
  var node = db.prepare('SELECT * FROM cockpit_nodes WHERE ip = ?').get(ip);
  res.json(node);
});

// 删除节点
router.delete('/nodes/:id', function (req, res) {
  var db = req.app.locals.db;
  db.prepare('DELETE FROM cockpit_nodes WHERE id = ?').run(parseInt(req.params.id));
  res.json({ success: true });
});

// 更新节点角色
router.put('/nodes/:id/role', function (req, res) {
  var db = req.app.locals.db;
  var { role } = req.body;
  db.prepare('UPDATE cockpit_nodes SET role = ? WHERE id = ?').run(role, parseInt(req.params.id));
  res.json({ success: true });
});

// 部署（模拟）
router.post('/deploy', function (req, res) {
  var db = req.app.locals.db;
  var { type, storage_mode, nodes, mmm_vip } = req.body;
  // type: 1=单机, 2=集群
  // storage_mode: GlusterFS/NFS/CIFS

  // 保存节点
  if (nodes && nodes.length > 0) {
    db.exec('DELETE FROM cockpit_nodes');
    nodes.forEach(function (n) {
      db.prepare('INSERT INTO cockpit_nodes (name, ip, role, is_docker_node, docker_ip, docker_hostname, storage_ip) VALUES (?,?,?,?,?,?,?)')
        .run(n.name, n.ip, n.role, n.is_docker_node || (n.docker_ip ? 1 : 0), n.docker_ip || '', n.docker_hostname || '', n.storage_ip || '');
    });
  }

  // 更新部署状态
  db.prepare('UPDATE cockpit_deploy_status SET status = 1, is_branch = ?, manager_storage_type = ?, mmm_vip = ?')
    .run(type === 2 ? 0 : 0, storage_mode || 'GlusterFS', mmm_vip || '127.0.0.1');

  res.json({ success: true, message: '部署完成' });
});

// 取消部署（回到初始状态）
router.post('/cancel-deploy', function (req, res) {
  var db = req.app.locals.db;
  db.prepare('UPDATE cockpit_deploy_status SET status = 0').run();
  res.json({ success: true });
});

// 一键关机
router.post('/shutdown', function (req, res) {
  res.json({ success: true, message: '关机指令已发送（模拟）' });
});

// 一键重启
router.post('/reboot', function (req, res) {
  res.json({ success: true, message: '重启指令已发送（模拟）' });
});

module.exports = router;
