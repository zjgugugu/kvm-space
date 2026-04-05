var { openDatabase } = require('./src/db/sqlite-wrapper');
openDatabase('./data/test2.db').then(function(db) {
  db.exec("CREATE TABLE IF NOT EXISTS t(x INTEGER)");
  db.prepare("INSERT INTO t VALUES(?)").run(42);
  var row = db.prepare("SELECT * FROM t").get();
  console.log("sql.js OK:", JSON.stringify(row));
  db.close();
  process.exit(0);
}).catch(function(e) {
  console.error("FAIL:", e.message);
  process.exit(1);
});
