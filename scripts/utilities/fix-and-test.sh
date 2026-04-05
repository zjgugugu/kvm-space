#!/bin/bash
# Add root user and start VM
NODE=/usr/local/node-v14.21.3-linux-arm64/bin/node
cd /opt/kvm-space

# Add root user
$NODE -e "
var bcrypt = require('bcryptjs');
var uuid = require('uuid');
var wrapper = require('./server/src/db/sqlite-wrapper');
wrapper.openDatabase('./server/data/kvm-cloud.db').then(function(db) {
  var existing = db.prepare('SELECT id FROM users WHERE username = ?').get('root');
  if (existing) {
    console.log('root user already exists, updating password');
    db.prepare('UPDATE users SET password_hash = ? WHERE username = ?').run(bcrypt.hashSync('root', 10), 'root');
  } else {
    console.log('Creating root user');
    db.prepare('INSERT INTO users (id, username, password_hash, display_name, role, status) VALUES (?, ?, ?, ?, ?, ?)').run(
      uuid.v4(), 'root', bcrypt.hashSync('root', 10), '超级管理员', 'sysadmin', 'active'
    );
  }
  // Verify
  var users = db.prepare('SELECT username, role, status FROM users').all();
  users.forEach(function(u) { console.log('  ' + u.username + ' ' + u.role + ' ' + u.status); });
  db.close();
  console.log('Done');
});
"

echo ""
echo "=== RESTART MC TO PICK UP DB CHANGES ==="
pkill -f 'node.*server/src/app.js' 2>/dev/null
sleep 2
> /tmp/mc.log
KVM_MODE=libvirt nohup $NODE server/src/app.js >> /tmp/mc.log 2>&1 &
sleep 4

echo "=== MC LOG ==="
cat /tmp/mc.log

echo ""
echo "=== TEST ROOT LOGIN ==="
curl -s -X POST http://localhost:8444/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"root","password":"root"}'

echo ""
echo ""
echo "=== TEST VM START ==="
ADMIN_RESP=$(curl -s -X POST http://localhost:8444/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"admin123"}')
TOKEN=$(echo "$ADMIN_RESP" | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])" 2>/dev/null)

curl -s -X POST "http://localhost:8444/api/vms/e89ab432-b985-46f2-826b-a788089b34b6/action" \
  -H "Authorization: Bearer $TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"action":"start"}'

sleep 3
echo ""
echo ""
echo "=== VIRSH LIST ==="
virsh list --all | head -10

echo ""
echo "=== MC LOG (last 10) ==="
tail -10 /tmp/mc.log
