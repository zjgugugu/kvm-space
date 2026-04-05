#!/bin/bash
export PATH=/usr/local/node-v14.21.3-linux-arm64/bin:$PATH

# Kill MC
pkill -f 'node server/src/app.js' 2>/dev/null
sleep 2

# Clean last stale VM
cd /opt/kvm-space
node -e '
var sqljs = require("./server/node_modules/sql.js"); var fs = require("fs");
sqljs().then(function(SQL) {
  var buf = fs.readFileSync("/opt/kvm-space/server/data/kvm-cloud.db");
  var db = new SQL.Database(buf);
  db.run("DELETE FROM vm_disks WHERE vm_id = ?", ["20c4c750-8a0e-4864-8389-03c4aa3abf45"]);
  db.run("DELETE FROM vm_nics WHERE vm_id = ?", ["20c4c750-8a0e-4864-8389-03c4aa3abf45"]);
  db.run("DELETE FROM vms WHERE id = ?", ["20c4c750-8a0e-4864-8389-03c4aa3abf45"]);
  var data = db.export(); fs.writeFileSync("/opt/kvm-space/server/data/kvm-cloud.db", Buffer.from(data));
  console.log("Cleaned last stale VM"); db.close();
});
'
sleep 1

# Restart MC
KVM_MODE=libvirt nohup node server/src/app.js > /tmp/mc.log 2>&1 &
sleep 3
tail -3 /tmp/mc.log
echo "==="
ss -tlnp | grep 8444
