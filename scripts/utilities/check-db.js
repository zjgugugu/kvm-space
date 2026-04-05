var initSqlJs = require('sql.js');
var fs = require('fs');
initSqlJs().then(function(SQL) {
  var buf = fs.readFileSync('data/kvm-cloud.db');
  var db = new SQL.Database(buf);
  var stmt = db.prepare('SELECT id,username,role,status FROM users');
  var rows = [];
  while (stmt.step()) rows.push(stmt.getAsObject());
  stmt.free();
  console.log(JSON.stringify(rows, null, 2));
});
