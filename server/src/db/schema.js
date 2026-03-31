// 数据库初始化 - 完整表结构（对标麒麟信安云V7R023全功能）

function initSchema(db) {
  db.exec(`
    -- ==================== 主机集群 ====================
    CREATE TABLE IF NOT EXISTS hosts (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      ip TEXT NOT NULL,
      bmc_ip TEXT DEFAULT '',
      role TEXT DEFAULT 'VDI',
      cpu_model TEXT DEFAULT '',
      cpu_total INTEGER DEFAULT 0,
      cpu_used INTEGER DEFAULT 0,
      mem_total INTEGER DEFAULT 0,
      mem_used INTEGER DEFAULT 0,
      disk_total INTEGER DEFAULT 0,
      disk_used INTEGER DEFAULT 0,
      net_speed INTEGER DEFAULT 1000,
      status TEXT DEFAULT 'offline',
      arch TEXT DEFAULT 'x86_64',
      os TEXT DEFAULT '',
      kernel TEXT DEFAULT '',
      uptime INTEGER DEFAULT 0,
      vm_count INTEGER DEFAULT 0,
      ntp_server TEXT DEFAULT '',
      ha_vip TEXT DEFAULT '',
      created_at DATETIME DEFAULT (datetime('now'))
    );

    -- ==================== 黄金镜像/模板 ====================
    CREATE TABLE IF NOT EXISTS templates (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      title TEXT DEFAULT '',
      os_type TEXT DEFAULT 'linux',
      os_version TEXT DEFAULT '',
      arch TEXT DEFAULT 'x86_64',
      cpu INTEGER DEFAULT 2,
      memory INTEGER DEFAULT 2048,
      disk INTEGER DEFAULT 40,
      status TEXT DEFAULT 'draft',
      run_mode TEXT DEFAULT 'VDI',
      data_mode TEXT DEFAULT 'normal',
      icon TEXT DEFAULT '',
      description TEXT DEFAULT '',
      version INTEGER DEFAULT 1,
      parent_id TEXT DEFAULT '',
      auto_optimize_threshold INTEGER DEFAULT 0,
      created_at DATETIME DEFAULT (datetime('now')),
      updated_at DATETIME DEFAULT (datetime('now'))
    );

    -- ==================== 桌面规格 ====================
    CREATE TABLE IF NOT EXISTS desktop_specs (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      cpu INTEGER DEFAULT 2,
      max_cpu INTEGER DEFAULT 4,
      memory INTEGER DEFAULT 2048,
      max_memory INTEGER DEFAULT 4096,
      cpu_limit INTEGER DEFAULT 100,
      memory_limit INTEGER DEFAULT 100,
      system_disk INTEGER DEFAULT 40,
      user_disk INTEGER DEFAULT 0,
      disk_encrypted INTEGER DEFAULT 0,
      network_type TEXT DEFAULT 'bridged',
      mac_pool_id TEXT DEFAULT '',
      protocol TEXT DEFAULT 'UDAP',
      usb_mode TEXT DEFAULT 'native',
      gpu_type TEXT DEFAULT '',
      gpu_count INTEGER DEFAULT 0,
      watermark_enabled INTEGER DEFAULT 0,
      screen_record_enabled INTEGER DEFAULT 0,
      description TEXT DEFAULT '',
      created_at DATETIME DEFAULT (datetime('now'))
    );

    -- ==================== 发布规则 ====================
    CREATE TABLE IF NOT EXISTS publish_rules (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      template_id TEXT,
      spec_id TEXT,
      target_type TEXT DEFAULT 'user',
      target_id TEXT DEFAULT '',
      target_name TEXT DEFAULT '',
      desktop_type TEXT DEFAULT 'dynamic',
      ip_restriction TEXT DEFAULT '',
      time_restriction TEXT DEFAULT '',
      snapshot_enabled INTEGER DEFAULT 0,
      max_snapshots INTEGER DEFAULT 3,
      auto_start INTEGER DEFAULT 0,
      auto_shutdown TEXT DEFAULT '',
      status TEXT DEFAULT 'active',
      created_at DATETIME DEFAULT (datetime('now')),
      FOREIGN KEY (template_id) REFERENCES templates(id),
      FOREIGN KEY (spec_id) REFERENCES desktop_specs(id)
    );

    -- ==================== 虚拟机 ====================
    CREATE TABLE IF NOT EXISTS vms (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      host_id TEXT,
      template_id TEXT,
      spec_id TEXT DEFAULT '',
      publish_rule_id TEXT DEFAULT '',
      cpu INTEGER DEFAULT 2,
      max_cpu INTEGER DEFAULT 4,
      memory INTEGER DEFAULT 2048,
      max_memory INTEGER DEFAULT 4096,
      disk INTEGER DEFAULT 40,
      status TEXT DEFAULT 'stopped',
      ip TEXT DEFAULT '',
      mac TEXT DEFAULT '',
      os_type TEXT DEFAULT 'linux',
      os_version TEXT DEFAULT '',
      owner TEXT DEFAULT '',
      description TEXT DEFAULT '',
      vnc_port INTEGER DEFAULT 0,
      -- 高级配置 (对标KSVD V7)
      cpu_mode TEXT DEFAULT 'host-passthrough',
      cpu_pinning TEXT DEFAULT '',
      cpu_hotplug INTEGER DEFAULT 0,
      mem_hotplug INTEGER DEFAULT 0,
      hugepages TEXT DEFAULT '',
      bios_type TEXT DEFAULT 'seabios',
      video_type TEXT DEFAULT 'qxl',
      video_ram INTEGER DEFAULT 65536,
      boot_order TEXT DEFAULT 'hd,cdrom,network',
      ha_enabled INTEGER DEFAULT 1,
      auto_migrate INTEGER DEFAULT 1,
      expire_date TEXT DEFAULT '',
      disk_cache TEXT DEFAULT 'none',
      deleted INTEGER DEFAULT 0,
      deleted_at DATETIME,
      created_at DATETIME DEFAULT (datetime('now')),
      updated_at DATETIME DEFAULT (datetime('now')),
      FOREIGN KEY (host_id) REFERENCES hosts(id),
      FOREIGN KEY (template_id) REFERENCES templates(id)
    );

    -- ==================== VM 磁盘 ====================
    CREATE TABLE IF NOT EXISTS vm_disks (
      id TEXT PRIMARY KEY,
      vm_id TEXT NOT NULL,
      name TEXT DEFAULT '',
      size INTEGER DEFAULT 0,
      type TEXT DEFAULT 'system',
      bus TEXT DEFAULT 'virtio',
      format TEXT DEFAULT 'qcow2',
      pool_id TEXT DEFAULT '',
      path TEXT DEFAULT '',
      boot_order INTEGER DEFAULT 0,
      created_at DATETIME DEFAULT (datetime('now')),
      FOREIGN KEY (vm_id) REFERENCES vms(id)
    );

    -- ==================== VM 网卡 ====================
    CREATE TABLE IF NOT EXISTS vm_nics (
      id TEXT PRIMARY KEY,
      vm_id TEXT NOT NULL,
      network_id TEXT DEFAULT '',
      mac TEXT DEFAULT '',
      model TEXT DEFAULT 'virtio',
      ip TEXT DEFAULT '',
      type TEXT DEFAULT 'bridged',
      created_at DATETIME DEFAULT (datetime('now')),
      FOREIGN KEY (vm_id) REFERENCES vms(id)
    );

    -- ==================== 快照 ====================
    CREATE TABLE IF NOT EXISTS snapshots (
      id TEXT PRIMARY KEY,
      vm_id TEXT NOT NULL,
      name TEXT NOT NULL,
      description TEXT DEFAULT '',
      size INTEGER DEFAULT 0,
      status TEXT DEFAULT 'active',
      is_current INTEGER DEFAULT 0,
      parent_id TEXT DEFAULT '',
      created_by TEXT DEFAULT 'admin',
      created_at DATETIME DEFAULT (datetime('now')),
      FOREIGN KEY (vm_id) REFERENCES vms(id)
    );

    -- ==================== 快照策略 ====================
    CREATE TABLE IF NOT EXISTS snapshot_policies (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      cron_expr TEXT DEFAULT '0 2 * * *',
      max_keep INTEGER DEFAULT 5,
      cpu_limit INTEGER DEFAULT 50,
      status TEXT DEFAULT 'active',
      last_run DATETIME,
      next_run DATETIME,
      created_at DATETIME DEFAULT (datetime('now'))
    );

    CREATE TABLE IF NOT EXISTS snapshot_policy_vms (
      policy_id TEXT NOT NULL,
      vm_id TEXT NOT NULL,
      PRIMARY KEY (policy_id, vm_id)
    );

    -- ==================== 网络 ====================
    CREATE TABLE IF NOT EXISTS networks (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      type TEXT DEFAULT 'bridge',
      bridge TEXT DEFAULT '',
      vlan INTEGER DEFAULT 0,
      subnet TEXT DEFAULT '',
      gateway TEXT DEFAULT '',
      dns TEXT DEFAULT '',
      dhcp_enabled INTEGER DEFAULT 1,
      dhcp_start TEXT DEFAULT '',
      dhcp_end TEXT DEFAULT '',
      nic_name TEXT DEFAULT '',
      status TEXT DEFAULT 'active',
      description TEXT DEFAULT '',
      created_at DATETIME DEFAULT (datetime('now'))
    );

    -- ==================== 安全组（虚拟防火墙） ====================
    CREATE TABLE IF NOT EXISTS security_groups (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      description TEXT DEFAULT '',
      created_at DATETIME DEFAULT (datetime('now'))
    );

    CREATE TABLE IF NOT EXISTS security_rules (
      id TEXT PRIMARY KEY,
      group_id TEXT NOT NULL,
      direction TEXT DEFAULT 'inbound',
      protocol TEXT DEFAULT 'tcp',
      port_range TEXT DEFAULT '',
      source TEXT DEFAULT '',
      action TEXT DEFAULT 'accept',
      priority INTEGER DEFAULT 100,
      description TEXT DEFAULT '',
      FOREIGN KEY (group_id) REFERENCES security_groups(id)
    );

    CREATE TABLE IF NOT EXISTS vm_security_groups (
      vm_id TEXT NOT NULL,
      group_id TEXT NOT NULL,
      PRIMARY KEY (vm_id, group_id)
    );

    -- ==================== MAC 地址池 ====================
    CREATE TABLE IF NOT EXISTS mac_pools (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      prefix TEXT DEFAULT '52:54:00',
      range_start TEXT DEFAULT '',
      range_end TEXT DEFAULT '',
      used_count INTEGER DEFAULT 0,
      total_count INTEGER DEFAULT 0,
      created_at DATETIME DEFAULT (datetime('now'))
    );

    -- ==================== 存储 ====================
    CREATE TABLE IF NOT EXISTS storage_pools (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      type TEXT DEFAULT 'local',
      total INTEGER DEFAULT 0,
      used INTEGER DEFAULT 0,
      status TEXT DEFAULT 'active',
      path TEXT DEFAULT '',
      host_id TEXT DEFAULT '',
      replica_count INTEGER DEFAULT 2,
      cache_disk TEXT DEFAULT '',
      description TEXT DEFAULT '',
      created_at DATETIME DEFAULT (datetime('now'))
    );

    CREATE TABLE IF NOT EXISTS volumes (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      pool_id TEXT,
      vm_id TEXT,
      size INTEGER DEFAULT 0,
      used INTEGER DEFAULT 0,
      format TEXT DEFAULT 'qcow2',
      disk_role TEXT DEFAULT 'data',
      status TEXT DEFAULT 'active',
      created_at DATETIME DEFAULT (datetime('now')),
      FOREIGN KEY (pool_id) REFERENCES storage_pools(id)
    );

    -- ==================== 备份 ====================
    CREATE TABLE IF NOT EXISTS backup_servers (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      address TEXT NOT NULL,
      port INTEGER DEFAULT 22,
      protocol TEXT DEFAULT 'ssh',
      username TEXT DEFAULT '',
      status TEXT DEFAULT 'active',
      total_space INTEGER DEFAULT 0,
      used_space INTEGER DEFAULT 0,
      created_at DATETIME DEFAULT (datetime('now'))
    );

    CREATE TABLE IF NOT EXISTS backups (
      id TEXT PRIMARY KEY,
      vm_id TEXT,
      server_id TEXT,
      name TEXT DEFAULT '',
      type TEXT DEFAULT 'full',
      size INTEGER DEFAULT 0,
      status TEXT DEFAULT 'completed',
      schedule TEXT DEFAULT '',
      read_speed_limit INTEGER DEFAULT 0,
      write_speed_limit INTEGER DEFAULT 0,
      started_at DATETIME,
      finished_at DATETIME,
      created_at DATETIME DEFAULT (datetime('now')),
      FOREIGN KEY (vm_id) REFERENCES vms(id),
      FOREIGN KEY (server_id) REFERENCES backup_servers(id)
    );

    -- ==================== 用户/角色/组 ====================
    CREATE TABLE IF NOT EXISTS users (
      id TEXT PRIMARY KEY,
      username TEXT NOT NULL UNIQUE,
      password_hash TEXT NOT NULL,
      display_name TEXT DEFAULT '',
      role TEXT DEFAULT 'user',
      email TEXT DEFAULT '',
      phone TEXT DEFAULT '',
      status TEXT DEFAULT 'active',
      group_id TEXT DEFAULT '',
      ldap_dn TEXT DEFAULT '',
      ip_restriction TEXT DEFAULT '',
      time_restriction TEXT DEFAULT '',
      last_login DATETIME,
      login_fail_count INTEGER DEFAULT 0,
      created_at DATETIME DEFAULT (datetime('now'))
    );

    CREATE TABLE IF NOT EXISTS user_groups (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      parent_id TEXT DEFAULT '',
      description TEXT DEFAULT '',
      created_at DATETIME DEFAULT (datetime('now'))
    );

    -- ==================== 事件/日志 ====================
    CREATE TABLE IF NOT EXISTS events (
      id TEXT PRIMARY KEY,
      type TEXT DEFAULT 'system',
      level TEXT DEFAULT 'info',
      resource_type TEXT DEFAULT '',
      resource_id TEXT DEFAULT '',
      resource_name TEXT DEFAULT '',
      action TEXT DEFAULT '',
      message TEXT DEFAULT '',
      detail TEXT DEFAULT '',
      user TEXT DEFAULT 'system',
      user_ip TEXT DEFAULT '',
      created_at DATETIME DEFAULT (datetime('now'))
    );

    -- ==================== 告警 ====================
    CREATE TABLE IF NOT EXISTS alerts (
      id TEXT PRIMARY KEY,
      level TEXT DEFAULT 'warning',
      type TEXT DEFAULT 'cpu',
      target_type TEXT DEFAULT 'vm',
      target_id TEXT DEFAULT '',
      target_name TEXT DEFAULT '',
      message TEXT DEFAULT '',
      value REAL DEFAULT 0,
      threshold REAL DEFAULT 0,
      status TEXT DEFAULT 'active',
      acknowledged INTEGER DEFAULT 0,
      acknowledged_by TEXT DEFAULT '',
      created_at DATETIME DEFAULT (datetime('now')),
      resolved_at DATETIME
    );

    CREATE TABLE IF NOT EXISTS alert_settings (
      id TEXT PRIMARY KEY,
      target_type TEXT DEFAULT 'vm',
      metric TEXT NOT NULL,
      threshold REAL DEFAULT 80,
      duration INTEGER DEFAULT 300,
      level TEXT DEFAULT 'warning',
      enabled INTEGER DEFAULT 1,
      notify_email INTEGER DEFAULT 0,
      created_at DATETIME DEFAULT (datetime('now'))
    );

    -- ==================== 任务 ====================
    CREATE TABLE IF NOT EXISTS tasks (
      id TEXT PRIMARY KEY,
      type TEXT NOT NULL,
      resource_type TEXT DEFAULT '',
      resource_id TEXT DEFAULT '',
      resource_name TEXT DEFAULT '',
      status TEXT DEFAULT 'pending',
      progress INTEGER DEFAULT 0,
      message TEXT DEFAULT '',
      user TEXT DEFAULT 'system',
      created_at DATETIME DEFAULT (datetime('now')),
      started_at DATETIME,
      finished_at DATETIME
    );

    -- ==================== 系统配置 ====================
    CREATE TABLE IF NOT EXISTS sys_config (
      key TEXT PRIMARY KEY,
      value TEXT DEFAULT '',
      description TEXT DEFAULT '',
      category TEXT DEFAULT 'general',
      updated_at DATETIME DEFAULT (datetime('now'))
    );

    -- ==================== 模板版本 ====================
    CREATE TABLE IF NOT EXISTS template_versions (
      id TEXT PRIMARY KEY,
      template_id TEXT NOT NULL,
      version INTEGER NOT NULL,
      description TEXT DEFAULT '',
      snapshot_name TEXT DEFAULT '',
      created_by TEXT DEFAULT 'admin',
      created_at DATETIME DEFAULT (datetime('now')),
      FOREIGN KEY (template_id) REFERENCES templates(id)
    );

    -- ==================== 集群管理 ====================
    CREATE TABLE IF NOT EXISTS clusters (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      description TEXT DEFAULT '',
      status TEXT DEFAULT 'active',
      created_at DATETIME DEFAULT (datetime('now'))
    );

    -- ==================== 审批流程 ====================
    CREATE TABLE IF NOT EXISTS approvals (
      id TEXT PRIMARY KEY,
      type TEXT NOT NULL,
      resource_type TEXT DEFAULT '',
      resource_id TEXT DEFAULT '',
      resource_name TEXT DEFAULT '',
      requester TEXT DEFAULT '',
      approver TEXT DEFAULT '',
      status TEXT DEFAULT 'pending',
      reason TEXT DEFAULT '',
      created_at DATETIME DEFAULT (datetime('now')),
      resolved_at DATETIME
    );

    -- ==================== 操作审计 ====================
    CREATE TABLE IF NOT EXISTS audit_logs (
      id TEXT PRIMARY KEY,
      user TEXT NOT NULL,
      user_ip TEXT DEFAULT '',
      action TEXT NOT NULL,
      resource_type TEXT DEFAULT '',
      resource_name TEXT DEFAULT '',
      detail TEXT DEFAULT '',
      result TEXT DEFAULT 'success',
      created_at DATETIME DEFAULT (datetime('now'))
    );

    -- ==================== 子网管理 ====================
    CREATE TABLE IF NOT EXISTS subnets (
      id TEXT PRIMARY KEY,
      network_id TEXT NOT NULL,
      name TEXT NOT NULL,
      cidr TEXT DEFAULT '',
      gateway TEXT DEFAULT '',
      dns1 TEXT DEFAULT '',
      dns2 TEXT DEFAULT '',
      dhcp_enabled INTEGER DEFAULT 0,
      dhcp_start TEXT DEFAULT '',
      dhcp_end TEXT DEFAULT '',
      vlan_id INTEGER DEFAULT 0,
      status TEXT DEFAULT 'active',
      created_at DATETIME DEFAULT (datetime('now')),
      FOREIGN KEY (network_id) REFERENCES networks(id)
    );

  `);

  // ==== SQLite ALTER TABLE migrations for existing databases ====
  const alterColumns = [
    { table: 'vms', column: 'cpu_mode', def: "TEXT DEFAULT 'host-passthrough'" },
    { table: 'vms', column: 'cpu_pinning', def: "TEXT DEFAULT ''" },
    { table: 'vms', column: 'cpu_hotplug', def: "INTEGER DEFAULT 0" },
    { table: 'vms', column: 'mem_hotplug', def: "INTEGER DEFAULT 0" },
    { table: 'vms', column: 'hugepages', def: "INTEGER DEFAULT 0" },
    { table: 'vms', column: 'bios_type', def: "TEXT DEFAULT 'seabios'" },
    { table: 'vms', column: 'video_type', def: "TEXT DEFAULT 'qxl'" },
    { table: 'vms', column: 'video_ram', def: "INTEGER DEFAULT 32" },
    { table: 'vms', column: 'boot_order', def: "TEXT DEFAULT 'hd,cdrom,network'" },
    { table: 'vms', column: 'ha_enabled', def: "INTEGER DEFAULT 0" },
    { table: 'vms', column: 'auto_migrate', def: "INTEGER DEFAULT 0" },
    { table: 'vms', column: 'expire_date', def: "TEXT DEFAULT ''" },
    { table: 'vms', column: 'disk_cache', def: "TEXT DEFAULT 'none'" },
    { table: 'sys_config', column: 'category', def: "TEXT DEFAULT ''" },
    { table: 'volumes', column: 'disk_role', def: "TEXT DEFAULT 'data'" },
    { table: 'hosts', column: 'cluster_id', def: "TEXT DEFAULT ''" },
  ];
  for (const { table, column, def } of alterColumns) {
    try {
      db.prepare(`ALTER TABLE ${table} ADD COLUMN ${column} ${def}`).run();
    } catch (e) {
      // Column already exists — ignore
    }
  }
}

function initDefaultData(db) {
  const bcrypt = require('bcryptjs');
  const { v4: uuidv4 } = require('uuid');

  // 检查是否已有数据
  const existing = db.prepare('SELECT id FROM users WHERE username = ?').get('admin');
  if (existing) return;

  const hash = bcrypt.hashSync('admin123', 10);

  // 三权分立默认账号
  db.prepare(`INSERT INTO users (id, username, password_hash, display_name, role, status) VALUES (?, ?, ?, ?, ?, ?)`).run(uuidv4(), 'admin', hash, '系统管理员', 'sysadmin', 'active');
  db.prepare(`INSERT INTO users (id, username, password_hash, display_name, role, status) VALUES (?, ?, ?, ?, ?, ?)`).run(uuidv4(), 'secadmin', bcrypt.hashSync('admin123', 10), '安全管理员', 'secadmin', 'active');
  db.prepare(`INSERT INTO users (id, username, password_hash, display_name, role, status) VALUES (?, ?, ?, ?, ?, ?)`).run(uuidv4(), 'auditor', bcrypt.hashSync('admin123', 10), '安全审计员', 'secauditor', 'active');

  // 默认告警设置
  const alertDefaults = [
    { metric: 'cpu_usage', threshold: 80, target_type: 'vm', level: 'warning' },
    { metric: 'cpu_usage', threshold: 95, target_type: 'vm', level: 'critical' },
    { metric: 'mem_usage', threshold: 85, target_type: 'vm', level: 'warning' },
    { metric: 'mem_usage', threshold: 95, target_type: 'vm', level: 'critical' },
    { metric: 'disk_usage', threshold: 85, target_type: 'vm', level: 'warning' },
    { metric: 'disk_usage', threshold: 95, target_type: 'vm', level: 'critical' },
    { metric: 'cpu_usage', threshold: 80, target_type: 'host', level: 'warning' },
    { metric: 'mem_usage', threshold: 85, target_type: 'host', level: 'warning' },
    { metric: 'disk_usage', threshold: 90, target_type: 'host', level: 'warning' },
  ];
  for (const a of alertDefaults) {
    db.prepare(`INSERT INTO alert_settings (id, target_type, metric, threshold, level) VALUES (?, ?, ?, ?, ?)`).run(uuidv4(), a.target_type, a.metric, a.threshold, a.level);
  }

  // 默认系统配置
  const sysDefaults = [
    { key: 'cluster_name', value: 'KVM Cloud 集群', description: '集群名称' },
    { key: 'ntp_server', value: 'ntp.aliyun.com', description: 'NTP时间同步服务器' },
    { key: 'user_self_register', value: 'false', description: '允许用户自助注册' },
    { key: 'login_fail_lock_count', value: '5', description: '登录失败锁定次数' },
    { key: 'session_timeout', value: '30', description: '会话超时(分钟)' },
    { key: 'default_protocol', value: 'UDAP', description: '默认远程协议' },
    { key: 'watermark_enabled', value: 'false', description: '全局水印开关' },
    { key: 'screen_record_enabled', value: 'false', description: '全局录屏开关' },
    // ===== 对标KSVD V7 全局策略 =====
    { key: 'ksm_enabled', value: 'false', description: '启用KSM内存超配(内核相同页合并)' },
    { key: 'secure_udap', value: 'false', description: '启用安全UDAP连接(SSL加密桌面协议)' },
    { key: 'cache_io_enabled', value: 'false', description: '启用缓存I/O(本地镜像缓存)' },
    { key: 'vm_scheduling', value: 'true', description: '虚拟机调度开关' },
    { key: 'boot_animation', value: 'true', description: '显示虚拟机开机动画' },
    { key: 'load_balance_mode', value: 'optimal', description: '负载均衡模式(optimal/cpu/session/memory/disk_io/storage)' },
    { key: 'auto_logout_timeout', value: '30', description: '超时注销(分钟: 5/10/15/30/60/240/1440)' },
    { key: 'network_speed_test', value: 'false', description: '网络测速开关' },
    { key: 'network_speed_limit', value: '10', description: '网络测速进程上限' },
    { key: 'user_netdisk', value: 'false', description: '用户网盘开关' },
    { key: 'gpu_allocation_mode', value: 'performance', description: '显卡分配模式(performance/density)' },
    { key: 'vgpu_scheduling', value: 'preempt', description: 'NVIDIA vGPU调度策略(preempt/dynamic/absolute)' },
    { key: 'desktop_refresh_interval', value: '10', description: '桌面状态刷新间隔(秒: 3/5/10/30/180)' },
    { key: 'allow_storage_on_mgmt', value: 'false', description: '允许镜像/VM存储至管理卷' },
    { key: 'usb_redirect_enabled', value: 'true', description: 'USB重定向管控开关' },
    { key: 'terminal_request_interval', value: '60', description: '终端请求间隔(秒: 30/60/120/180)' },
    { key: 'cert_type', value: 'SSL', description: '加密证书类型(SSL/GMSSL)' },
    { key: 'mem_reclaim_threshold', value: '30', description: '内存回收阈值(%)' },
    { key: 'mem_return_threshold', value: '70', description: '内存返还阈值(%)' },
    { key: 'disk_overcommit', value: 'false', description: '虚拟磁盘超配开关' },
    { key: 'disk_overcommit_reserve', value: '50', description: '虚拟磁盘超配预留(GB)' },
    { key: 'ha_enabled', value: 'true', description: '全局HA高可用开关' },
    { key: 'drs_enabled', value: 'false', description: '分布式资源调度(DRS)开关' },
    { key: 'drs_mode', value: 'manual', description: 'DRS模式(manual/semi_auto/auto)' },
    { key: 'dpm_enabled', value: 'false', description: '智能电源管理(DPM)开关' },
  ];
  for (const c of sysDefaults) {
    db.prepare(`INSERT OR IGNORE INTO sys_config (key, value, description) VALUES (?, ?, ?)`).run(c.key, c.value, c.description);
  }

  console.log('[DB] 已创建默认账号: admin/secadmin/auditor (密码: admin123)');
  console.log('[DB] 已创建默认告警设置和系统配置');
}

module.exports = { initSchema, initDefaultData };
