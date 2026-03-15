// Mock 驱动 - 全模拟模式，用于 Windows 开发调试
// 覆盖麒麟信安云V7R023全功能，所有操作真实修改 SQLite 数据

const { v4: uuidv4 } = require('uuid');
const VirtDriver = require('./driver');

function randomMAC() {
  const hex = () => Math.floor(Math.random() * 256).toString(16).padStart(2, '0');
  return `52:54:00:${hex()}:${hex()}:${hex()}`;
}

class MockDriver extends VirtDriver {
  constructor(db) {
    super('mock');
    this.db = db;
  }

  init() {
    this._initMockData();
  }

  _initMockData() {
    const count = this.db.prepare('SELECT COUNT(*) as c FROM hosts').get();
    if (count && count.c > 0) return;

    // ===== 宿主机 =====
    const hosts = [
      { id: uuidv4(), name: 'host-node-01', ip: '192.168.100.11', bmc_ip: '192.168.101.11', role: 'CM_VDI', cpu_model: 'Intel Xeon Gold 6248', cpu_total: 32, cpu_used: 12, mem_total: 65536, mem_used: 24576, disk_total: 2048, disk_used: 680, net_speed: 10000, status: 'online', arch: 'x86_64', os: 'Kylin Linux V10 SP1', kernel: '4.19.90-24.4.v2101.ky10.x86_64', uptime: 864000, vm_count: 3 },
      { id: uuidv4(), name: 'host-node-02', ip: '192.168.100.12', bmc_ip: '192.168.101.12', role: 'VDI', cpu_model: 'Intel Xeon Gold 6248', cpu_total: 32, cpu_used: 18, mem_total: 65536, mem_used: 38400, disk_total: 2048, disk_used: 920, net_speed: 10000, status: 'online', arch: 'x86_64', os: 'Kylin Linux V10 SP1', kernel: '4.19.90-24.4.v2101.ky10.x86_64', uptime: 864000, vm_count: 2 },
      { id: uuidv4(), name: 'host-node-03', ip: '192.168.100.13', bmc_ip: '192.168.101.13', role: 'VDI', cpu_model: 'Kunpeng 920', cpu_total: 64, cpu_used: 8, mem_total: 131072, mem_used: 16384, disk_total: 4096, disk_used: 512, net_speed: 25000, status: 'online', arch: 'aarch64', os: 'Kylin Linux V10 SP1 ARM', kernel: '4.19.90-24.4.v2101.ky10.aarch64', uptime: 432000, vm_count: 1 },
    ];
    const insertHost = this.db.prepare(`INSERT INTO hosts (id,name,ip,bmc_ip,role,cpu_model,cpu_total,cpu_used,mem_total,mem_used,disk_total,disk_used,net_speed,status,arch,os,kernel,uptime,vm_count) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)`);
    for (const h of hosts) {
      insertHost.run(h.id, h.name, h.ip, h.bmc_ip, h.role, h.cpu_model, h.cpu_total, h.cpu_used, h.mem_total, h.mem_used, h.disk_total, h.disk_used, h.net_speed, h.status, h.arch, h.os, h.kernel, h.uptime, h.vm_count);
    }

    // ===== 黄金镜像/模板 =====
    const templates = [
      { id: uuidv4(), name: 'win10-desktop', title: 'Windows 10 桌面版', os_type: 'windows', os_version: 'Windows 10 Enterprise LTSC', arch: 'x86_64', cpu: 4, memory: 4096, disk: 60, status: 'published', run_mode: 'VDI', version: 3 },
      { id: uuidv4(), name: 'kylin-v10-desktop', title: '银河麒麟 V10 桌面版', os_type: 'linux', os_version: 'Kylin V10 SP1', arch: 'x86_64', cpu: 2, memory: 2048, disk: 40, status: 'published', run_mode: 'VDI', version: 5 },
      { id: uuidv4(), name: 'kylin-v10-arm', title: '银河麒麟 V10 ARM版', os_type: 'linux', os_version: 'Kylin V10 SP1 ARM', arch: 'aarch64', cpu: 2, memory: 2048, disk: 40, status: 'published', run_mode: 'VDI', version: 2 },
      { id: uuidv4(), name: 'uos-desktop', title: 'UOS 桌面版', os_type: 'linux', os_version: 'UOS Desktop V20', arch: 'x86_64', cpu: 2, memory: 4096, disk: 50, status: 'published', run_mode: 'VDI', version: 1 },
      { id: uuidv4(), name: 'centos79-server', title: 'CentOS 7.9 服务器', os_type: 'linux', os_version: 'CentOS 7.9', arch: 'x86_64', cpu: 4, memory: 8192, disk: 100, status: 'published', run_mode: 'VDI', version: 2 },
      { id: uuidv4(), name: 'kylin-v10-draft', title: '银河麒麟测试镜像', os_type: 'linux', os_version: 'Kylin V10', arch: 'x86_64', cpu: 2, memory: 2048, disk: 40, status: 'maintaining', run_mode: 'VDI', version: 1 },
    ];
    const insertTpl = this.db.prepare(`INSERT INTO templates (id,name,title,os_type,os_version,arch,cpu,memory,disk,status,run_mode,version,description) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)`);
    for (const t of templates) {
      insertTpl.run(t.id, t.name, t.title, t.os_type, t.os_version, t.arch, t.cpu, t.memory, t.disk, t.status, t.run_mode, t.version, `${t.title} 标准黄金镜像`);
    }

    // ===== 桌面规格 =====
    const specs = [
      { id: uuidv4(), name: '标准办公桌面', cpu: 2, max_cpu: 4, memory: 2048, max_memory: 4096, system_disk: 40, user_disk: 20, network_type: 'bridged', protocol: 'UDAP' },
      { id: uuidv4(), name: '高性能桌面', cpu: 4, max_cpu: 8, memory: 8192, max_memory: 16384, system_disk: 60, user_disk: 50, network_type: 'bridged', protocol: 'UDAP' },
      { id: uuidv4(), name: 'GPU图形桌面', cpu: 4, max_cpu: 8, memory: 8192, max_memory: 16384, system_disk: 60, user_disk: 100, network_type: 'bridged', protocol: 'UDAP', gpu_type: 'vGPU', gpu_count: 1 },
      { id: uuidv4(), name: '轻量桌面', cpu: 1, max_cpu: 2, memory: 1024, max_memory: 2048, system_disk: 30, user_disk: 10, network_type: 'bridged', protocol: 'UDAP' },
    ];
    const insertSpec = this.db.prepare(`INSERT INTO desktop_specs (id,name,cpu,max_cpu,memory,max_memory,system_disk,user_disk,network_type,protocol,gpu_type,gpu_count,description) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)`);
    for (const s of specs) {
      insertSpec.run(s.id, s.name, s.cpu, s.max_cpu, s.memory, s.max_memory, s.system_disk, s.user_disk || 0, s.network_type, s.protocol, s.gpu_type || '', s.gpu_count || 0, `${s.name} 规格`);
    }

    // ===== 发布规则 =====
    const rules = [
      { id: uuidv4(), name: '研发部-麒麟桌面', template_id: templates[1].id, spec_id: specs[1].id, target_type: 'group', target_name: '研发部', desktop_type: 'static', snapshot_enabled: 1, max_snapshots: 5 },
      { id: uuidv4(), name: '行政部-Win10桌面', template_id: templates[0].id, spec_id: specs[0].id, target_type: 'group', target_name: '行政部', desktop_type: 'dynamic', snapshot_enabled: 0 },
      { id: uuidv4(), name: 'GPU设计桌面', template_id: templates[0].id, spec_id: specs[2].id, target_type: 'user', target_name: '设计师A', desktop_type: 'static', snapshot_enabled: 1, max_snapshots: 3 },
    ];
    const insertRule = this.db.prepare(`INSERT INTO publish_rules (id,name,template_id,spec_id,target_type,target_name,desktop_type,snapshot_enabled,max_snapshots,status) VALUES (?,?,?,?,?,?,?,?,?,?)`);
    for (const r of rules) {
      insertRule.run(r.id, r.name, r.template_id, r.spec_id, r.target_type, r.target_name, r.desktop_type, r.snapshot_enabled, r.max_snapshots, 'active');
    }

    // ===== 网络 =====
    const networks = [
      { id: uuidv4(), name: 'vswitch-mgmt', type: 'bridge', bridge: 'br-mgmt', vlan: 100, subnet: '192.168.100.0/24', gateway: '192.168.100.1', dns: '114.114.114.114', dhcp_enabled: 0, nic_name: 'eth0' },
      { id: uuidv4(), name: 'vswitch-desktop', type: 'bridge', bridge: 'br-desktop', vlan: 200, subnet: '192.168.200.0/24', gateway: '192.168.200.1', dns: '114.114.114.114', dhcp_enabled: 1, dhcp_start: '192.168.200.100', dhcp_end: '192.168.200.250', nic_name: 'eth1' },
      { id: uuidv4(), name: 'vswitch-storage', type: 'bridge', bridge: 'br-storage', vlan: 300, subnet: '10.0.30.0/24', gateway: '10.0.30.1', dns: '', dhcp_enabled: 0, nic_name: 'eth2' },
      { id: uuidv4(), name: 'vnet-nat', type: 'nat', bridge: 'virbr0', vlan: 0, subnet: '172.16.0.0/24', gateway: '172.16.0.1', dns: '8.8.8.8', dhcp_enabled: 1, dhcp_start: '172.16.0.100', dhcp_end: '172.16.0.200', nic_name: '' },
    ];
    const insertNet = this.db.prepare(`INSERT INTO networks (id,name,type,bridge,vlan,subnet,gateway,dns,dhcp_enabled,dhcp_start,dhcp_end,nic_name,status) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)`);
    for (const n of networks) {
      insertNet.run(n.id, n.name, n.type, n.bridge, n.vlan, n.subnet, n.gateway, n.dns, n.dhcp_enabled, n.dhcp_start || '', n.dhcp_end || '', n.nic_name, 'active');
    }

    // ===== 安全组 =====
    const sg1 = uuidv4();
    const sg2 = uuidv4();
    this.db.prepare(`INSERT INTO security_groups (id,name,description) VALUES (?,?,?)`).run(sg1, '默认安全组', '允许所有出站，禁止外部入站');
    this.db.prepare(`INSERT INTO security_groups (id,name,description) VALUES (?,?,?)`).run(sg2, 'Web服务安全组', '允许80/443入站');
    this.db.prepare(`INSERT INTO security_rules (id,group_id,direction,protocol,port_range,source,action,priority,description) VALUES (?,?,?,?,?,?,?,?,?)`).run(uuidv4(), sg1, 'outbound', 'all', '', '', 'accept', 100, '允许所有出站');
    this.db.prepare(`INSERT INTO security_rules (id,group_id,direction,protocol,port_range,source,action,priority,description) VALUES (?,?,?,?,?,?,?,?,?)`).run(uuidv4(), sg1, 'inbound', 'icmp', '', '', 'accept', 90, '允许ICMP');
    this.db.prepare(`INSERT INTO security_rules (id,group_id,direction,protocol,port_range,source,action,priority,description) VALUES (?,?,?,?,?,?,?,?,?)`).run(uuidv4(), sg2, 'inbound', 'tcp', '80', '0.0.0.0/0', 'accept', 100, 'HTTP');
    this.db.prepare(`INSERT INTO security_rules (id,group_id,direction,protocol,port_range,source,action,priority,description) VALUES (?,?,?,?,?,?,?,?,?)`).run(uuidv4(), sg2, 'inbound', 'tcp', '443', '0.0.0.0/0', 'accept', 100, 'HTTPS');

    // ===== MAC 地址池 =====
    this.db.prepare(`INSERT INTO mac_pools (id,name,prefix,range_start,range_end,total_count) VALUES (?,?,?,?,?,?)`).run(uuidv4(), '默认MAC池', '52:54:00', '52:54:00:00:00:01', '52:54:00:FF:FF:FE', 16777214);

    // ===== 存储池 =====
    const pools = [
      { id: uuidv4(), name: 'distributed-pool-01', type: 'distributed', total: 10240, used: 3200, path: '/data/distributed', host_id: '', replica_count: 2, cache_disk: '/dev/sdb' },
      { id: uuidv4(), name: 'local-pool-node01', type: 'local', total: 2048, used: 680, path: '/data/local', host_id: hosts[0].id, replica_count: 1 },
      { id: uuidv4(), name: 'nfs-backup', type: 'nfs', total: 8192, used: 1536, path: '192.168.100.200:/nfs-share', host_id: '', replica_count: 1 },
      { id: uuidv4(), name: 'iscsi-san-01', type: 'iscsi', total: 5120, used: 2048, path: '192.168.100.201:3260', host_id: '', replica_count: 1 },
    ];
    const insertPool = this.db.prepare(`INSERT INTO storage_pools (id,name,type,total,used,status,path,host_id,replica_count,cache_disk) VALUES (?,?,?,?,?,?,?,?,?,?)`);
    for (const p of pools) {
      insertPool.run(p.id, p.name, p.type, p.total, p.used, 'active', p.path, p.host_id || '', p.replica_count, p.cache_disk || '');
    }

    // ===== 虚拟机 =====
    const vms = [
      { id: uuidv4(), name: 'desktop-zhangsan', host_id: hosts[0].id, template_id: templates[0].id, spec_id: specs[0].id, cpu: 4, max_cpu: 4, memory: 4096, max_memory: 8192, disk: 60, status: 'running', ip: '192.168.200.101', mac: randomMAC(), os_type: 'windows', os_version: 'Windows 10', owner: '张三', vnc_port: 5901 },
      { id: uuidv4(), name: 'desktop-lisi', host_id: hosts[0].id, template_id: templates[1].id, spec_id: specs[0].id, cpu: 2, max_cpu: 4, memory: 2048, max_memory: 4096, disk: 40, status: 'running', ip: '192.168.200.102', mac: randomMAC(), os_type: 'linux', os_version: 'Kylin V10', owner: '李四', vnc_port: 5902 },
      { id: uuidv4(), name: 'desktop-wangwu', host_id: hosts[1].id, template_id: templates[0].id, spec_id: specs[1].id, cpu: 4, max_cpu: 8, memory: 8192, max_memory: 16384, disk: 60, status: 'stopped', ip: '192.168.200.103', mac: randomMAC(), os_type: 'windows', os_version: 'Windows 10', owner: '王五', vnc_port: 0 },
      { id: uuidv4(), name: 'server-web-01', host_id: hosts[1].id, template_id: templates[4].id, spec_id: specs[1].id, cpu: 8, max_cpu: 8, memory: 16384, max_memory: 16384, disk: 200, status: 'running', ip: '192.168.200.201', mac: randomMAC(), os_type: 'linux', os_version: 'CentOS 7.9', owner: 'admin', vnc_port: 5903 },
      { id: uuidv4(), name: 'desktop-zhaoliu', host_id: hosts[2].id, template_id: templates[2].id, spec_id: specs[0].id, cpu: 2, max_cpu: 4, memory: 2048, max_memory: 4096, disk: 40, status: 'running', ip: '192.168.200.104', mac: randomMAC(), os_type: 'linux', os_version: 'Kylin V10 ARM', owner: '赵六', vnc_port: 5904 },
      { id: uuidv4(), name: 'desktop-sunqi', host_id: hosts[0].id, template_id: templates[3].id, spec_id: specs[3].id, cpu: 1, max_cpu: 2, memory: 1024, max_memory: 2048, disk: 30, status: 'suspended', ip: '192.168.200.105', mac: randomMAC(), os_type: 'linux', os_version: 'UOS V20', owner: '孙七', vnc_port: 5905 },
      { id: uuidv4(), name: 'desktop-deleted', host_id: hosts[0].id, template_id: templates[1].id, spec_id: specs[0].id, cpu: 2, max_cpu: 4, memory: 2048, max_memory: 4096, disk: 40, status: 'stopped', ip: '192.168.200.106', mac: randomMAC(), os_type: 'linux', os_version: 'Kylin V10', owner: '已离职员工', vnc_port: 0, deleted: 1 },
    ];
    const insertVM = this.db.prepare(`INSERT INTO vms (id,name,host_id,template_id,spec_id,cpu,max_cpu,memory,max_memory,disk,status,ip,mac,os_type,os_version,owner,vnc_port,deleted,created_at,updated_at) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,datetime('now'),datetime('now'))`);
    for (const v of vms) {
      insertVM.run(v.id, v.name, v.host_id, v.template_id, v.spec_id, v.cpu, v.max_cpu, v.memory, v.max_memory, v.disk, v.status, v.ip, v.mac, v.os_type, v.os_version, v.owner, v.vnc_port, v.deleted || 0);
    }

    // 为每个VM创建磁盘记录
    for (const v of vms) {
      this.db.prepare(`INSERT INTO vm_disks (id,vm_id,name,size,type,bus,format,pool_id) VALUES (?,?,?,?,?,?,?,?)`).run(uuidv4(), v.id, `${v.name}-sys`, v.disk, 'system', 'virtio', 'qcow2', pools[0].id);
      if (specs.find(s => s.id === v.spec_id)?.user_disk > 0) {
        const userDiskSize = specs.find(s => s.id === v.spec_id).user_disk;
        this.db.prepare(`INSERT INTO vm_disks (id,vm_id,name,size,type,bus,format,pool_id) VALUES (?,?,?,?,?,?,?,?)`).run(uuidv4(), v.id, `${v.name}-data`, userDiskSize, 'data', 'virtio', 'qcow2', pools[0].id);
      }
      // 创建网卡记录
      this.db.prepare(`INSERT INTO vm_nics (id,vm_id,network_id,mac,model,ip,type) VALUES (?,?,?,?,?,?,?)`).run(uuidv4(), v.id, networks[1].id, v.mac, 'virtio', v.ip, 'bridged');
    }

    // 为部分VM关联安全组
    this.db.prepare(`INSERT INTO vm_security_groups (vm_id,group_id) VALUES (?,?)`).run(vms[0].id, sg1);
    this.db.prepare(`INSERT INTO vm_security_groups (vm_id,group_id) VALUES (?,?)`).run(vms[3].id, sg2);

    // ===== 快照 =====
    const now = new Date().toISOString().replace('T', ' ').slice(0, 19);
    this.db.prepare(`INSERT INTO snapshots (id,vm_id,name,description,size,status,is_current,created_by) VALUES (?,?,?,?,?,?,?,?)`).run(uuidv4(), vms[0].id, '初始安装完成', '系统安装并激活', 2048, 'active', 0, 'admin');
    this.db.prepare(`INSERT INTO snapshots (id,vm_id,name,description,size,status,is_current,created_by) VALUES (?,?,?,?,?,?,?,?)`).run(uuidv4(), vms[0].id, '安装Office后', '安装Office 2019', 3072, 'active', 1, 'admin');
    this.db.prepare(`INSERT INTO snapshots (id,vm_id,name,description,size,status,is_current,created_by) VALUES (?,?,?,?,?,?,?,?)`).run(uuidv4(), vms[1].id, '基础环境配置', 'WPS + 输入法安装完成', 1536, 'active', 1, 'admin');

    // ===== 快照策略 =====
    this.db.prepare(`INSERT INTO snapshot_policies (id,name,cron_expr,max_keep,cpu_limit,status) VALUES (?,?,?,?,?,?)`).run(uuidv4(), '每日凌晨快照', '0 2 * * *', 7, 30, 'active');
    this.db.prepare(`INSERT INTO snapshot_policies (id,name,cron_expr,max_keep,cpu_limit,status) VALUES (?,?,?,?,?,?)`).run(uuidv4(), '每周日全量快照', '0 3 * * 0', 4, 50, 'active');

    // ===== 备份服务器 =====
    const bkServer = uuidv4();
    this.db.prepare(`INSERT INTO backup_servers (id,name,address,port,protocol,username,status,total_space,used_space) VALUES (?,?,?,?,?,?,?,?,?)`).run(bkServer, '备份服务器-01', '192.168.100.250', 22, 'ssh', 'backup', 'active', 20480, 4096);

    // ===== 备份记录 =====
    this.db.prepare(`INSERT INTO backups (id,vm_id,server_id,name,type,size,status,started_at,finished_at) VALUES (?,?,?,?,?,?,?,datetime('now','-2 days'),datetime('now','-2 days','+30 minutes'))`).run(uuidv4(), vms[0].id, bkServer, 'desktop-zhangsan-全量备份', 'full', 5120, 'completed');
    this.db.prepare(`INSERT INTO backups (id,vm_id,server_id,name,type,size,status,started_at,finished_at) VALUES (?,?,?,?,?,?,?,datetime('now','-1 days'),datetime('now','-1 days','+10 minutes'))`).run(uuidv4(), vms[3].id, bkServer, 'server-web-01-全量备份', 'full', 10240, 'completed');

    // ===== 用户组 =====
    const g1 = uuidv4(), g2 = uuidv4(), g3 = uuidv4();
    this.db.prepare(`INSERT INTO user_groups (id,name,parent_id,description) VALUES (?,?,?,?)`).run(g1, '研发部', '', '软件研发部门');
    this.db.prepare(`INSERT INTO user_groups (id,name,parent_id,description) VALUES (?,?,?,?)`).run(g2, '行政部', '', '行政办公部门');
    this.db.prepare(`INSERT INTO user_groups (id,name,parent_id,description) VALUES (?,?,?,?)`).run(g3, '研发一组', g1, '研发部下属组');

    // ===== 初始事件 =====
    this._addEvent('system', '', '', '', 'info', 'system_start', '系统启动', '虚拟化管理平台启动', 'system');
    this._addEvent('host', hosts[0].id, hosts[0].name, '', 'info', 'host_online', '主机上线', `${hosts[0].name} 已上线`, 'system');
    this._addEvent('host', hosts[1].id, hosts[1].name, '', 'info', 'host_online', '主机上线', `${hosts[1].name} 已上线`, 'system');
    this._addEvent('host', hosts[2].id, hosts[2].name, '', 'info', 'host_online', '主机上线', `${hosts[2].name} 已上线`, 'system');
    this._addEvent('vm', vms[0].id, vms[0].name, '', 'info', 'vm_start', '虚拟机启动', `${vms[0].name} 已启动`, 'admin');

    // ===== 初始告警 =====
    this.db.prepare(`INSERT INTO alerts (id,level,type,target_type,target_id,target_name,message,value,threshold,status) VALUES (?,?,?,?,?,?,?,?,?,?)`).run(uuidv4(), 'warning', 'mem_usage', 'host', hosts[1].id, hosts[1].name, '内存使用率超过阈值', 58.6, 55, 'active');
    this.db.prepare(`INSERT INTO alerts (id,level,type,target_type,target_id,target_name,message,value,threshold,status) VALUES (?,?,?,?,?,?,?,?,?,?)`).run(uuidv4(), 'warning', 'disk_usage', 'storage', pools[0].id, pools[0].name, '存储使用率: 31.25%，接近告警阈值', 31.25, 35, 'resolved');

    console.log('[Mock] 已初始化完整模拟数据: 3台宿主机, 6个模板, 7台虚拟机(含1回收站), 4桌面规格, 3发布规则, 4网络, 2安全组, 4存储池, 1备份服务器');
  }

  // ===========================
  //  宿主机管理
  // ===========================
  async listHosts() {
    return this.db.prepare('SELECT * FROM hosts ORDER BY name').all();
  }

  async getHost(id) {
    return this.db.prepare('SELECT * FROM hosts WHERE id = ?').get(id);
  }

  async addHost(config) {
    const id = uuidv4();
    this.db.prepare(`INSERT INTO hosts (id,name,ip,bmc_ip,role,cpu_model,cpu_total,mem_total,disk_total,status,arch,os) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)`).run(
      id, config.name, config.ip, config.bmc_ip || '', config.role || 'VDI', config.cpu_model || 'Unknown', config.cpu_total || 16, config.mem_total || 32768, config.disk_total || 1024, 'online', config.arch || 'x86_64', config.os || 'Kylin Linux V10');
    this._addEvent('host', id, config.name, '', 'info', 'host_add', '添加主机', `添加主机 ${config.name} (${config.ip})`, 'admin');
    return this.getHost(id);
  }

  async removeHost(id) {
    const host = await this.getHost(id);
    if (!host) throw new Error('主机不存在');
    const vmCount = this.db.prepare('SELECT COUNT(*) as c FROM vms WHERE host_id = ? AND deleted = 0').get(id);
    if (vmCount && vmCount.c > 0) throw new Error('主机上还有虚拟机，请先迁移');
    this.db.prepare('DELETE FROM hosts WHERE id = ?').run(id);
    this._addEvent('host', id, host.name, '', 'warning', 'host_remove', '移除主机', `移除主机 ${host.name}`, 'admin');
    return { success: true };
  }

  async rebootHost(id) {
    const host = await this.getHost(id);
    if (!host) throw new Error('主机不存在');
    this.db.prepare("UPDATE hosts SET status = 'rebooting' WHERE id = ?").run(id);
    this._addEvent('host', id, host.name, '', 'warning', 'host_reboot', '重启主机', `重启主机 ${host.name}`, 'admin');
    // 模拟重启完成
    setTimeout(() => {
      this.db.prepare("UPDATE hosts SET status = 'online', uptime = 0 WHERE id = ?").run(id);
    }, 3000);
    return { success: true, message: '主机正在重启' };
  }

  async shutdownHost(id) {
    const host = await this.getHost(id);
    if (!host) throw new Error('主机不存在');
    this.db.prepare("UPDATE hosts SET status = 'offline' WHERE id = ?").run(id);
    this._addEvent('host', id, host.name, '', 'warning', 'host_shutdown', '关闭主机', `关闭主机 ${host.name}`, 'admin');
    return { success: true };
  }

  async updateHostConfig(id, config) {
    const host = await this.getHost(id);
    if (!host) throw new Error('主机不存在');
    const fields = [];
    const values = [];
    if (config.ip) { fields.push('ip = ?'); values.push(config.ip); }
    if (config.role) { fields.push('role = ?'); values.push(config.role); }
    if (config.ntp_server !== undefined) { fields.push('ntp_server = ?'); values.push(config.ntp_server); }
    if (config.ha_vip !== undefined) { fields.push('ha_vip = ?'); values.push(config.ha_vip); }
    if (fields.length === 0) throw new Error('无可更新字段');
    values.push(id);
    this.db.prepare(`UPDATE hosts SET ${fields.join(', ')} WHERE id = ?`).run(...values);
    this._addEvent('host', id, host.name, '', 'info', 'host_update', '更新主机配置', `更新主机 ${host.name} 配置`, 'admin');
    return this.getHost(id);
  }

  async getHostStats(id) {
    const host = await this.getHost(id);
    if (!host) throw new Error('主机不存在');
    const isOnline = host.status === 'online';
    return {
      cpu_usage: isOnline ? Math.random() * 50 + 10 : 0,
      mem_usage: isOnline ? (host.mem_used / host.mem_total * 100) + (Math.random() * 5 - 2.5) : 0,
      disk_read: isOnline ? Math.floor(Math.random() * 200000) : 0,
      disk_write: isOnline ? Math.floor(Math.random() * 100000) : 0,
      net_rx: isOnline ? Math.floor(Math.random() * 50000) : 0,
      net_tx: isOnline ? Math.floor(Math.random() * 30000) : 0,
      load_avg: isOnline ? [Math.random() * 4 + 1, Math.random() * 3 + 1, Math.random() * 2 + 0.5].map(v => +v.toFixed(2)) : [0, 0, 0],
      uptime: host.uptime + Math.floor(Math.random() * 100),
    };
  }

  // ===========================
  //  虚拟机管理
  // ===========================
  async listVMs(includeDeleted = false) {
    const where = includeDeleted ? '' : 'WHERE v.deleted = 0';
    return this.db.prepare(`
      SELECT v.*, h.name as host_name, t.title as template_name
      FROM vms v LEFT JOIN hosts h ON v.host_id = h.id LEFT JOIN templates t ON v.template_id = t.id
      ${where} ORDER BY v.created_at DESC
    `).all();
  }

  async listDeletedVMs() {
    return this.db.prepare(`
      SELECT v.*, h.name as host_name, t.title as template_name
      FROM vms v LEFT JOIN hosts h ON v.host_id = h.id LEFT JOIN templates t ON v.template_id = t.id
      WHERE v.deleted = 1 ORDER BY v.deleted_at DESC
    `).all();
  }

  async getVM(id) {
    const vm = this.db.prepare(`
      SELECT v.*, h.name as host_name, t.title as template_name
      FROM vms v LEFT JOIN hosts h ON v.host_id = h.id LEFT JOIN templates t ON v.template_id = t.id
      WHERE v.id = ?
    `).get(id);
    if (!vm) return null;
    // 附加磁盘、网卡、安全组信息
    vm.disks = this.db.prepare('SELECT * FROM vm_disks WHERE vm_id = ?').all(id);
    vm.nics = this.db.prepare('SELECT n.*, net.name as network_name FROM vm_nics n LEFT JOIN networks net ON n.network_id = net.id WHERE n.vm_id = ?').all(id);
    vm.security_groups = this.db.prepare('SELECT sg.* FROM security_groups sg JOIN vm_security_groups vsg ON sg.id = vsg.group_id WHERE vsg.vm_id = ?').all(id);
    return vm;
  }

  async createVM(config) {
    const id = uuidv4();
    const ip = config.ip || `192.168.200.${Math.floor(Math.random() * 150) + 100}`;
    const mac = randomMAC();
    const vnc_port = 5900 + Math.floor(Math.random() * 100);

    this.db.prepare(`INSERT INTO vms (id,name,host_id,template_id,spec_id,cpu,max_cpu,memory,max_memory,disk,status,ip,mac,os_type,os_version,owner,vnc_port,created_at,updated_at)
      VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,datetime('now'),datetime('now'))`)
      .run(id, config.name, config.host_id, config.template_id || '', config.spec_id || '', config.cpu || 2, config.max_cpu || config.cpu || 4, config.memory || 2048, config.max_memory || config.memory || 4096, config.disk || 40, 'stopped', ip, mac, config.os_type || 'linux', config.os_version || '', config.owner || 'admin', vnc_port);

    // 创建系统盘
    this.db.prepare(`INSERT INTO vm_disks (id,vm_id,name,size,type,bus,format) VALUES (?,?,?,?,?,?,?)`).run(uuidv4(), id, `${config.name}-sys`, config.disk || 40, 'system', 'virtio', 'qcow2');
    // 创建默认网卡
    const defaultNet = this.db.prepare("SELECT id FROM networks WHERE type = 'bridge' AND vlan = 200").get();
    this.db.prepare(`INSERT INTO vm_nics (id,vm_id,network_id,mac,model,ip,type) VALUES (?,?,?,?,?,?,?)`).run(uuidv4(), id, defaultNet ? defaultNet.id : '', mac, 'virtio', ip, config.network_type || 'bridged');

    // 更新宿主机 VM计数
    this.db.prepare('UPDATE hosts SET vm_count = vm_count + 1 WHERE id = ?').run(config.host_id);

    this._addTask('create_vm', 'vm', id, config.name, 100, 'completed', `虚拟机 ${config.name} 创建完成`);
    this._addEvent('vm', id, config.name, '', 'info', 'vm_create', '创建虚拟机', `创建虚拟机 ${config.name}`, 'admin');
    return this.getVM(id);
  }

  async editVM(id, config) {
    const vm = this.db.prepare('SELECT * FROM vms WHERE id = ?').get(id);
    if (!vm) throw new Error('虚拟机不存在');

    const fields = [];
    const values = [];
    // CPU 热调整（运行中可调整到 max_cpu 范围内）
    if (config.cpu !== undefined) {
      if (vm.status === 'running' && config.cpu > vm.max_cpu) throw new Error(`运行中CPU不可超过最大值 ${vm.max_cpu}`);
      fields.push('cpu = ?'); values.push(config.cpu);
    }
    if (config.max_cpu !== undefined) {
      if (vm.status === 'running') throw new Error('最大CPU需关机后修改');
      fields.push('max_cpu = ?'); values.push(config.max_cpu);
    }
    // 内存热调整
    if (config.memory !== undefined) {
      if (vm.status === 'running' && config.memory > vm.max_memory) throw new Error(`运行中内存不可超过最大值 ${vm.max_memory}MB`);
      fields.push('memory = ?'); values.push(config.memory);
    }
    if (config.max_memory !== undefined) {
      if (vm.status === 'running') throw new Error('最大内存需关机后修改');
      fields.push('max_memory = ?'); values.push(config.max_memory);
    }
    if (config.description !== undefined) { fields.push('description = ?'); values.push(config.description); }
    if (config.owner !== undefined) { fields.push('owner = ?'); values.push(config.owner); }
    if (config.name !== undefined) { fields.push('name = ?'); values.push(config.name); }

    if (fields.length === 0) throw new Error('无可更新字段');
    fields.push("updated_at = datetime('now')");
    values.push(id);
    this.db.prepare(`UPDATE vms SET ${fields.join(', ')} WHERE id = ?`).run(...values);
    this._addEvent('vm', id, vm.name, '', 'info', 'vm_edit', '修改虚拟机配置', `修改 ${vm.name} 配置`, 'admin');
    return this.getVM(id);
  }

  async deleteVM(id, permanent = false) {
    const vm = this.db.prepare('SELECT * FROM vms WHERE id = ?').get(id);
    if (!vm) throw new Error('虚拟机不存在');
    if (vm.status === 'running') throw new Error('请先关闭虚拟机');

    if (permanent || vm.deleted === 1) {
      // 永久删除
      this.db.prepare('DELETE FROM vm_disks WHERE vm_id = ?').run(id);
      this.db.prepare('DELETE FROM vm_nics WHERE vm_id = ?').run(id);
      this.db.prepare('DELETE FROM snapshots WHERE vm_id = ?').run(id);
      this.db.prepare('DELETE FROM vm_security_groups WHERE vm_id = ?').run(id);
      this.db.prepare('DELETE FROM vms WHERE id = ?').run(id);
      this._addEvent('vm', id, vm.name, '', 'warning', 'vm_destroy', '永久删除虚拟机', `永久删除 ${vm.name}`, 'admin');
    } else {
      // 移入回收站
      this.db.prepare("UPDATE vms SET deleted = 1, deleted_at = datetime('now') WHERE id = ?").run(id);
      this._addEvent('vm', id, vm.name, '', 'info', 'vm_delete', '删除虚拟机(移入回收站)', `${vm.name} 移入回收站`, 'admin');
    }
    this.db.prepare('UPDATE hosts SET vm_count = MAX(0, vm_count - 1) WHERE id = ?').run(vm.host_id);
    return { success: true };
  }

  async restoreVM(id) {
    const vm = this.db.prepare('SELECT * FROM vms WHERE id = ? AND deleted = 1').get(id);
    if (!vm) throw new Error('回收站中不存在该虚拟机');
    this.db.prepare("UPDATE vms SET deleted = 0, deleted_at = NULL WHERE id = ?").run(id);
    this.db.prepare('UPDATE hosts SET vm_count = vm_count + 1 WHERE id = ?').run(vm.host_id);
    this._addEvent('vm', id, vm.name, '', 'info', 'vm_restore', '恢复虚拟机', `从回收站恢复 ${vm.name}`, 'admin');
    return { success: true };
  }

  async startVM(id) {
    const vm = this.db.prepare('SELECT * FROM vms WHERE id = ?').get(id);
    if (!vm) throw new Error('虚拟机不存在');
    if (vm.status === 'running') throw new Error('虚拟机已在运行中');
    if (vm.deleted === 1) throw new Error('虚拟机已被删除');

    const vnc_port = 5900 + Math.floor(Math.random() * 100);
    this.db.prepare("UPDATE vms SET status = 'running', vnc_port = ?, updated_at = datetime('now') WHERE id = ?").run(vnc_port, id);
    this._addTask('start_vm', 'vm', id, vm.name, 100, 'completed', `虚拟机 ${vm.name} 已启动`);
    this._addEvent('vm', id, vm.name, '', 'info', 'vm_start', '启动虚拟机', `启动 ${vm.name}`, 'admin');
    return { success: true, status: 'running' };
  }

  async stopVM(id) {
    const vm = this.db.prepare('SELECT * FROM vms WHERE id = ?').get(id);
    if (!vm) throw new Error('虚拟机不存在');
    if (vm.status === 'stopped') throw new Error('虚拟机已关闭');

    this.db.prepare("UPDATE vms SET status = 'stopped', vnc_port = 0, updated_at = datetime('now') WHERE id = ?").run(id);
    this._addEvent('vm', id, vm.name, '', 'info', 'vm_stop', '关闭虚拟机', `关闭 ${vm.name}`, 'admin');
    return { success: true, status: 'stopped' };
  }

  async forceStopVM(id) {
    const vm = this.db.prepare('SELECT * FROM vms WHERE id = ?').get(id);
    if (!vm) throw new Error('虚拟机不存在');
    this.db.prepare("UPDATE vms SET status = 'stopped', vnc_port = 0, updated_at = datetime('now') WHERE id = ?").run(id);
    this._addEvent('vm', id, vm.name, '', 'warning', 'vm_force_stop', '强制关闭虚拟机', `强制关闭 ${vm.name}`, 'admin');
    return { success: true, status: 'stopped' };
  }

  async rebootVM(id) {
    const vm = this.db.prepare('SELECT * FROM vms WHERE id = ?').get(id);
    if (!vm) throw new Error('虚拟机不存在');
    if (vm.status !== 'running') throw new Error('虚拟机未运行');
    this.db.prepare("UPDATE vms SET updated_at = datetime('now') WHERE id = ?").run(id);
    this._addEvent('vm', id, vm.name, '', 'info', 'vm_reboot', '重启虚拟机', `重启 ${vm.name}`, 'admin');
    return { success: true, status: 'running' };
  }

  async forceRebootVM(id) {
    const vm = this.db.prepare('SELECT * FROM vms WHERE id = ?').get(id);
    if (!vm) throw new Error('虚拟机不存在');
    this.db.prepare("UPDATE vms SET status = 'running', updated_at = datetime('now') WHERE id = ?").run(id);
    this._addEvent('vm', id, vm.name, '', 'warning', 'vm_force_reboot', '强制重启虚拟机', `强制重启 ${vm.name}`, 'admin');
    return { success: true, status: 'running' };
  }

  async suspendVM(id) {
    const vm = this.db.prepare('SELECT * FROM vms WHERE id = ?').get(id);
    if (!vm) throw new Error('虚拟机不存在');
    if (vm.status !== 'running') throw new Error('只有运行中的虚拟机可以挂起');
    this.db.prepare("UPDATE vms SET status = 'suspended', updated_at = datetime('now') WHERE id = ?").run(id);
    this._addEvent('vm', id, vm.name, '', 'info', 'vm_suspend', '挂起虚拟机', `挂起 ${vm.name}`, 'admin');
    return { success: true, status: 'suspended' };
  }

  async resumeVM(id) {
    const vm = this.db.prepare('SELECT * FROM vms WHERE id = ?').get(id);
    if (!vm) throw new Error('虚拟机不存在');
    if (vm.status !== 'suspended') throw new Error('虚拟机未处于挂起状态');
    this.db.prepare("UPDATE vms SET status = 'running', updated_at = datetime('now') WHERE id = ?").run(id);
    this._addEvent('vm', id, vm.name, '', 'info', 'vm_resume', '唤醒虚拟机', `唤醒 ${vm.name}`, 'admin');
    return { success: true, status: 'running' };
  }

  async restoreToTemplate(id) {
    const vm = this.db.prepare('SELECT * FROM vms WHERE id = ?').get(id);
    if (!vm) throw new Error('虚拟机不存在');
    if (vm.status === 'running') throw new Error('请先关闭虚拟机');
    if (!vm.template_id) throw new Error('虚拟机无关联模板');
    this._addTask('restore_vm', 'vm', id, vm.name, 100, 'completed', `${vm.name} 已还原到黄金镜像状态`);
    this._addEvent('vm', id, vm.name, '', 'info', 'vm_restore_template', '系统还原', `${vm.name} 还原到黄金镜像`, 'admin');
    return { success: true, message: '已还原到黄金镜像状态' };
  }

  async migrateVM(id, targetHostId) {
    const vm = this.db.prepare('SELECT * FROM vms WHERE id = ?').get(id);
    if (!vm) throw new Error('虚拟机不存在');
    const targetHost = await this.getHost(targetHostId);
    if (!targetHost) throw new Error('目标主机不存在');
    if (targetHost.status !== 'online') throw new Error('目标主机不在线');
    if (vm.host_id === targetHostId) throw new Error('目标主机与当前主机相同');

    const oldHostId = vm.host_id;
    this.db.prepare("UPDATE vms SET host_id = ?, updated_at = datetime('now') WHERE id = ?").run(targetHostId, id);
    this.db.prepare('UPDATE hosts SET vm_count = MAX(0, vm_count - 1) WHERE id = ?').run(oldHostId);
    this.db.prepare('UPDATE hosts SET vm_count = vm_count + 1 WHERE id = ?').run(targetHostId);

    this._addTask('migrate_vm', 'vm', id, vm.name, 100, 'completed', `${vm.name} 迁移到 ${targetHost.name} 完成`);
    this._addEvent('vm', id, vm.name, '', 'info', 'vm_migrate', '迁移虚拟机', `${vm.name} 迁移到 ${targetHost.name}`, 'admin');
    return { success: true, message: `已迁移到 ${targetHost.name}` };
  }

  async cloneVM(id, newName) {
    const vm = this.db.prepare('SELECT * FROM vms WHERE id = ?').get(id);
    if (!vm) throw new Error('虚拟机不存在');
    const newId = uuidv4();
    const ip = `192.168.200.${Math.floor(Math.random() * 150) + 100}`;
    const mac = randomMAC();

    this.db.prepare(`INSERT INTO vms (id,name,host_id,template_id,spec_id,cpu,max_cpu,memory,max_memory,disk,status,ip,mac,os_type,os_version,owner,description,created_at,updated_at)
      VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,datetime('now'),datetime('now'))`)
      .run(newId, newName, vm.host_id, vm.template_id, vm.spec_id, vm.cpu, vm.max_cpu, vm.memory, vm.max_memory, vm.disk, 'stopped', ip, mac, vm.os_type, vm.os_version, vm.owner, `从 ${vm.name} 克隆`);

    // 克隆磁盘
    const disks = this.db.prepare('SELECT * FROM vm_disks WHERE vm_id = ?').all(id);
    for (const d of disks) {
      this.db.prepare(`INSERT INTO vm_disks (id,vm_id,name,size,type,bus,format,pool_id) VALUES (?,?,?,?,?,?,?,?)`).run(uuidv4(), newId, d.name.replace(vm.name, newName), d.size, d.type, d.bus, d.format, d.pool_id);
    }
    // 克隆网卡
    const nics = this.db.prepare('SELECT * FROM vm_nics WHERE vm_id = ?').all(id);
    for (const n of nics) {
      this.db.prepare(`INSERT INTO vm_nics (id,vm_id,network_id,mac,model,ip,type) VALUES (?,?,?,?,?,?,?)`).run(uuidv4(), newId, n.network_id, mac, n.model, ip, n.type);
    }

    this.db.prepare('UPDATE hosts SET vm_count = vm_count + 1 WHERE id = ?').run(vm.host_id);
    this._addTask('clone_vm', 'vm', newId, newName, 100, 'completed', `克隆 ${vm.name} → ${newName} 完成`);
    this._addEvent('vm', newId, newName, '', 'info', 'vm_clone', '克隆虚拟机', `从 ${vm.name} 克隆 ${newName}`, 'admin');
    return this.getVM(newId);
  }

  async getVMStats(id) {
    const vm = this.db.prepare('SELECT * FROM vms WHERE id = ?').get(id);
    if (!vm) throw new Error('虚拟机不存在');
    const isRunning = vm.status === 'running';
    return {
      cpu_usage: isRunning ? +(Math.random() * 60 + 5).toFixed(1) : 0,
      memory_usage: isRunning ? +(Math.random() * 40 + 30).toFixed(1) : 0,
      memory_used: isRunning ? Math.floor(vm.memory * (0.3 + Math.random() * 0.4)) : 0,
      memory_total: vm.memory,
      disk_read_bps: isRunning ? Math.floor(Math.random() * 50000000) : 0,
      disk_write_bps: isRunning ? Math.floor(Math.random() * 30000000) : 0,
      disk_read_iops: isRunning ? Math.floor(Math.random() * 5000) : 0,
      disk_write_iops: isRunning ? Math.floor(Math.random() * 3000) : 0,
      net_rx_bps: isRunning ? Math.floor(Math.random() * 10000000) : 0,
      net_tx_bps: isRunning ? Math.floor(Math.random() * 8000000) : 0,
      net_rx_packets: isRunning ? Math.floor(Math.random() * 10000) : 0,
      net_tx_packets: isRunning ? Math.floor(Math.random() * 8000) : 0,
      timestamp: new Date().toISOString(),
    };
  }

  // VM 热添加磁盘
  async addDisk(vmId, config) {
    const vm = this.db.prepare('SELECT * FROM vms WHERE id = ?').get(vmId);
    if (!vm) throw new Error('虚拟机不存在');
    const diskId = uuidv4();
    this.db.prepare(`INSERT INTO vm_disks (id,vm_id,name,size,type,bus,format,pool_id) VALUES (?,?,?,?,?,?,?,?)`).run(
      diskId, vmId, config.name || `${vm.name}-disk-${Date.now()}`, config.size || 20, config.type || 'data', config.bus || 'virtio', config.format || 'qcow2', config.pool_id || '');
    this.db.prepare('UPDATE vms SET disk = disk + ? WHERE id = ?').run(config.size || 20, vmId);
    this._addEvent('vm', vmId, vm.name, '', 'info', 'vm_add_disk', '添加磁盘', `为 ${vm.name} 添加 ${config.size || 20}GB 磁盘`, 'admin');
    return this.db.prepare('SELECT * FROM vm_disks WHERE id = ?').get(diskId);
  }

  // VM 热添加网卡
  async addNic(vmId, config) {
    const vm = this.db.prepare('SELECT * FROM vms WHERE id = ?').get(vmId);
    if (!vm) throw new Error('虚拟机不存在');
    const nicId = uuidv4();
    const mac = randomMAC();
    this.db.prepare(`INSERT INTO vm_nics (id,vm_id,network_id,mac,model,ip,type) VALUES (?,?,?,?,?,?,?)`).run(
      nicId, vmId, config.network_id || '', mac, config.model || 'virtio', config.ip || '', config.type || 'bridged');
    this._addEvent('vm', vmId, vm.name, '', 'info', 'vm_add_nic', '添加网卡', `为 ${vm.name} 添加网卡 ${mac}`, 'admin');
    return this.db.prepare('SELECT * FROM vm_nics WHERE id = ?').get(nicId);
  }

  async removeDisk(vmId, diskId) {
    const disk = this.db.prepare('SELECT * FROM vm_disks WHERE id = ? AND vm_id = ?').get(diskId, vmId);
    if (!disk) throw new Error('磁盘不存在');
    if (disk.type === 'system') throw new Error('不可删除系统盘');
    this.db.prepare('DELETE FROM vm_disks WHERE id = ?').run(diskId);
    this.db.prepare('UPDATE vms SET disk = MAX(0, disk - ?) WHERE id = ?').run(disk.size, vmId);
    return { success: true };
  }

  async removeNic(vmId, nicId) {
    const nic = this.db.prepare('SELECT * FROM vm_nics WHERE id = ? AND vm_id = ?').get(nicId, vmId);
    if (!nic) throw new Error('网卡不存在');
    const nicCount = this.db.prepare('SELECT COUNT(*) as c FROM vm_nics WHERE vm_id = ?').get(vmId);
    if (nicCount && nicCount.c <= 1) throw new Error('至少保留一个网卡');
    this.db.prepare('DELETE FROM vm_nics WHERE id = ?').run(nicId);
    return { success: true };
  }

  // ===========================
  //  快照管理
  // ===========================
  async listSnapshots(vmId) {
    return this.db.prepare('SELECT * FROM snapshots WHERE vm_id = ? ORDER BY created_at DESC').all(vmId);
  }

  async createSnapshot(vmId, name, description) {
    const vm = this.db.prepare('SELECT * FROM vms WHERE id = ?').get(vmId);
    if (!vm) throw new Error('虚拟机不存在');
    // 取消旧的 is_current
    this.db.prepare('UPDATE snapshots SET is_current = 0 WHERE vm_id = ?').run(vmId);
    const id = uuidv4();
    const size = Math.floor(vm.disk * 0.3 + Math.random() * vm.disk * 0.2);
    this.db.prepare(`INSERT INTO snapshots (id,vm_id,name,description,size,status,is_current,created_by) VALUES (?,?,?,?,?,?,?,?)`).run(id, vmId, name, description || '', size, 'active', 1, 'admin');
    this._addTask('create_snapshot', 'snapshot', id, name, 100, 'completed', `快照 ${name} 创建完成`);
    this._addEvent('snapshot', id, name, '', 'info', 'snapshot_create', '创建快照', `为 ${vm.name} 创建快照 ${name}`, 'admin');
    return this.db.prepare('SELECT * FROM snapshots WHERE id = ?').get(id);
  }

  async editSnapshot(vmId, snapId, updates) {
    const snap = this.db.prepare('SELECT * FROM snapshots WHERE id = ? AND vm_id = ?').get(snapId, vmId);
    if (!snap) throw new Error('快照不存在');
    if (updates.name) this.db.prepare('UPDATE snapshots SET name = ? WHERE id = ?').run(updates.name, snapId);
    if (updates.description !== undefined) this.db.prepare('UPDATE snapshots SET description = ? WHERE id = ?').run(updates.description, snapId);
    return this.db.prepare('SELECT * FROM snapshots WHERE id = ?').get(snapId);
  }

  async revertSnapshot(vmId, snapId) {
    const snap = this.db.prepare('SELECT * FROM snapshots WHERE id = ? AND vm_id = ?').get(snapId, vmId);
    if (!snap) throw new Error('快照不存在');
    const vm = this.db.prepare('SELECT * FROM vms WHERE id = ?').get(vmId);
    if (vm && vm.status === 'running') throw new Error('请先关闭虚拟机再恢复快照');
    this.db.prepare('UPDATE snapshots SET is_current = 0 WHERE vm_id = ?').run(vmId);
    this.db.prepare('UPDATE snapshots SET is_current = 1 WHERE id = ?').run(snapId);
    this._addTask('revert_snapshot', 'snapshot', snapId, snap.name, 100, 'completed', `快照 ${snap.name} 恢复完成`);
    this._addEvent('snapshot', snapId, snap.name, '', 'info', 'snapshot_revert', '恢复快照', `${vm.name} 恢复到快照 ${snap.name}`, 'admin');
    return { success: true, message: `已恢复到快照 ${snap.name}` };
  }

  async deleteSnapshot(vmId, snapId) {
    const snap = this.db.prepare('SELECT * FROM snapshots WHERE id = ? AND vm_id = ?').get(snapId, vmId);
    if (!snap) throw new Error('快照不存在');
    this.db.prepare('DELETE FROM snapshots WHERE id = ?').run(snapId);
    this._addEvent('snapshot', snapId, snap.name, '', 'info', 'snapshot_delete', '删除快照', `删除快照 ${snap.name}`, 'admin');
    return { success: true };
  }

  // ===== 快照策略 =====
  async listSnapshotPolicies() {
    return this.db.prepare('SELECT * FROM snapshot_policies ORDER BY created_at DESC').all();
  }

  async createSnapshotPolicy(config) {
    const id = uuidv4();
    this.db.prepare(`INSERT INTO snapshot_policies (id,name,cron_expr,max_keep,cpu_limit,status) VALUES (?,?,?,?,?,?)`).run(id, config.name, config.cron_expr || '0 2 * * *', config.max_keep || 5, config.cpu_limit || 50, 'active');
    if (config.vm_ids && Array.isArray(config.vm_ids)) {
      for (const vmId of config.vm_ids) {
        this.db.prepare(`INSERT INTO snapshot_policy_vms (policy_id,vm_id) VALUES (?,?)`).run(id, vmId);
      }
    }
    return this.db.prepare('SELECT * FROM snapshot_policies WHERE id = ?').get(id);
  }

  async toggleSnapshotPolicy(id, enabled) {
    this.db.prepare('UPDATE snapshot_policies SET status = ? WHERE id = ?').run(enabled ? 'active' : 'disabled', id);
    return { success: true };
  }

  async deleteSnapshotPolicy(id) {
    this.db.prepare('DELETE FROM snapshot_policy_vms WHERE policy_id = ?').run(id);
    this.db.prepare('DELETE FROM snapshot_policies WHERE id = ?').run(id);
    return { success: true };
  }

  // ===========================
  //  模板/黄金镜像管理
  // ===========================
  async listTemplates() {
    return this.db.prepare('SELECT * FROM templates ORDER BY created_at DESC').all();
  }

  async getTemplate(id) {
    return this.db.prepare('SELECT * FROM templates WHERE id = ?').get(id);
  }

  async createTemplate(config) {
    const id = uuidv4();
    this.db.prepare(`INSERT INTO templates (id,name,title,os_type,os_version,arch,cpu,memory,disk,status,run_mode,description) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)`)
      .run(id, config.name, config.title || config.name, config.os_type || 'linux', config.os_version || '', config.arch || 'x86_64', config.cpu || 2, config.memory || 2048, config.disk || 40, 'draft', config.run_mode || 'VDI', config.description || '');
    this._addEvent('template', id, config.name, '', 'info', 'template_create', '创建黄金镜像', `创建黄金镜像 ${config.name}`, 'admin');
    return this.getTemplate(id);
  }

  async createTemplateFromVM(vmId, name) {
    const vm = this.db.prepare('SELECT * FROM vms WHERE id = ?').get(vmId);
    if (!vm) throw new Error('虚拟机不存在');
    if (vm.status === 'running') throw new Error('请先关闭虚拟机');
    const id = uuidv4();
    this.db.prepare(`INSERT INTO templates (id,name,title,os_type,os_version,arch,cpu,memory,disk,status,run_mode,description) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)`)
      .run(id, name, name, vm.os_type, vm.os_version, 'x86_64', vm.cpu, vm.memory, vm.disk, 'published', 'VDI', `从虚拟机 ${vm.name} 提取的模板`);
    this._addTask('extract_template', 'template', id, name, 100, 'completed', `从 ${vm.name} 提取模板 ${name} 完成`);
    this._addEvent('template', id, name, '', 'info', 'template_extract', '提取模板', `从 ${vm.name} 提取模板 ${name}`, 'admin');
    return this.getTemplate(id);
  }

  async editTemplate(id, updates) {
    const tpl = this.db.prepare('SELECT * FROM templates WHERE id = ?').get(id);
    if (!tpl) throw new Error('模板不存在');
    const fields = [];
    const values = [];
    for (const key of ['title', 'description', 'cpu', 'memory', 'disk', 'run_mode', 'data_mode', 'auto_optimize_threshold']) {
      if (updates[key] !== undefined) { fields.push(`${key} = ?`); values.push(updates[key]); }
    }
    if (fields.length === 0) throw new Error('无可更新字段');
    fields.push("updated_at = datetime('now')");
    values.push(id);
    this.db.prepare(`UPDATE templates SET ${fields.join(', ')} WHERE id = ?`).run(...values);
    return this.getTemplate(id);
  }

  async publishTemplate(id) {
    const tpl = this.db.prepare('SELECT * FROM templates WHERE id = ?').get(id);
    if (!tpl) throw new Error('模板不存在');
    this.db.prepare("UPDATE templates SET status = 'published', version = version + 1, updated_at = datetime('now') WHERE id = ?").run(id);
    this._addTask('publish_template', 'template', id, tpl.name, 100, 'completed', `发布黄金镜像 ${tpl.title || tpl.name}`);
    this._addEvent('template', id, tpl.name, '', 'info', 'template_publish', '发布黄金镜像', `发布 ${tpl.title || tpl.name} v${tpl.version + 1}`, 'admin');
    return this.getTemplate(id);
  }

  async maintainTemplate(id) {
    const tpl = this.db.prepare('SELECT * FROM templates WHERE id = ?').get(id);
    if (!tpl) throw new Error('模板不存在');
    this.db.prepare("UPDATE templates SET status = 'maintaining', updated_at = datetime('now') WHERE id = ?").run(id);
    this._addEvent('template', id, tpl.name, '', 'info', 'template_maintain', '进入维护模式', `${tpl.title || tpl.name} 进入维护`, 'admin');
    return this.getTemplate(id);
  }

  async cloneTemplate(id, newName) {
    const tpl = this.db.prepare('SELECT * FROM templates WHERE id = ?').get(id);
    if (!tpl) throw new Error('模板不存在');
    const newId = uuidv4();
    this.db.prepare(`INSERT INTO templates (id,name,title,os_type,os_version,arch,cpu,memory,disk,status,run_mode,parent_id,description) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)`)
      .run(newId, newName, `${tpl.title} (克隆)`, tpl.os_type, tpl.os_version, tpl.arch, tpl.cpu, tpl.memory, tpl.disk, 'draft', tpl.run_mode, tpl.id, `从 ${tpl.title || tpl.name} 克隆`);
    this._addEvent('template', newId, newName, '', 'info', 'template_clone', '克隆黄金镜像', `克隆 ${tpl.title || tpl.name} → ${newName}`, 'admin');
    return this.getTemplate(newId);
  }

  async deleteTemplate(id) {
    const tpl = this.db.prepare('SELECT * FROM templates WHERE id = ?').get(id);
    if (!tpl) throw new Error('模板不存在');
    const inUse = this.db.prepare('SELECT COUNT(*) as c FROM publish_rules WHERE template_id = ?').get(id);
    if (inUse && inUse.c > 0) throw new Error('模板正在被发布规则使用，无法删除');
    this.db.prepare('DELETE FROM templates WHERE id = ?').run(id);
    this._addEvent('template', id, tpl.name, '', 'warning', 'template_delete', '删除黄金镜像', `删除 ${tpl.title || tpl.name}`, 'admin');
    return { success: true };
  }

  // ===========================
  //  桌面规格
  // ===========================
  async listDesktopSpecs() {
    return this.db.prepare('SELECT * FROM desktop_specs ORDER BY created_at DESC').all();
  }

  async getDesktopSpec(id) {
    return this.db.prepare('SELECT * FROM desktop_specs WHERE id = ?').get(id);
  }

  async createDesktopSpec(config) {
    const id = uuidv4();
    this.db.prepare(`INSERT INTO desktop_specs (id,name,cpu,max_cpu,memory,max_memory,cpu_limit,memory_limit,system_disk,user_disk,disk_encrypted,network_type,protocol,usb_mode,gpu_type,gpu_count,watermark_enabled,screen_record_enabled,description)
      VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)`)
      .run(id, config.name, config.cpu || 2, config.max_cpu || 4, config.memory || 2048, config.max_memory || 4096, config.cpu_limit || 100, config.memory_limit || 100, config.system_disk || 40, config.user_disk || 0, config.disk_encrypted ? 1 : 0, config.network_type || 'bridged', config.protocol || 'UDAP', config.usb_mode || 'native', config.gpu_type || '', config.gpu_count || 0, config.watermark_enabled ? 1 : 0, config.screen_record_enabled ? 1 : 0, config.description || '');
    return this.getDesktopSpec(id);
  }

  async editDesktopSpec(id, updates) {
    const spec = this.db.prepare('SELECT * FROM desktop_specs WHERE id = ?').get(id);
    if (!spec) throw new Error('规格不存在');
    const allowed = ['name', 'cpu', 'max_cpu', 'memory', 'max_memory', 'cpu_limit', 'memory_limit', 'system_disk', 'user_disk', 'disk_encrypted', 'network_type', 'protocol', 'usb_mode', 'gpu_type', 'gpu_count', 'watermark_enabled', 'screen_record_enabled', 'description'];
    const fields = [];
    const values = [];
    for (const key of allowed) {
      if (updates[key] !== undefined) { fields.push(`${key} = ?`); values.push(updates[key]); }
    }
    if (fields.length === 0) throw new Error('无可更新字段');
    values.push(id);
    this.db.prepare(`UPDATE desktop_specs SET ${fields.join(', ')} WHERE id = ?`).run(...values);
    return this.getDesktopSpec(id);
  }

  async deleteDesktopSpec(id) {
    const inUse = this.db.prepare('SELECT COUNT(*) as c FROM publish_rules WHERE spec_id = ?').get(id);
    if (inUse && inUse.c > 0) throw new Error('规格正在被发布规则使用');
    this.db.prepare('DELETE FROM desktop_specs WHERE id = ?').run(id);
    return { success: true };
  }

  // ===========================
  //  发布规则
  // ===========================
  async listPublishRules() {
    return this.db.prepare(`
      SELECT r.*, t.title as template_name, s.name as spec_name
      FROM publish_rules r LEFT JOIN templates t ON r.template_id = t.id LEFT JOIN desktop_specs s ON r.spec_id = s.id
      ORDER BY r.created_at DESC
    `).all();
  }

  async getPublishRule(id) {
    return this.db.prepare(`
      SELECT r.*, t.title as template_name, s.name as spec_name
      FROM publish_rules r LEFT JOIN templates t ON r.template_id = t.id LEFT JOIN desktop_specs s ON r.spec_id = s.id
      WHERE r.id = ?
    `).get(id);
  }

  async createPublishRule(config) {
    const id = uuidv4();
    this.db.prepare(`INSERT INTO publish_rules (id,name,template_id,spec_id,target_type,target_name,desktop_type,ip_restriction,time_restriction,snapshot_enabled,max_snapshots,auto_start,auto_shutdown,status)
      VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)`)
      .run(id, config.name, config.template_id, config.spec_id, config.target_type || 'user', config.target_name || '', config.desktop_type || 'dynamic', config.ip_restriction || '', config.time_restriction || '', config.snapshot_enabled ? 1 : 0, config.max_snapshots || 3, config.auto_start ? 1 : 0, config.auto_shutdown || '', 'active');
    return this.db.prepare('SELECT * FROM publish_rules WHERE id = ?').get(id);
  }

  async deletePublishRule(id) {
    this.db.prepare('DELETE FROM publish_rules WHERE id = ?').run(id);
    return { success: true };
  }

  async updatePublishRule(id, updates) {
    const rule = this.db.prepare('SELECT * FROM publish_rules WHERE id = ?').get(id);
    if (!rule) throw new Error('发布规则不存在');
    const allowed = ['name', 'template_id', 'spec_id', 'target_type', 'target_name', 'desktop_type', 'ip_restriction', 'time_restriction', 'snapshot_enabled', 'max_snapshots', 'auto_start', 'auto_shutdown'];
    const fields = [];
    const values = [];
    for (const key of allowed) {
      if (updates[key] !== undefined) { fields.push(`${key} = ?`); values.push(updates[key]); }
    }
    if (fields.length === 0) throw new Error('无可更新字段');
    values.push(id);
    this.db.prepare(`UPDATE publish_rules SET ${fields.join(', ')} WHERE id = ?`).run(...values);
    return this.getPublishRule(id);
  }

  async togglePublishRule(id, status) {
    const rule = this.db.prepare('SELECT * FROM publish_rules WHERE id = ?').get(id);
    if (!rule) throw new Error('发布规则不存在');
    this.db.prepare('UPDATE publish_rules SET status = ? WHERE id = ?').run(status || (rule.status === 'active' ? 'disabled' : 'active'), id);
    return this.getPublishRule(id);
  }

  // ===========================
  //  存储管理
  // ===========================
  async listStoragePools() {
    return this.db.prepare('SELECT * FROM storage_pools ORDER BY name').all();
  }

  async getStoragePool(id) {
    return this.db.prepare('SELECT * FROM storage_pools WHERE id = ?').get(id);
  }

  async createStoragePool(config) {
    const id = uuidv4();
    this.db.prepare(`INSERT INTO storage_pools (id,name,type,total,used,status,path,host_id,replica_count,cache_disk,description) VALUES (?,?,?,?,?,?,?,?,?,?,?)`)
      .run(id, config.name, config.type || 'local', config.total || 1024, 0, 'active', config.path || '', config.host_id || '', config.replica_count || 1, config.cache_disk || '', config.description || '');
    this._addEvent('storage', id, config.name, '', 'info', 'pool_create', '创建存储池', `创建存储池 ${config.name}`, 'admin');
    return this.getStoragePool(id);
  }

  async expandStoragePool(id, additionalSize) {
    const pool = this.db.prepare('SELECT * FROM storage_pools WHERE id = ?').get(id);
    if (!pool) throw new Error('存储池不存在');
    this.db.prepare('UPDATE storage_pools SET total = total + ? WHERE id = ?').run(additionalSize, id);
    this._addEvent('storage', id, pool.name, '', 'info', 'pool_expand', '扩容存储池', `${pool.name} 扩容 ${additionalSize}GB`, 'admin');
    return this.getStoragePool(id);
  }

  async deleteStoragePool(id) {
    const pool = this.db.prepare('SELECT * FROM storage_pools WHERE id = ?').get(id);
    if (!pool) throw new Error('存储池不存在');
    const volCount = this.db.prepare('SELECT COUNT(*) as c FROM volumes WHERE pool_id = ?').get(id);
    if (volCount && volCount.c > 0) throw new Error('存储池中还有卷数据');
    this.db.prepare('DELETE FROM storage_pools WHERE id = ?').run(id);
    this._addEvent('storage', id, pool.name, '', 'warning', 'pool_delete', '删除存储池', `删除 ${pool.name}`, 'admin');
    return { success: true };
  }

  async listVolumes(poolId) {
    if (poolId) return this.db.prepare('SELECT * FROM volumes WHERE pool_id = ?').all(poolId);
    return this.db.prepare('SELECT * FROM volumes').all();
  }

  // ===========================
  //  网络管理
  // ===========================
  async listNetworks() {
    return this.db.prepare('SELECT * FROM networks ORDER BY name').all();
  }

  async getNetwork(id) {
    return this.db.prepare('SELECT * FROM networks WHERE id = ?').get(id);
  }

  async createNetwork(config) {
    const id = uuidv4();
    this.db.prepare(`INSERT INTO networks (id,name,type,bridge,vlan,subnet,gateway,dns,dhcp_enabled,dhcp_start,dhcp_end,nic_name,status,description) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)`)
      .run(id, config.name, config.type || 'bridge', config.bridge || '', config.vlan || 0, config.subnet || '', config.gateway || '', config.dns || '', config.dhcp_enabled ? 1 : 0, config.dhcp_start || '', config.dhcp_end || '', config.nic_name || '', 'active', config.description || '');
    this._addEvent('network', id, config.name, '', 'info', 'network_create', '创建网络', `创建网络 ${config.name}`, 'admin');
    return this.getNetwork(id);
  }

  async editNetwork(id, updates) {
    const net = this.db.prepare('SELECT * FROM networks WHERE id = ?').get(id);
    if (!net) throw new Error('网络不存在');
    const allowed = ['name', 'subnet', 'gateway', 'dns', 'dhcp_enabled', 'dhcp_start', 'dhcp_end', 'description'];
    const fields = [];
    const values = [];
    for (const key of allowed) {
      if (updates[key] !== undefined) { fields.push(`${key} = ?`); values.push(updates[key]); }
    }
    if (fields.length === 0) throw new Error('无可更新字段');
    values.push(id);
    this.db.prepare(`UPDATE networks SET ${fields.join(', ')} WHERE id = ?`).run(...values);
    return this.getNetwork(id);
  }

  async deleteNetwork(id) {
    const nicCount = this.db.prepare('SELECT COUNT(*) as c FROM vm_nics WHERE network_id = ?').get(id);
    if (nicCount && nicCount.c > 0) throw new Error('网络正在被虚拟机使用');
    this.db.prepare('DELETE FROM networks WHERE id = ?').run(id);
    return { success: true };
  }

  // ===== 安全组 =====
  async listSecurityGroups() {
    return this.db.prepare('SELECT * FROM security_groups ORDER BY name').all();
  }

  async getSecurityGroup(id) {
    const sg = this.db.prepare('SELECT * FROM security_groups WHERE id = ?').get(id);
    if (!sg) return null;
    sg.rules = this.db.prepare('SELECT * FROM security_rules WHERE group_id = ? ORDER BY priority').all(id);
    return sg;
  }

  async createSecurityGroup(config) {
    const id = uuidv4();
    this.db.prepare(`INSERT INTO security_groups (id,name,description) VALUES (?,?,?)`).run(id, config.name, config.description || '');
    if (config.rules && Array.isArray(config.rules)) {
      for (const r of config.rules) {
        this.db.prepare(`INSERT INTO security_rules (id,group_id,direction,protocol,port_range,source,action,priority,description) VALUES (?,?,?,?,?,?,?,?,?)`)
          .run(uuidv4(), id, r.direction || 'inbound', r.protocol || 'tcp', r.port_range || '', r.source || '', r.action || 'accept', r.priority || 100, r.description || '');
      }
    }
    return this.getSecurityGroup(id);
  }

  async addSecurityRule(groupId, rule) {
    const id = uuidv4();
    this.db.prepare(`INSERT INTO security_rules (id,group_id,direction,protocol,port_range,source,action,priority,description) VALUES (?,?,?,?,?,?,?,?,?)`)
      .run(id, groupId, rule.direction || 'inbound', rule.protocol || 'tcp', rule.port_range || '', rule.source || '', rule.action || 'accept', rule.priority || 100, rule.description || '');
    return this.db.prepare('SELECT * FROM security_rules WHERE id = ?').get(id);
  }

  async deleteSecurityRule(ruleId) {
    this.db.prepare('DELETE FROM security_rules WHERE id = ?').run(ruleId);
    return { success: true };
  }

  async deleteSecurityGroup(id) {
    const vmCount = this.db.prepare('SELECT COUNT(*) as c FROM vm_security_groups WHERE group_id = ?').get(id);
    if (vmCount && vmCount.c > 0) throw new Error('安全组正在被虚拟机使用');
    this.db.prepare('DELETE FROM security_rules WHERE group_id = ?').run(id);
    this.db.prepare('DELETE FROM security_groups WHERE id = ?').run(id);
    return { success: true };
  }

  // ===========================
  //  备份管理
  // ===========================
  async listBackupServers() {
    return this.db.prepare('SELECT * FROM backup_servers ORDER BY name').all();
  }

  async addBackupServer(config) {
    const id = uuidv4();
    this.db.prepare(`INSERT INTO backup_servers (id,name,address,port,protocol,username,status,total_space,used_space) VALUES (?,?,?,?,?,?,?,?,?)`)
      .run(id, config.name, config.address, config.port || 22, config.protocol || 'ssh', config.username || '', 'active', config.total_space || 10240, 0);
    return this.db.prepare('SELECT * FROM backup_servers WHERE id = ?').get(id);
  }

  async editBackupServer(id, updates) {
    const server = this.db.prepare('SELECT * FROM backup_servers WHERE id = ?').get(id);
    if (!server) throw new Error('备份服务器不存在');
    const fields = [];
    const values = [];
    for (const key of ['name', 'address', 'port', 'username']) {
      if (updates[key] !== undefined) { fields.push(`${key} = ?`); values.push(updates[key]); }
    }
    if (fields.length === 0) throw new Error('无可更新字段');
    values.push(id);
    this.db.prepare(`UPDATE backup_servers SET ${fields.join(', ')} WHERE id = ?`).run(...values);
    return this.db.prepare('SELECT * FROM backup_servers WHERE id = ?').get(id);
  }

  async deleteBackupServer(id) {
    const bkCount = this.db.prepare('SELECT COUNT(*) as c FROM backups WHERE server_id = ?').get(id);
    if (bkCount && bkCount.c > 0) throw new Error('服务器上还有备份数据，请先删除');
    this.db.prepare('DELETE FROM backup_servers WHERE id = ?').run(id);
    return { success: true };
  }

  async listBackups(vmId) {
    if (vmId) return this.db.prepare('SELECT b.*, bs.name as server_name FROM backups b LEFT JOIN backup_servers bs ON b.server_id = bs.id WHERE b.vm_id = ? ORDER BY b.created_at DESC').all(vmId);
    return this.db.prepare('SELECT b.*, bs.name as server_name, v.name as vm_name FROM backups b LEFT JOIN backup_servers bs ON b.server_id = bs.id LEFT JOIN vms v ON b.vm_id = v.id ORDER BY b.created_at DESC').all();
  }

  async createBackup(config) {
    const vm = this.db.prepare('SELECT * FROM vms WHERE id = ?').get(config.vm_id);
    if (!vm) throw new Error('虚拟机不存在');
    const server = this.db.prepare('SELECT * FROM backup_servers WHERE id = ?').get(config.server_id);
    if (!server) throw new Error('备份服务器不存在');
    const id = uuidv4();
    const size = Math.floor(vm.disk * 0.6 + Math.random() * vm.disk * 0.3);
    this.db.prepare(`INSERT INTO backups (id,vm_id,server_id,name,type,size,status,read_speed_limit,write_speed_limit,started_at,finished_at) VALUES (?,?,?,?,?,?,?,?,?,datetime('now'),datetime('now','+15 minutes'))`)
      .run(id, config.vm_id, config.server_id, config.name || `${vm.name}-备份-${new Date().toISOString().slice(0, 10)}`, config.type || 'full', size, 'completed', config.read_speed_limit || 0, config.write_speed_limit || 0);
    this.db.prepare('UPDATE backup_servers SET used_space = used_space + ? WHERE id = ?').run(size, config.server_id);
    this._addTask('backup_vm', 'backup', id, `${vm.name} 备份`, 100, 'completed', `${vm.name} 备份完成`);
    this._addEvent('backup', id, `${vm.name}-备份`, '', 'info', 'backup_create', '创建备份', `为 ${vm.name} 创建备份`, 'admin');
    return this.db.prepare('SELECT * FROM backups WHERE id = ?').get(id);
  }

  async restoreBackup(backupId) {
    const backup = this.db.prepare('SELECT b.*, v.name as vm_name FROM backups b LEFT JOIN vms v ON b.vm_id = v.id WHERE b.id = ?').get(backupId);
    if (!backup) throw new Error('备份不存在');
    this._addTask('restore_backup', 'backup', backupId, `恢复 ${backup.vm_name}`, 100, 'completed', `从备份恢复 ${backup.vm_name} 完成`);
    this._addEvent('backup', backupId, backup.name, '', 'info', 'backup_restore', '恢复备份', `恢复 ${backup.vm_name}`, 'admin');
    return { success: true, message: '备份恢复完成' };
  }

  async deleteBackup(id) {
    const backup = this.db.prepare('SELECT * FROM backups WHERE id = ?').get(id);
    if (!backup) throw new Error('备份不存在');
    this.db.prepare('UPDATE backup_servers SET used_space = MAX(0, used_space - ?) WHERE id = ?').run(backup.size, backup.server_id);
    this.db.prepare('DELETE FROM backups WHERE id = ?').run(id);
    return { success: true };
  }

  // ===========================
  //  告警管理
  // ===========================
  async listAlerts(filters = {}) {
    let where = [];
    let params = [];
    if (filters.level) { where.push('level = ?'); params.push(filters.level); }
    if (filters.status) { where.push('status = ?'); params.push(filters.status); }
    if (filters.type) { where.push('type = ?'); params.push(filters.type); }
    const whereClause = where.length ? `WHERE ${where.join(' AND ')}` : '';
    return this.db.prepare(`SELECT * FROM alerts ${whereClause} ORDER BY created_at DESC`).all(...params);
  }

  async acknowledgeAlert(id) {
    this.db.prepare("UPDATE alerts SET acknowledged = 1, acknowledged_by = 'admin' WHERE id = ?").run(id);
    return { success: true };
  }

  async resolveAlert(id) {
    this.db.prepare("UPDATE alerts SET status = 'resolved', resolved_at = datetime('now') WHERE id = ?").run(id);
    return { success: true };
  }

  async listAlertSettings() {
    return this.db.prepare('SELECT * FROM alert_settings ORDER BY target_type, metric').all();
  }

  async updateAlertSetting(id, updates) {
    const fields = [];
    const values = [];
    for (const key of ['threshold', 'duration', 'level', 'enabled', 'notify_email']) {
      if (updates[key] !== undefined) { fields.push(`${key} = ?`); values.push(updates[key]); }
    }
    if (fields.length === 0) throw new Error('无可更新字段');
    values.push(id);
    this.db.prepare(`UPDATE alert_settings SET ${fields.join(', ')} WHERE id = ?`).run(...values);
    return this.db.prepare('SELECT * FROM alert_settings WHERE id = ?').get(id);
  }

  // ===========================
  //  仪表板统计
  // ===========================
  async getDashboardOverview() {
    const hosts = this.db.prepare('SELECT * FROM hosts').all();
    const vmStats = this.db.prepare("SELECT status, COUNT(*) as count FROM vms WHERE deleted = 0 GROUP BY status").all();
    const deletedCount = this.db.prepare("SELECT COUNT(*) as c FROM vms WHERE deleted = 1").get();
    const totalCpu = hosts.reduce((s, h) => s + h.cpu_total, 0);
    const usedCpu = hosts.reduce((s, h) => s + h.cpu_used, 0);
    const totalMem = hosts.reduce((s, h) => s + h.mem_total, 0);
    const usedMem = hosts.reduce((s, h) => s + h.mem_used, 0);
    const pools = this.db.prepare('SELECT * FROM storage_pools').all();
    const totalStorage = pools.reduce((s, p) => s + p.total, 0);
    const usedStorage = pools.reduce((s, p) => s + p.used, 0);
    const activeAlerts = this.db.prepare("SELECT COUNT(*) as c FROM alerts WHERE status = 'active'").get();
    const recentEvents = this.db.prepare('SELECT * FROM events ORDER BY created_at DESC LIMIT 10').all();
    const recentTasks = this.db.prepare('SELECT * FROM tasks ORDER BY created_at DESC LIMIT 5').all();
    const userCount = this.db.prepare('SELECT COUNT(*) as c FROM users').get();
    const templateCount = this.db.prepare('SELECT COUNT(*) as c FROM templates').get();

    const vmStatusMap = {};
    for (const s of vmStats) vmStatusMap[s.status] = s.count;

    return {
      cluster: {
        cpu: { total: totalCpu, used: usedCpu, usage: totalCpu ? +(usedCpu / totalCpu * 100).toFixed(1) : 0 },
        memory: { total: totalMem, used: usedMem, usage: totalMem ? +(usedMem / totalMem * 100).toFixed(1) : 0 },
        storage: { total: totalStorage, used: usedStorage, usage: totalStorage ? +(usedStorage / totalStorage * 100).toFixed(1) : 0 },
      },
      hosts: {
        total: hosts.length,
        online: hosts.filter(h => h.status === 'online').length,
        offline: hosts.filter(h => h.status !== 'online').length,
      },
      vms: {
        total: Object.values(vmStatusMap).reduce((s, v) => s + v, 0),
        running: vmStatusMap.running || 0,
        stopped: vmStatusMap.stopped || 0,
        suspended: vmStatusMap.suspended || 0,
        deleted: deletedCount ? deletedCount.c : 0,
      },
      alerts: { active: activeAlerts ? activeAlerts.c : 0 },
      users: { total: userCount ? userCount.c : 0 },
      templates: { total: templateCount ? templateCount.c : 0 },
      recent_events: recentEvents,
      recent_tasks: recentTasks,
    };
  }

  // ===========================
  //  系统配置
  // ===========================
  async getSysConfig() {
    return this.db.prepare('SELECT * FROM sys_config ORDER BY key').all();
  }

  async updateSysConfig(key, value) {
    const existing = this.db.prepare('SELECT key FROM sys_config WHERE key = ?').get(key);
    if (existing) {
      this.db.prepare("UPDATE sys_config SET value = ?, updated_at = datetime('now') WHERE key = ?").run(value, key);
    } else {
      this.db.prepare("INSERT INTO sys_config (key, value, updated_at) VALUES (?, ?, datetime('now'))").run(key, value);
    }
    return { key, value };
  }

  // ===========================
  //  用户组
  // ===========================
  async listUserGroups() {
    return this.db.prepare('SELECT * FROM user_groups ORDER BY name').all();
  }

  async createUserGroup(config) {
    const id = uuidv4();
    this.db.prepare(`INSERT INTO user_groups (id,name,parent_id,description) VALUES (?,?,?,?)`).run(id, config.name, config.parent_id || '', config.description || '');
    return this.db.prepare('SELECT * FROM user_groups WHERE id = ?').get(id);
  }

  async deleteUserGroup(id) {
    this.db.prepare('DELETE FROM user_groups WHERE id = ?').run(id);
    return { success: true };
  }

  // ===========================
  //  MAC 地址池
  // ===========================
  async listMacPools() {
    return this.db.prepare('SELECT * FROM mac_pools ORDER BY name').all();
  }

  async createMacPool(config) {
    const id = uuidv4();
    this.db.prepare(`INSERT INTO mac_pools (id,name,prefix,range_start,range_end,total_count) VALUES (?,?,?,?,?,?)`).run(id, config.name, config.prefix || '52:54:00', config.range_start || '', config.range_end || '', config.total_count || 0);
    return this.db.prepare('SELECT * FROM mac_pools WHERE id = ?').get(id);
  }

  // ===========================
  //  内部工具
  // ===========================
  _addEvent(resourceType, resourceId, resourceName, userIp, level, action, message, detail, user) {
    this.db.prepare(`INSERT INTO events (id,type,level,resource_type,resource_id,resource_name,action,message,detail,user,user_ip,created_at) VALUES (?,?,?,?,?,?,?,?,?,?,?,datetime('now'))`)
      .run(uuidv4(), resourceType, level || 'info', resourceType, resourceId, resourceName || '', action, message, detail || '', user || 'system', userIp || '');
  }

  _addTask(type, resourceType, resourceId, resourceName, progress, status, message) {
    const id = uuidv4();
    this.db.prepare(`INSERT INTO tasks (id,type,resource_type,resource_id,resource_name,status,progress,message,user,created_at,started_at,finished_at) VALUES (?,?,?,?,?,?,?,?,?,datetime('now'),datetime('now'),${status === 'completed' ? "datetime('now')" : 'NULL'})`)
      .run(id, type, resourceType, resourceId, resourceName || '', status || 'pending', progress || 0, message || '', 'admin');
    return id;
  }
}

module.exports = MockDriver;
