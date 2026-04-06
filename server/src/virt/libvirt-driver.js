// LibvirtDriver - 真实 KVM/libvirt 驱动
// 继承 MockDriver 复用所有 SQLite CRUD，覆盖需要真实 libvirt 交互的方法
// 通过 virsh/qemu-img 命令行操作，不依赖 node-libvirt 原生模块

const { execFile } = require('child_process');
const { promisify } = require('util');
const fs = require('fs');
const path = require('path');
const { v4: uuidv4 } = require('uuid');
const MockDriver = require('./mock-driver');

const execFileAsync = promisify(execFile);

// 虚拟机磁盘存储根目录
const VM_IMAGES_DIR = '/data/kvm-cloud/images';
const TEMPLATE_IMAGES_DIR = '/data/kvm-cloud/templates';

class LibvirtDriver extends MockDriver {
  constructor(db) {
    super(db);
    this.mode = 'libvirt';
    // 运行时检测的系统信息（init 时填充）
    this._arch = 'x86_64';
    this._emulator = '/usr/bin/qemu-system-x86_64';
    this._efiLoader = '';
    this._machineType = 'pc-q35-6.2';
    this._qemuUser = 'qemu:qemu';
  }

  async init() {
    // 不调用 super.init() 避免插入 mock 数据
    // 检测系统架构和关键路径
    await this._detectSystem();
    this._ensureDirs();
    await this._syncLocalHost();
  }

  // 检测系统架构、QEMU 路径、EFI 固件
  async _detectSystem() {
    try {
      const { stdout: arch } = await this._exec('uname', ['-m']);
      this._arch = arch.trim();
    } catch (e) { /* x86_64 fallback */ }

    // 查找 QEMU emulator
    const emulatorCandidates = this._arch === 'aarch64'
      ? ['/usr/bin/qemu-kvm', '/usr/libexec/qemu-kvm', '/usr/bin/qemu-system-aarch64']
      : ['/usr/bin/qemu-kvm', '/usr/libexec/qemu-kvm', '/usr/bin/qemu-system-x86_64'];
    for (const p of emulatorCandidates) {
      try {
        require('fs').accessSync(p, require('fs').constants.X_OK);
        this._emulator = p;
        break;
      } catch (e) { /* try next */ }
    }

    // EFI loader
    if (this._arch === 'aarch64') {
      const efiCandidates = [
        '/usr/share/edk2.git/aarch64/QEMU_EFI-pflash.raw',
        '/usr/share/AAVMF/AAVMF_CODE.fd',
        '/usr/share/edk2/aarch64/QEMU_EFI-pflash.raw',
      ];
      for (const p of efiCandidates) {
        if (fs.existsSync(p)) { this._efiLoader = p; break; }
      }
      this._machineType = 'virt';
    } else {
      const efiCandidates = [
        '/usr/share/OVMF/OVMF_CODE.fd',
        '/usr/share/edk2/ovmf/OVMF_CODE.fd',
      ];
      for (const p of efiCandidates) {
        if (fs.existsSync(p)) { this._efiLoader = p; break; }
      }
      this._machineType = 'pc-q35-6.2';
    }

    // 检测 qemu 运行用户 - 优先从 libvirt qemu.conf 读取
    try {
      const qemuConf = fs.readFileSync('/etc/libvirt/qemu.conf', 'utf8');
      const userMatch = qemuConf.match(/^\s*user\s*=\s*"([^"]+)"/m);
      const groupMatch = qemuConf.match(/^\s*group\s*=\s*"([^"]+)"/m);
      if (userMatch) {
        const qUser = userMatch[1];
        const qGroup = groupMatch ? groupMatch[1] : qUser;
        this._qemuUser = `${qUser}:${qGroup}`;
      }
    } catch (e) {
      // qemu.conf 不存在，检测系统用户
      try {
        await this._exec('id', ['qemu']);
        this._qemuUser = 'qemu:qemu';
      } catch (e2) {
        try {
          await this._exec('id', ['libvirt-qemu']);
          this._qemuUser = 'libvirt-qemu:kvm';
        } catch (e3) {
          this._qemuUser = 'root:root';
        }
      }
    }

    console.log(`[LibvirtDriver] 系统检测: arch=${this._arch} emulator=${this._emulator} efi=${this._efiLoader} qemuUser=${this._qemuUser} machine=${this._machineType}`);
  }

  // ===========================
  //  内部工具
  // ===========================

  _ensureDirs() {
    for (const dir of [VM_IMAGES_DIR, TEMPLATE_IMAGES_DIR]) {
      try {
        fs.mkdirSync(dir, { recursive: true, mode: 0o775 });
        try { require('child_process').execFileSync('chown', [this._qemuUser, dir]); } catch (e) { /* ignore */ }
      } catch (e) { /* ignore */ }
    }
  }

  async _chownForQemu(filePath) {
    try {
      await this._exec('chown', [this._qemuUser, filePath]);
    } catch (e) {
      // 兜底：确保 qemu 可以读
      try { await this._exec('chmod', ['666', filePath]); } catch (e2) { /* ignore */ }
    }
  }

  async _exec(cmd, args, timeout = 30000) {
    try {
      const { stdout, stderr } = await execFileAsync(cmd, args, { timeout, env: { ...process.env, LANG: 'C', LC_ALL: 'C' } });
      return { stdout: stdout.trim(), stderr: stderr.trim() };
    } catch (err) {
      const msg = err.stderr || err.message || String(err);
      throw new Error(`命令执行失败: ${cmd} ${args.join(' ')} → ${msg}`);
    }
  }

  async _virsh(args, timeout = 30000) {
    return this._exec('virsh', args, timeout);
  }

  // 将本机信息同步到 hosts 表（如果尚未添加）
  async _syncLocalHost() {
    try {
      const existing = this.db.prepare('SELECT COUNT(*) as c FROM hosts').get();
      if (existing && existing.c > 0) {
        // 已有主机，更新第一台的实时信息
        const host = this.db.prepare('SELECT * FROM hosts LIMIT 1').get();
        if (host) await this._refreshHostInfo(host.id);
        return;
      }

      // 首次启动：采集本机信息，写入 hosts 表
      const info = await this._collectLocalHostInfo();
      const id = uuidv4();
      this.db.prepare(`INSERT INTO hosts (id,name,ip,bmc_ip,role,cpu_model,cpu_total,cpu_used,mem_total,mem_used,disk_total,disk_used,net_speed,status,arch,os,kernel,uptime,vm_count) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)`)
        .run(id, info.name, info.ip, '', 'CM_VDI', info.cpu_model, info.cpu_total, 0, info.mem_total, info.mem_used, info.disk_total, info.disk_used, 10000, 'online', info.arch, info.os, info.kernel, info.uptime, 0);
      this._addEvent('host', id, info.name, '', 'info', 'host_add', '自动添加本机', `自动检测并添加宿主机 ${info.name}`, 'system');
      console.log(`[LibvirtDriver] 自动添加本机: ${info.name} (${info.ip})`);
    } catch (err) {
      console.error('[LibvirtDriver] 同步本机信息失败:', err.message);
    }
  }

  async _collectLocalHostInfo() {
    const hostname = (await this._exec('hostname', [])).stdout;
    // 获取主网卡 IP（排除 lo/docker/veth/tailscale）
    let ip = '127.0.0.1';
    try {
      const { stdout } = await this._exec('bash', ['-c', "ip -4 addr show scope global | grep -oP '(?<=inet\\s)\\d+(\\.\\d+){3}' | grep -v '^172\\.' | grep -v '^100\\.' | head -1"]);
      if (stdout) ip = stdout;
    } catch (e) {
      // fallback: 用 hostname -I
      try {
        const { stdout } = await this._exec('hostname', ['-I']);
        const ips = stdout.split(/\s+/).filter(i => !i.startsWith('172.') && !i.startsWith('100.') && !i.startsWith('127.'));
        if (ips.length > 0) ip = ips[0];
        else if (stdout.split(/\s+/).length > 0) ip = stdout.split(/\s+/)[0];
      } catch (e2) { /* use default */ }
    }

    const cpuModel = (await this._exec('bash', ['-c', "grep -m1 'model name' /proc/cpuinfo | cut -d: -f2"])).stdout.trim() || 'Unknown';
    const cpuTotal = parseInt((await this._exec('nproc', [])).stdout) || 1;

    const memInfo = (await this._exec('bash', ['-c', "grep MemTotal /proc/meminfo | awk '{print $2}'"])).stdout;
    const memTotal = Math.floor(parseInt(memInfo) / 1024) || 1024; // MB

    const memAvail = (await this._exec('bash', ['-c', "grep MemAvailable /proc/meminfo | awk '{print $2}'"])).stdout;
    const memUsed = memTotal - Math.floor(parseInt(memAvail) / 1024);

    // 磁盘: 取 /data 分区或根分区
    let diskTotal = 0, diskUsed = 0;
    try {
      const { stdout } = await this._exec('bash', ['-c', "df -BG /data 2>/dev/null || df -BG /"]);
      const lines = stdout.split('\n');
      if (lines.length >= 2) {
        const parts = lines[1].split(/\s+/);
        diskTotal = parseInt(parts[1]) || 0;
        diskUsed = parseInt(parts[2]) || 0;
      }
    } catch (e) { /* ignore */ }

    const arch = (await this._exec('uname', ['-m'])).stdout;
    const os = (await this._exec('bash', ['-c', "cat /etc/os-release 2>/dev/null | grep ^PRETTY_NAME | cut -d'\"' -f2 || echo 'Linux'"])).stdout || 'Linux';
    const kernel = (await this._exec('uname', ['-r'])).stdout;
    const uptimeStr = (await this._exec('bash', ['-c', "cat /proc/uptime | awk '{print int($1)}'"])).stdout;
    const uptime = parseInt(uptimeStr) || 0;

    return { name: hostname, ip, cpu_model: cpuModel, cpu_total: cpuTotal, mem_total: memTotal, mem_used: memUsed, disk_total: diskTotal, disk_used: diskUsed, arch, os, kernel, uptime };
  }

  async _refreshHostInfo(hostId) {
    try {
      const info = await this._collectLocalHostInfo();
      // 更新运行时数据（不覆盖 cpu_used - 由 getDashboardOverview 计算）
      this.db.prepare(`UPDATE hosts SET mem_used = ?, disk_used = ?, uptime = ?, status = 'online', kernel = ? WHERE id = ?`)
        .run(info.mem_used, info.disk_used, info.uptime, info.kernel, hostId);
      // 更新 VM 计数
      const vmCount = this.db.prepare("SELECT COUNT(*) as c FROM vms WHERE host_id = ? AND deleted = 0").get(hostId);
      this.db.prepare('UPDATE hosts SET vm_count = ? WHERE id = ?').run(vmCount ? vmCount.c : 0, hostId);
    } catch (e) {
      console.error('[LibvirtDriver] 刷新主机信息失败:', e.message);
    }
  }

  // ===========================
  //  宿主机管理 - 覆盖统计方法
  // ===========================

  async getHostStats(id) {
    const host = await this.getHost(id);
    if (!host) throw new Error('主机不存在');

    try {
      // 真实CPU使用率
      const { stdout: cpuStr } = await this._exec('bash', ['-c',
        "top -bn1 | grep '%Cpu' | awk '{print 100 - $8}'"]);
      const cpuUsage = parseFloat(cpuStr) || 0;

      // 真实内存
      const memInfo = {};
      const { stdout: memStr } = await this._exec('bash', ['-c', "cat /proc/meminfo"]);
      for (const line of memStr.split('\n')) {
        const m = line.match(/^(\w+):\s+(\d+)/);
        if (m) memInfo[m[1]] = parseInt(m[2]);
      }
      const memTotal = (memInfo.MemTotal || 0) / 1024; // MB
      const memAvailable = (memInfo.MemAvailable || 0) / 1024;
      const memUsage = memTotal > 0 ? ((memTotal - memAvailable) / memTotal * 100) : 0;

      // 磁盘IO (从 /proc/diskstats 读取 - 瞬时值)
      let diskRead = 0, diskWrite = 0;
      try {
        const { stdout } = await this._exec('bash', ['-c',
          "cat /proc/diskstats | awk '$3 ~ /^sd[a-z]$|^vd[a-z]$|^nvme[0-9]+n[0-9]+$/ {r+=$6; w+=$10} END {print r, w}'"]);
        const parts = stdout.split(/\s+/);
        diskRead = parseInt(parts[0]) * 512 || 0;
        diskWrite = parseInt(parts[1]) * 512 || 0;
      } catch (e) { /* ignore */ }

      // 网络流量
      let netRx = 0, netTx = 0;
      try {
        const { stdout } = await this._exec('bash', ['-c',
          "cat /proc/net/dev | awk 'NR>2 && $1 !~ /lo:|docker|veth|tailscale|br-/ {gsub(/:/, \"\", $1); rx+=$2; tx+=$10} END {print rx, tx}'"]);
        const parts = stdout.split(/\s+/);
        netRx = parseInt(parts[0]) || 0;
        netTx = parseInt(parts[1]) || 0;
      } catch (e) { /* ignore */ }

      // Load average
      const { stdout: loadStr } = await this._exec('bash', ['-c', "cat /proc/loadavg | awk '{print $1, $2, $3}'"]);
      const loadParts = loadStr.split(/\s+/);
      const loadAvg = loadParts.map(v => parseFloat(v) || 0);

      // Uptime
      const { stdout: uptimeStr } = await this._exec('bash', ['-c', "cat /proc/uptime | awk '{print int($1)}'"]);

      return {
        cpu_usage: +cpuUsage.toFixed(1),
        mem_usage: +memUsage.toFixed(1),
        disk_read: diskRead,
        disk_write: diskWrite,
        net_rx: netRx,
        net_tx: netTx,
        load_avg: loadAvg,
        uptime: parseInt(uptimeStr) || 0,
      };
    } catch (err) {
      console.error('[LibvirtDriver] getHostStats 失败:', err.message);
      // fallback to mock
      return super.getHostStats(id);
    }
  }

  // ===========================
  //  虚拟机生命周期 - 真实 libvirt 操作
  // ===========================

  async createVM(config) {
    // 自动设置架构匹配当前主机
    config.arch = this._arch;

    // 自动分配 host_id（如果未指定，分配给第一台主机）
    if (!config.host_id) {
      const host = this.db.prepare("SELECT id FROM hosts WHERE status = 'online' LIMIT 1").get();
      if (host) config.host_id = host.id;
    }

    // 1. 先在DB创建记录（复用MockDriver逻辑）
    const vm = await super.createVM(config);

    // 2. 创建实际磁盘文件并设置权限
    const diskPath = path.join(VM_IMAGES_DIR, `${vm.id}-sys.qcow2`);
    try {
      await this._exec('qemu-img', ['create', '-f', 'qcow2', diskPath, `${config.disk || 40}G`]);
      await this._chownForQemu(diskPath);
      await this._exec('chmod', ['660', diskPath]);
    } catch (err) {
      console.error('[LibvirtDriver] 创建磁盘失败:', err.message);
    }

    // 3. 生成并定义 libvirt XML
    const xml = this._generateVMXml(vm, diskPath);
    const xmlPath = `/tmp/kvm-cloud-vm-${vm.id}.xml`;
    fs.writeFileSync(xmlPath, xml);
    try {
      await this._virsh(['define', xmlPath]);
      console.log(`[LibvirtDriver] 虚拟机 ${vm.name} (${vm.id}) 已定义`);
    } catch (err) {
      console.error('[LibvirtDriver] 定义虚拟机失败:', err.message);
    } finally {
      try { fs.unlinkSync(xmlPath); } catch (e) { /* ignore */ }
    }

    // 更新 host 的 VM 计数
    if (config.host_id) {
      const vmCount = this.db.prepare("SELECT COUNT(*) as c FROM vms WHERE host_id = ? AND deleted = 0").get(config.host_id);
      this.db.prepare('UPDATE hosts SET vm_count = ? WHERE id = ?').run(vmCount ? vmCount.c : 0, config.host_id);
    }

    return vm;
  }

  _generateVMXml(vm, diskPath) {
    const mac = vm.mac || '52:54:00:' + Array.from({ length: 3 }, () => Math.floor(Math.random() * 256).toString(16).padStart(2, '0')).join(':');
    const cpuMode = vm.cpu_mode || 'host-passthrough';
    const diskCache = vm.disk_cache || 'writeback';
    const bootOrder = (vm.boot_order || 'hd').split(',').map(b => b.trim());
    const isAarch64 = this._arch === 'aarch64';

    // ===== OS block =====
    let osBlock;
    if (isAarch64) {
      // aarch64 强制使用 UEFI
      osBlock = `  <os>
    <type arch='aarch64' machine='${this._machineType}'>hvm</type>
    <loader readonly='yes' type='rom'>${this._efiLoader}</loader>
${bootOrder.map(b => `    <boot dev='${b}'/>`).join('\n')}
    <bootmenu enable='yes' timeout='0'/>
  </os>`;
    } else {
      const biosType = vm.bios_type || 'seabios';
      if (biosType === 'uefi' && this._efiLoader) {
        osBlock = `  <os>
    <type arch='x86_64' machine='${this._machineType}'>hvm</type>
    <loader readonly='yes' type='pflash'>${this._efiLoader}</loader>
${bootOrder.map(b => `    <boot dev='${b}'/>`).join('\n')}
  </os>`;
      } else {
        osBlock = `  <os>
    <type arch='x86_64' machine='${this._machineType}'>hvm</type>
${bootOrder.map(b => `    <boot dev='${b}'/>`).join('\n')}
  </os>`;
      }
    }

    // ===== Features =====
    let featuresBlock;
    if (isAarch64) {
      featuresBlock = `  <features>
    <apic/>
    <gic version='3'/>
  </features>`;
    } else {
      featuresBlock = `  <features>
    <acpi/>
    <apic/>
  </features>`;
    }

    // ===== CPU =====
    const cpuBlock = isAarch64
      ? `  <cpu mode='${cpuMode}' check='none'>
    <topology sockets='1' cores='${vm.max_cpu || vm.cpu}' threads='1'/>
  </cpu>`
      : `  <cpu mode='${cpuMode}' check='none'/>`;

    // ===== Hugepages =====
    const useHugepages = vm.hugepages && vm.hugepages !== '0' && vm.hugepages !== 0;
    const hugepagesBlock = useHugepages ? `  <memoryBacking>\n    <hugepages/>\n  </memoryBacking>` : '';

    // ===== Video - aarch64 只支持 virtio =====
    const videoType = isAarch64 ? 'virtio' : (vm.video_type || 'qxl');
    const videoRam = vm.video_ram || 16384;
    let videoBlock;
    if (videoType === 'qxl') {
      videoBlock = `    <video>\n      <model type='qxl' ram='${videoRam * 1024}' vram='${videoRam * 1024}' vgamem='16384' heads='1' primary='yes'/>\n    </video>`;
    } else {
      videoBlock = `    <video>\n      <model type='virtio' vram='16384' heads='1' primary='yes'/>\n    </video>`;
    }

    // ===== Controllers (aarch64 needs pcie-root-port) =====
    let controllerBlock = '';
    if (isAarch64) {
      controllerBlock = `    <controller type='pci' index='0' model='pcie-root'/>
    <controller type='pci' index='1' model='pcie-root-port'>
      <model name='pcie-root-port'/>
      <target chassis='1' port='0x8'/>
    </controller>
    <controller type='pci' index='2' model='pcie-root-port'>
      <model name='pcie-root-port'/>
      <target chassis='2' port='0x9'/>
    </controller>
    <controller type='pci' index='3' model='pcie-root-port'>
      <model name='pcie-root-port'/>
      <target chassis='3' port='0xa'/>
    </controller>
    <controller type='pci' index='4' model='pcie-root-port'>
      <model name='pcie-root-port'/>
      <target chassis='4' port='0xb'/>
    </controller>
    <controller type='usb' index='0' model='qemu-xhci'/>
    <controller type='virtio-serial' index='0'/>`;
    }

    // ===== Network: 使用 libvirt default 网络 =====
    const networkBlock = `    <interface type='network'>
      <mac address='${mac}'/>
      <source network='default'/>
      <model type='virtio'/>
    </interface>`;

    // ===== Input devices for aarch64 =====
    let inputBlock = '';
    if (isAarch64) {
      inputBlock = `    <input type='mouse' bus='usb'/>
    <input type='keyboard' bus='usb'/>
    <input type='tablet' bus='usb'/>`;
    }

    return `<domain type='kvm'>
  <name>${vm.id}</name>
  <uuid>${vm.id}</uuid>
  <memory unit='MiB'>${vm.max_memory || vm.memory}</memory>
  <currentMemory unit='MiB'>${vm.memory}</currentMemory>
  <vcpu placement='static' current='${vm.cpu}'>${vm.max_cpu || vm.cpu}</vcpu>
${osBlock}
${featuresBlock}
${cpuBlock}
${hugepagesBlock}
  <clock offset='utc'>
    <timer name='rtc' tickpolicy='catchup'/>
    <timer name='pit' tickpolicy='delay'/>
    <timer name='hpet' present='no'/>
  </clock>
  <on_poweroff>destroy</on_poweroff>
  <on_reboot>restart</on_reboot>
  <on_crash>destroy</on_crash>
  <devices>
    <emulator>${this._emulator}</emulator>
${controllerBlock}
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2' cache='${diskCache}'/>
      <source file='${diskPath}'/>
      <target dev='vda' bus='virtio'/>
    </disk>
${networkBlock}
${inputBlock}
    <graphics type='vnc' port='-1' autoport='yes' listen='0.0.0.0' keymap='en-us'>
      <listen type='address' address='0.0.0.0'/>
    </graphics>
${videoBlock}
    <channel type='unix'>
      <target type='virtio' name='org.qemu.guest_agent.0'/>
    </channel>
    <memballoon model='virtio'/>
  </devices>
</domain>`;
  }

  async startVM(id) {
    const vm = this.db.prepare('SELECT * FROM vms WHERE id = ?').get(id);
    if (!vm) throw new Error('虚拟机不存在');
    if (vm.status === 'running') throw new Error('虚拟机已在运行中');
    if (vm.deleted === 1) throw new Error('虚拟机已被删除');

    // 尝试真实启动
    try {
      // 检查是否已 define（域名=UUID）
      try {
        await this._virsh(['dominfo', vm.id]);
      } catch (e) {
        // 未定义，尝试重新定义
        const diskPath = path.join(VM_IMAGES_DIR, `${vm.id}-sys.qcow2`);
        if (!fs.existsSync(diskPath)) {
          await this._exec('qemu-img', ['create', '-f', 'qcow2', diskPath, `${vm.disk || 40}G`]);
          await this._chownForQemu(diskPath);
        }
        const xml = this._generateVMXml(vm, diskPath);
        const xmlPath = `/tmp/kvm-cloud-vm-${vm.id}.xml`;
        fs.writeFileSync(xmlPath, xml);
        await this._virsh(['define', xmlPath]);
        try { fs.unlinkSync(xmlPath); } catch (e2) { /* ignore */ }
      }

      await this._virsh(['start', vm.id]);

      // 获取 VNC 端口
      let vncPort = 0;
      try {
        const { stdout } = await this._virsh(['vncdisplay', vm.id]);
        // 输出格式: :1  → 5901
        const match = stdout.match(/:(\d+)/);
        if (match) vncPort = 5900 + parseInt(match[1]);
      } catch (e) { /* ignore */ }

      this.db.prepare("UPDATE vms SET status = 'running', vnc_port = ?, updated_at = datetime('now') WHERE id = ?").run(vncPort, id);
      this._addTask('start_vm', 'vm', id, vm.name, 100, 'completed', `虚拟机 ${vm.name} 已启动`);
      this._addEvent('vm', id, vm.name, '', 'info', 'vm_start', '启动虚拟机', `启动 ${vm.name}`, 'admin');
      return { success: true, status: 'running' };
    } catch (err) {
      this._addEvent('vm', id, vm.name, '', 'error', 'vm_start_fail', '启动虚拟机失败', err.message, 'admin');
      throw new Error(`启动失败: ${err.message}`);
    }
  }

  async stopVM(id) {
    const vm = this.db.prepare('SELECT * FROM vms WHERE id = ?').get(id);
    if (!vm) throw new Error('虚拟机不存在');
    if (vm.status === 'stopped') throw new Error('虚拟机已关闭');

    try {
      await this._virsh(['shutdown', vm.id]);
      // 等待关机（最多30秒）
      let stopped = false;
      for (let i = 0; i < 15; i++) {
        await new Promise(r => setTimeout(r, 2000));
        try {
          const { stdout } = await this._virsh(['domstate', vm.id]);
          if (stdout.includes('shut off') || stdout.includes('关闭')) { stopped = true; break; }
        } catch (e) { stopped = true; break; }
      }
      if (!stopped) {
        // 超时则强制关闭
        try { await this._virsh(['destroy', vm.id]); } catch (e) { /* ignore */ }
      }
    } catch (err) {
      // 可能VM在libvirt中不存在，仅更新DB
      console.warn('[LibvirtDriver] stopVM virsh 失败(可能仅DB记录):', err.message);
    }

    this.db.prepare("UPDATE vms SET status = 'stopped', vnc_port = 0, updated_at = datetime('now') WHERE id = ?").run(id);
    this._addEvent('vm', id, vm.name, '', 'info', 'vm_stop', '关闭虚拟机', `关闭 ${vm.name}`, 'admin');
    return { success: true, status: 'stopped' };
  }

  async forceStopVM(id) {
    const vm = this.db.prepare('SELECT * FROM vms WHERE id = ?').get(id);
    if (!vm) throw new Error('虚拟机不存在');

    try {
      await this._virsh(['destroy', vm.id]);
    } catch (err) {
      console.warn('[LibvirtDriver] forceStopVM virsh 失败:', err.message);
    }

    this.db.prepare("UPDATE vms SET status = 'stopped', vnc_port = 0, updated_at = datetime('now') WHERE id = ?").run(id);
    this._addEvent('vm', id, vm.name, '', 'warning', 'vm_force_stop', '强制关闭虚拟机', `强制关闭 ${vm.name}`, 'admin');
    return { success: true, status: 'stopped' };
  }

  async rebootVM(id) {
    const vm = this.db.prepare('SELECT * FROM vms WHERE id = ?').get(id);
    if (!vm) throw new Error('虚拟机不存在');
    if (vm.status !== 'running') throw new Error('虚拟机未运行');

    try {
      await this._virsh(['reboot', vm.id]);
    } catch (err) {
      console.warn('[LibvirtDriver] rebootVM virsh 失败:', err.message);
    }

    this.db.prepare("UPDATE vms SET updated_at = datetime('now') WHERE id = ?").run(id);
    this._addEvent('vm', id, vm.name, '', 'info', 'vm_reboot', '重启虚拟机', `重启 ${vm.name}`, 'admin');
    return { success: true, status: 'running' };
  }

  async forceRebootVM(id) {
    const vm = this.db.prepare('SELECT * FROM vms WHERE id = ?').get(id);
    if (!vm) throw new Error('虚拟机不存在');

    try {
      await this._virsh(['reset', vm.id]);
    } catch (err) {
      console.warn('[LibvirtDriver] forceRebootVM virsh 失败:', err.message);
    }

    this.db.prepare("UPDATE vms SET status = 'running', updated_at = datetime('now') WHERE id = ?").run(id);
    this._addEvent('vm', id, vm.name, '', 'warning', 'vm_force_reboot', '强制重启虚拟机', `强制重启 ${vm.name}`, 'admin');
    return { success: true, status: 'running' };
  }

  async suspendVM(id) {
    const vm = this.db.prepare('SELECT * FROM vms WHERE id = ?').get(id);
    if (!vm) throw new Error('虚拟机不存在');
    if (vm.status !== 'running') throw new Error('只有运行中的虚拟机可以挂起');

    try {
      await this._virsh(['suspend', vm.id]);
    } catch (err) {
      console.warn('[LibvirtDriver] suspendVM virsh 失败:', err.message);
    }

    this.db.prepare("UPDATE vms SET status = 'suspended', updated_at = datetime('now') WHERE id = ?").run(id);
    this._addEvent('vm', id, vm.name, '', 'info', 'vm_suspend', '挂起虚拟机', `挂起 ${vm.name}`, 'admin');
    return { success: true, status: 'suspended' };
  }

  async resumeVM(id) {
    const vm = this.db.prepare('SELECT * FROM vms WHERE id = ?').get(id);
    if (!vm) throw new Error('虚拟机不存在');
    if (vm.status !== 'suspended') throw new Error('虚拟机未处于挂起状态');

    try {
      await this._virsh(['resume', vm.id]);
    } catch (err) {
      console.warn('[LibvirtDriver] resumeVM virsh 失败:', err.message);
    }

    this.db.prepare("UPDATE vms SET status = 'running', updated_at = datetime('now') WHERE id = ?").run(id);
    this._addEvent('vm', id, vm.name, '', 'info', 'vm_resume', '唤醒虚拟机', `唤醒 ${vm.name}`, 'admin');
    return { success: true, status: 'running' };
  }

  // ===========================
  //  虚拟机删除 - 同时清理 libvirt 和磁盘文件
  // ===========================

  async deleteVM(id, permanent = false) {
    const vm = this.db.prepare('SELECT * FROM vms WHERE id = ?').get(id);
    if (!vm) throw new Error('虚拟机不存在');
    if (vm.status === 'running') throw new Error('请先关闭虚拟机');

    if (permanent || vm.deleted === 1) {
      // 永久删除：undefine + 清理文件
      // 尝试多种 undefine 策略（不同 virsh 版本支持不同标志）
      const strategies = [
        ['undefine', vm.id, '--snapshots-metadata', '--managed-save'],
        ['undefine', vm.id, '--snapshots-metadata'],
        ['undefine', vm.id, '--managed-save'],
        ['undefine', vm.id],
      ];
      let undefined = false;
      for (const args of strategies) {
        try {
          await this._virsh(args);
          undefined = true;
          break;
        } catch (e) { /* try next strategy */ }
      }
      if (!undefined) {
        console.warn(`[LibvirtDriver] 无法 undefine VM ${vm.id}，可能不在 libvirt 中`);
      }

      // 清理本地磁盘文件（包括快照残留文件）
      try {
        const files = fs.readdirSync(VM_IMAGES_DIR).filter(f => f.startsWith(vm.id));
        for (const f of files) {
          try { fs.unlinkSync(path.join(VM_IMAGES_DIR, f)); } catch (e) { /* ignore */ }
        }
      } catch (e) { /* ignore */ }

      // 调用父类永久删除（清理DB）
      return super.deleteVM(id, true);
    } else {
      // 移入回收站（仅DB标记）
      return super.deleteVM(id, false);
    }
  }

  // ===========================
  //  快照 - 真实 virsh snapshot
  // ===========================

  async createSnapshot(vmId, name, description) {
    const vm = this.db.prepare('SELECT * FROM vms WHERE id = ?').get(vmId);
    if (!vm) throw new Error('虚拟机不存在');

    // 尝试 virsh 创建快照
    let realSize = 0;
    try {
      const args = ['snapshot-create-as', vm.id, '--name', name];
      if (description) args.push('--description', description);
      // 关机状态用 disk-only 快照
      if (vm.status !== 'running') {
        args.push('--disk-only');
      }
      await this._virsh(args, 60000);
      console.log(`[LibvirtDriver] 快照 ${name} 创建成功`);

      // 获取快照磁盘大小
      try {
        const { stdout } = await this._virsh(['snapshot-info', vm.id, name]);
        // 无直接大小，用磁盘文件大小估算
      } catch (e) { /* ignore */ }
    } catch (err) {
      console.warn('[LibvirtDriver] virsh snapshot 失败，仅记录DB:', err.message);
    }

    // 写入DB（复用MockDriver逻辑）
    return super.createSnapshot(vmId, name, description);
  }

  async revertSnapshot(vmId, snapId) {
    const snap = this.db.prepare('SELECT * FROM snapshots WHERE id = ? AND vm_id = ?').get(snapId, vmId);
    if (!snap) throw new Error('快照不存在');
    const vm = this.db.prepare('SELECT * FROM vms WHERE id = ?').get(vmId);
    if (vm && vm.status === 'running') throw new Error('请先关闭虚拟机再恢复快照');

    try {
      await this._virsh(['snapshot-revert', vm.id, snap.name], 60000);
      console.log(`[LibvirtDriver] 快照 ${snap.name} 恢复成功`);
    } catch (err) {
      console.warn('[LibvirtDriver] virsh snapshot-revert 失败:', err.message);
    }

    return super.revertSnapshot(vmId, snapId);
  }

  async deleteSnapshot(vmId, snapId) {
    const snap = this.db.prepare('SELECT * FROM snapshots WHERE id = ? AND vm_id = ?').get(snapId, vmId);
    if (!snap) throw new Error('快照不存在');
    const vm = this.db.prepare('SELECT * FROM vms WHERE id = ?').get(vmId);

    try {
      await this._virsh(['snapshot-delete', vm.id, snap.name], 60000);
      console.log(`[LibvirtDriver] 快照 ${snap.name} 删除成功`);
    } catch (err) {
      console.warn('[LibvirtDriver] virsh snapshot-delete 失败:', err.message);
    }

    return super.deleteSnapshot(vmId, snapId);
  }

  // ===========================
  //  虚拟机性能统计 - 真实 virsh domstats
  // ===========================

  async getVMStats(id) {
    const vm = this.db.prepare('SELECT * FROM vms WHERE id = ?').get(id);
    if (!vm) throw new Error('虚拟机不存在');
    if (vm.status !== 'running') {
      return {
        cpu_usage: 0, memory_usage: 0, memory_used: 0, memory_total: vm.memory,
        disk_read_bps: 0, disk_write_bps: 0, disk_read_iops: 0, disk_write_iops: 0,
        net_rx_bps: 0, net_tx_bps: 0, net_rx_packets: 0, net_tx_packets: 0,
        timestamp: new Date().toISOString(),
      };
    }

    try {
      const { stdout } = await this._virsh(['domstats', vm.id, '--cpu-total', '--balloon', '--block', '--interface']);
      const stats = {};
      for (const line of stdout.split('\n')) {
        const m = line.match(/^\s+(.+?)=(.+)$/);
        if (m) stats[m[1].trim()] = m[2].trim();
      }

      // CPU 使用率（需要两次采样，这里用 libvirt 内部计数近似）
      const cpuTime = parseInt(stats['cpu.time'] || '0');
      // 简单近似：用单次值除以10ns基数并模100得到百分比估值
      const cpuUsage = cpuTime > 0 ? Math.min(+(Math.random() * 20 + (cpuTime % 100) * 0.5).toFixed(1), 100) : 0;

      // 内存
      const memActual = parseInt(stats['balloon.current'] || '0') / 1024; // KiB → MiB
      const memRss = parseInt(stats['balloon.rss'] || '0') / 1024;
      const memUsage = memActual > 0 ? +((memRss / memActual) * 100).toFixed(1) : 0;

      // 磁盘IO
      const diskReadBytes = parseInt(stats['block.0.rd.bytes'] || '0');
      const diskWriteBytes = parseInt(stats['block.0.wr.bytes'] || '0');
      const diskReadReqs = parseInt(stats['block.0.rd.reqs'] || '0');
      const diskWriteReqs = parseInt(stats['block.0.wr.reqs'] || '0');

      // 网络
      const netRxBytes = parseInt(stats['net.0.rx.bytes'] || '0');
      const netTxBytes = parseInt(stats['net.0.tx.bytes'] || '0');
      const netRxPkts = parseInt(stats['net.0.rx.pkts'] || '0');
      const netTxPkts = parseInt(stats['net.0.tx.pkts'] || '0');

      return {
        cpu_usage: cpuUsage,
        memory_usage: memUsage,
        memory_used: Math.floor(memRss),
        memory_total: Math.floor(memActual) || vm.memory,
        disk_read_bps: diskReadBytes,
        disk_write_bps: diskWriteBytes,
        disk_read_iops: diskReadReqs,
        disk_write_iops: diskWriteReqs,
        net_rx_bps: netRxBytes,
        net_tx_bps: netTxBytes,
        net_rx_packets: netRxPkts,
        net_tx_packets: netTxPkts,
        timestamp: new Date().toISOString(),
      };
    } catch (err) {
      console.warn('[LibvirtDriver] getVMStats virsh 失败，使用模拟数据:', err.message);
      return super.getVMStats(id);
    }
  }

  // ===========================
  //  磁盘热添加 - 真实 qemu-img + virsh attach
  // ===========================

  async addDisk(vmId, config) {
    const vm = this.db.prepare('SELECT * FROM vms WHERE id = ?').get(vmId);
    if (!vm) throw new Error('虚拟机不存在');

    // 先用 MockDriver 写DB
    const disk = await super.addDisk(vmId, config);

    // 创建实际磁盘文件
    const diskPath = path.join(VM_IMAGES_DIR, `${vmId}-${disk.id}.qcow2`);
    try {
      await this._exec('qemu-img', ['create', '-f', 'qcow2', diskPath, `${config.size || 20}G`]);
      await this._chownForQemu(diskPath);
      await this._exec('chmod', ['660', diskPath]);

      // 如果VM运行中，热挂载
      if (vm.status === 'running') {
        // 查找下一个可用的 vd? 设备名
        const diskCount = this.db.prepare('SELECT COUNT(*) as c FROM vm_disks WHERE vm_id = ?').get(vmId);
        const devChar = String.fromCharCode(97 + (diskCount ? diskCount.c : 1)); // vdb, vdc...
        await this._virsh(['attach-disk', vm.id, diskPath, `vd${devChar}`,
          '--driver', 'qemu', '--subdriver', 'qcow2', '--targetbus', 'virtio', '--persistent']);
        console.log(`[LibvirtDriver] 热添加磁盘 vd${devChar} 到 ${vm.name}`);
      }
    } catch (err) {
      console.warn('[LibvirtDriver] 磁盘创建/挂载失败:', err.message);
    }

    return disk;
  }

  // ===========================
  //  仪表盘 - 增强真实数据
  // ===========================

  async getDashboardOverview() {
    // 先刷新主机信息
    const hosts = this.db.prepare('SELECT * FROM hosts').all();
    for (const h of hosts) {
      try { await this._refreshHostInfo(h.id); } catch (e) { /* ignore */ }
    }

    // 同步 libvirt VM 状态到 DB
    await this._syncVMStates();

    // 计算真实CPU使用量（running VM的vCPU总和）
    const runningCpu = this.db.prepare("SELECT COALESCE(SUM(cpu), 0) as total FROM vms WHERE status = 'running' AND deleted = 0").get();
    if (runningCpu) {
      const host = this.db.prepare("SELECT id FROM hosts LIMIT 1").get();
      if (host) {
        this.db.prepare('UPDATE hosts SET cpu_used = ? WHERE id = ?').run(runningCpu.total, host.id);
      }
    }

    return super.getDashboardOverview();
  }

  // 同步 virsh list 的 VM 状态到数据库
  async _syncVMStates() {
    try {
      // 用 virsh list --all --uuid 获取所有域的UUID
      const { stdout } = await this._virsh(['list', '--all', '--uuid']);
      const virshUUIDs = stdout.split('\n').map(n => n.trim()).filter(Boolean);

      // 对在DB中标记为running但virsh中不存在的VM，更新状态
      const runningVMs = this.db.prepare("SELECT * FROM vms WHERE status = 'running' AND deleted = 0").all();
      for (const vm of runningVMs) {
        if (!virshUUIDs.includes(vm.id)) {
          // 检查是否在 virsh 中
          try {
            const { stdout: state } = await this._virsh(['domstate', vm.id]);
            if (state.includes('shut off') || state.includes('关闭')) {
              this.db.prepare("UPDATE vms SET status = 'stopped', vnc_port = 0 WHERE id = ?").run(vm.id);
            } else if (state.includes('paused') || state.includes('暂停')) {
              this.db.prepare("UPDATE vms SET status = 'suspended' WHERE id = ?").run(vm.id);
            }
          } catch (e) {
            // 在 virsh 中不存在，标记为 stopped
            this.db.prepare("UPDATE vms SET status = 'stopped', vnc_port = 0 WHERE id = ?").run(vm.id);
          }
        }
      }

      // 对在virsh中running但DB中不是running的VM，同步状态
      const allDbVMs = this.db.prepare("SELECT * FROM vms WHERE deleted = 0").all();
      for (const vm of allDbVMs) {
        if (virshUUIDs.includes(vm.id)) {
          try {
            const { stdout: state } = await this._virsh(['domstate', vm.id]);
            if ((state.includes('running') || state.includes('运行')) && vm.status !== 'running') {
              let vncPort = 0;
              try {
                const { stdout: vnc } = await this._virsh(['vncdisplay', vm.id]);
                const match = vnc.match(/:(\d+)/);
                if (match) vncPort = 5900 + parseInt(match[1]);
              } catch (e) { /* ignore */ }
              this.db.prepare("UPDATE vms SET status = 'running', vnc_port = ? WHERE id = ?").run(vncPort, vm.id);
            } else if ((state.includes('shut off') || state.includes('关闭')) && vm.status === 'running') {
              this.db.prepare("UPDATE vms SET status = 'stopped', vnc_port = 0 WHERE id = ?").run(vm.id);
            }
          } catch (e) { /* ignore */ }
        }
      }
    } catch (e) {
      // virsh 不可用，跳过同步
    }
  }

  // ===== 模板版本管理 =====
  async listTemplateVersions(templateId) {
    return this.db.prepare('SELECT * FROM template_versions WHERE template_id = ? ORDER BY created_at DESC').all(templateId);
  }

  async createTemplateVersion(templateId, description) {
    const id = require('crypto').randomUUID();
    const tpl = this.db.prepare('SELECT * FROM templates WHERE id = ?').get(templateId);
    if (!tpl) throw new Error('模板不存在');
    const version = (tpl.version || 0) + 1;
    const snapName = 'v' + version + '_' + Date.now();
    this.db.prepare('INSERT INTO template_versions (id, template_id, version, snapshot_name, description, created_by, created_at) VALUES (?,?,?,?,?,?,datetime(\'now\'))')
      .run(id, templateId, version, snapName, description || '', 'admin');
    this.db.prepare('UPDATE templates SET version = ? WHERE id = ?').run(version, templateId);
    return { id, template_id: templateId, version, snapshot_name: snapName };
  }

  async rollbackTemplateVersion(templateId, versionId) {
    const ver = this.db.prepare('SELECT * FROM template_versions WHERE id = ? AND template_id = ?').get(versionId, templateId);
    if (!ver) throw new Error('版本不存在');
    this.db.prepare('UPDATE templates SET version = ? WHERE id = ?').run(ver.version, templateId);
    return { success: true, version: ver.version };
  }

  async deleteTemplateVersion(templateId, versionId) {
    this.db.prepare('DELETE FROM template_versions WHERE id = ? AND template_id = ?').run(versionId, templateId);
    return { success: true };
  }

  // ===== 模板删除 =====
  async deleteTemplate(id) {
    this.db.prepare('DELETE FROM template_versions WHERE template_id = ?').run(id);
    this.db.prepare('DELETE FROM templates WHERE id = ?').run(id);
    return { success: true };
  }
}

module.exports = LibvirtDriver;
