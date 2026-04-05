#!/bin/bash
NODE=/usr/local/node-v14.21.3-linux-arm64/bin/node
cd /opt/kvm-space/server

# Add root user (run from server dir so bcryptjs is found)
$NODE -e "
var bcrypt = require('bcryptjs');
var uuid = require('uuid');
var wrapper = require('./src/db/sqlite-wrapper');
wrapper.openDatabase('./data/kvm-cloud.db').then(function(db) {
  var existing = db.prepare('SELECT id FROM users WHERE username = ?').get('root');
  if (existing) {
    console.log('root already exists, updating password');
    db.prepare('UPDATE users SET password_hash = ? WHERE username = ?').run(bcrypt.hashSync('root', 10), 'root');
  } else {
    console.log('Creating root user');
    db.prepare('INSERT INTO users (id, username, password_hash, display_name, role, status) VALUES (?, ?, ?, ?, ?, ?)').run(
      uuid.v4(), 'root', bcrypt.hashSync('root', 10), '超级管理员', 'sysadmin', 'active'
    );
  }
  var users = db.prepare('SELECT username, role, status FROM users').all();
  users.forEach(function(u) { console.log('  ' + u.username + ' ' + u.role + ' ' + u.status); });
  db.close();
});
"

echo ""
echo "=== CHECK VM XML ==="
VM_ID=e89ab432-b985-46f2-826b-a788089b34b6
virsh dumpxml $VM_ID 2>/dev/null || echo "Not defined or cannot dump"

echo ""
echo "=== SYSTEM MEMORY ==="
free -m | head -3

echo ""
echo "=== HUGEPAGES ==="
cat /proc/meminfo | grep -i huge
