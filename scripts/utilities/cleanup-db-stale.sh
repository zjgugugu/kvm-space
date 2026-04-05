#!/bin/bash
# Clean up stale data in the database
export PATH=/usr/local/node-v14.21.3-linux-arm64/bin:$PATH
cd /opt/kvm-space

node -e '
var sqljs = require("./server/node_modules/sql.js");
var fs = require("fs");
var path = require("path");
sqljs().then(function(SQL) {
  var dbPath = path.join("/opt/kvm-space/server/data/kvm-cloud.db");
  var buf = fs.readFileSync(dbPath);
  var db = new SQL.Database(buf);

  // Show current state
  var pools = db.exec("SELECT id, name, status FROM storage_pools");
  console.log("Storage pools:", JSON.stringify(pools[0] ? pools[0].values : []));

  var vms = db.exec("SELECT id, name, status, deleted FROM vms");
  console.log("VMs:", JSON.stringify(vms[0] ? vms[0].values : []));

  // Delete duplicate test-pool entries (keep first)
  var allPools = db.exec("SELECT id FROM storage_pools ORDER BY rowid");
  if (allPools[0] && allPools[0].values.length > 1) {
    var keepId = allPools[0].values[0][0];
    console.log("Keeping pool: " + keepId);
    db.run("DELETE FROM storage_pools WHERE id != ?", [keepId]);
    console.log("Deleted duplicate pools");
  }

  // Delete VMs that are marked deleted=1 (in recycle bin)
  var deleted = db.exec("SELECT id FROM vms WHERE deleted = 1");
  if (deleted[0]) {
    for (var i = 0; i < deleted[0].values.length; i++) {
      var vmId = deleted[0].values[i][0];
      db.run("DELETE FROM vm_disks WHERE vm_id = ?", [vmId]);
      db.run("DELETE FROM vm_nics WHERE vm_id = ?", [vmId]);
      db.run("DELETE FROM vms WHERE id = ?", [vmId]);
      console.log("Permanently deleted recycled VM: " + vmId);
    }
  }

  // Show final state
  var pools2 = db.exec("SELECT id, name FROM storage_pools");
  console.log("Final pools:", JSON.stringify(pools2[0] ? pools2[0].values : []));

  var vms2 = db.exec("SELECT id, name, status, deleted FROM vms");
  console.log("Final VMs:", JSON.stringify(vms2[0] ? vms2[0].values : []));

  // Save
  var data = db.export();
  fs.writeFileSync(dbPath, Buffer.from(data));
  console.log("Database saved");
  db.close();
});
'
