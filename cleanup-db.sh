#!/bin/bash
NODE=/usr/local/node-v14.21.3-linux-arm64/bin/node
cd /opt/kvm-space/server

$NODE -e "
var wrapper = require('./src/db/sqlite-wrapper');
wrapper.openDatabase('./data/kvm-cloud.db').then(function(db) {
  var vms = db.prepare('SELECT id, name FROM vms WHERE deleted = 0').all();
  var child = require('child_process');
  var deleted = 0;
  vms.forEach(function(vm) {
    try {
      child.execFileSync('virsh', ['dominfo', vm.id], {timeout: 5000, stdio: 'pipe'});
      console.log('  KEEP: ' + vm.name);
    } catch(e) {
      try { db.prepare('DELETE FROM vm_disks WHERE vm_id = ?').run(vm.id); } catch(e2) {}
      try { db.prepare('DELETE FROM vm_nics WHERE vm_id = ?').run(vm.id); } catch(e2) {}
      try { db.prepare('DELETE FROM vms WHERE id = ?').run(vm.id); } catch(e2) {}
      console.log('  DEL:  ' + vm.name);
      deleted++;
    }
  });
  console.log('Deleted: ' + deleted);
  var cnt = db.prepare('SELECT count(*) as c FROM vms').get();
  console.log('Remaining: ' + cnt.c);
  db.close();
});
"
