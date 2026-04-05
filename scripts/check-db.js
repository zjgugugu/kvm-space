// Check DB table row counts
var path = require('path');
var p = require(path.join(__dirname, '..', 'server', 'src', 'db', 'sqlite-wrapper'));
p.openDatabase(path.join(__dirname, '..', 'server', 'data', 'kvm-cloud.db')).then(function(db) {
  var r = db.exec("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name");
  if (r.length) r[0].values.forEach(function(v) {
    var c = db.exec("SELECT COUNT(*) FROM [" + v[0] + "]");
    console.log(v[0] + ": " + (c.length ? c[0].values[0][0] : 0) + " rows");
  });
});
