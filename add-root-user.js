// Add root user with password root
var initSqlJs = require('sql.js');
var fs = require('fs');
var bcrypt = require('bcryptjs');

initSqlJs().then(function(SQL) {
  var dbPath = 'data/kvm-cloud.db';
  var buf = fs.readFileSync(dbPath);
  var db = new SQL.Database(buf);
  
  // Check if root user exists
  var stmt = db.prepare('SELECT id FROM users WHERE username = ?');
  stmt.bind(['root']);
  var exists = stmt.step();
  stmt.free();
  
  if (!exists) {
    var hash = bcrypt.hashSync('root', 10);
    var id = 'root-' + Date.now();
    db.run('INSERT INTO users (id, username, password_hash, display_name, role, status) VALUES (?, ?, ?, ?, ?, ?)',
      [id, 'root', hash, '超级管理员', 'sysadmin', 'active']);
    console.log('Created root user with password: root');
  } else {
    // Update password to root
    var hash = bcrypt.hashSync('root', 10);
    db.run('UPDATE users SET password_hash = ? WHERE username = ?', [hash, 'root']);
    console.log('Updated root user password to: root');
  }
  
  // Save
  var data = db.export();
  var buffer = Buffer.from(data);
  fs.writeFileSync(dbPath, buffer);
  console.log('Database saved.');
  
  // Verify
  var stmt2 = db.prepare('SELECT id,username,role,status FROM users');
  while (stmt2.step()) {
    console.log(JSON.stringify(stmt2.getAsObject()));
  }
  stmt2.free();
});
