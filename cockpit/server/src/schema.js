// Cockpit 总控虚拟化界面 - 数据库Schema
// Cockpit 总控虚拟化界面 - 数据库表结构

function initSchema(db) {
  db.exec(`
    CREATE TABLE IF NOT EXISTS cockpit_nodes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name VARCHAR(255) NOT NULL,
      ip VARCHAR(15) NOT NULL,
      role VARCHAR(20) NOT NULL,
      status VARCHAR(16) DEFAULT 'active',
      is_docker_node INT DEFAULT 0,
      docker_ip VARCHAR(15) DEFAULT '',
      docker_hostname VARCHAR(15) DEFAULT '',
      storage_ip VARCHAR(15) DEFAULT ''
    );

    CREATE TABLE IF NOT EXISTS cockpit_deploy_status (
      status INT DEFAULT 0,
      is_branch INT DEFAULT 0,
      manager_storage_type VARCHAR(20) NOT NULL DEFAULT 'GlusterFS',
      mmm_vip VARCHAR(15) DEFAULT '127.0.0.1'
    );

    CREATE TABLE IF NOT EXISTS cockpit_center_cluster_info (
      ip VARCHAR(15) NOT NULL,
      user_name VARCHAR(255) NOT NULL,
      password VARCHAR(255) NOT NULL,
      data_sync_time VARCHAR(255) NOT NULL
    );

    CREATE TABLE IF NOT EXISTS cockpit_nfs_storage_info (
      ip VARCHAR(16) NOT NULL,
      share_dir VARCHAR(255) NOT NULL,
      version VARCHAR(32) NOT NULL
    );

    CREATE TABLE IF NOT EXISTS cockpit_cifs_storage_info (
      ip VARCHAR(16) NOT NULL,
      share_dir VARCHAR(255) NOT NULL,
      user_name VARCHAR(255) NOT NULL,
      password VARCHAR(255) NOT NULL,
      domain VARCHAR(255) DEFAULT '',
      version VARCHAR(10) DEFAULT '2.0'
    );

    CREATE TABLE IF NOT EXISTS cockpit_time_server (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      server VARCHAR(255) NOT NULL,
      time_update_interval INTEGER DEFAULT 5
    );

    CREATE TABLE IF NOT EXISTS cockpit_ksvd_status (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      ip VARCHAR(15) NOT NULL,
      status VARCHAR(16) NOT NULL
    );

    CREATE TABLE IF NOT EXISTS cockpit_maintain_tasks (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      type VARCHAR(50) NOT NULL,
      status VARCHAR(20) DEFAULT 'pending',
      progress INTEGER DEFAULT 0,
      message TEXT DEFAULT '',
      created_at DATETIME DEFAULT (datetime('now')),
      updated_at DATETIME DEFAULT (datetime('now'))
    );

    CREATE TABLE IF NOT EXISTS cockpit_maintain_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      type VARCHAR(50) NOT NULL,
      level VARCHAR(10) DEFAULT 'info',
      message TEXT NOT NULL,
      detail TEXT DEFAULT '',
      created_at DATETIME DEFAULT (datetime('now'))
    );
  `);
}

function initDefaultData(db) {
  // 检查是否已有部署状态
  var row = db.prepare('SELECT COUNT(*) as cnt FROM cockpit_deploy_status').get();
  if (row.cnt === 0) {
    // 匹配真实系统: status=1(已部署), is_branch=0, GlusterFS, mmm_vip=10.126.33.195
    db.prepare('INSERT INTO cockpit_deploy_status (status, is_branch, manager_storage_type, mmm_vip) VALUES (?,?,?,?)').run(1, 0, 'GlusterFS', '10.126.33.195');
  }

  // 检查是否有节点数据
  row = db.prepare('SELECT COUNT(*) as cnt FROM cockpit_nodes').get();
  if (row.cnt === 0) {
    // 匹配真实系统: node1, 10.126.33.238, CM_VDI, docker_ip=10.126.33.194
    db.prepare('INSERT INTO cockpit_nodes (name, ip, role, is_docker_node, docker_ip, docker_hostname, storage_ip) VALUES (?,?,?,?,?,?,?)')
      .run('node1', '10.126.33.238', 'CM_VDI', 1, '10.126.33.194', 'dockernode1', '');
  }

  // 检查是否有时间服务器配置
  row = db.prepare('SELECT COUNT(*) as cnt FROM cockpit_time_server').get();
  if (row.cnt === 0) {
    db.prepare('INSERT INTO cockpit_time_server (server, time_update_interval) VALUES (?, ?)').run('0', 5);
  }
}

module.exports = { initSchema, initDefaultData };
