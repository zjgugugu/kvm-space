#!/bin/bash
echo "=== DISK FILE ==="
ls -la /data/kvm-cloud/images/
echo ""
echo "=== QEMU USER ==="
id qemu
echo ""
echo "=== PYTHON VERSION ==="
python3 --version
echo ""
echo "=== CHECK ROOT USER IN DB ==="
# Use node to query DB directly
cd /opt/kvm-space
/usr/local/node-v14.21.3-linux-arm64/bin/node -e "
const { openDatabase } = require('./server/src/db/sqlite-wrapper');
async function main() {
  const db = await openDatabase('./server/data/kvm-cloud.db');
  const users = db.prepare('SELECT username, password_hash, role, status FROM users').all();
  users.forEach(u => console.log(u.username, u.role, u.status, u.password_hash.substring(0,20)));
}
main().catch(e => console.error(e));
"
echo ""
echo "=== FIX DISK PERMISSIONS ==="
chmod 666 /data/kvm-cloud/images/*.qcow2 2>/dev/null
ls -la /data/kvm-cloud/images/
