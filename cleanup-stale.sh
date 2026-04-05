#!/bin/bash
# Clean up stale VMs from DB and disk
NODE=/usr/local/node-v14.21.3-linux-arm64/bin/node
cd /opt/kvm-space/server

echo "=== Cleaning stale VMs from DB ==="
$NODE -e "
var wrapper = require('./src/db/sqlite-wrapper');
wrapper.openDatabase('./data/kvm-cloud.db').then(function(db) {
  var vms = db.prepare('SELECT id, name FROM vms WHERE deleted = 0').all();
  var child = require('child_process');
  var deleted = 0;
  vms.forEach(function(vm) {
    try {
      child.execFileSync('virsh', ['dominfo', vm.id], {timeout: 5000});
      console.log('  KEEP: ' + vm.id.substring(0,12) + ' ' + vm.name);
    } catch(e) {
      // Not in libvirt, delete from DB
      db.prepare('DELETE FROM vm_disks WHERE vm_id = ?').run(vm.id);
      db.prepare('DELETE FROM vm_nics WHERE vm_id = ?').run(vm.id);
      db.prepare('DELETE FROM vm_snapshots WHERE vm_id = ?').run(vm.id);
      db.prepare('DELETE FROM vms WHERE id = ?').run(vm.id);
      console.log('  DEL:  ' + vm.id.substring(0,12) + ' ' + vm.name);
      deleted++;
    }
  });
  console.log('Deleted ' + deleted + ' stale VMs');
  
  // Verify
  var remaining = db.prepare('SELECT count(*) as cnt FROM vms WHERE deleted = 0').get();
  console.log('Remaining VMs: ' + remaining.cnt);
  db.close();
});
"

echo ""
echo "=== Clean stale disk images ==="
# Only delete images not belonging to any real VM
cd /data/kvm-cloud/images
for f in *.qcow2; do
  UUID=$(echo "$f" | sed 's/-sys.qcow2//')
  if ! virsh dominfo "$UUID" >/dev/null 2>&1; then
    rm -f "$f"
    echo "  Removed: $f"
  else
    echo "  Keep: $f"
  fi
done

echo ""
echo "=== Remaining disk images ==="
ls -la /data/kvm-cloud/images/
