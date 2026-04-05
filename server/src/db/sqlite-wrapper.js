// 数据库包装层 - 使用 sql.js (纯 JS SQLite，兼容 Node 14 / ARM64)
const initSqlJs = require('sql.js');
const fs = require('fs');
const path = require('path');

class Statement {
  constructor(db, sql) {
    this._db = db;
    this._sql = sql;
  }

  run() {
    var params = Array.prototype.slice.call(arguments);
    if (params.length === 1 && Array.isArray(params[0])) params = params[0];
    // sql.js doesn't accept undefined - convert to null
    params = params.map(function(v) { return v === undefined ? null : v; });
    try {
      this._db._raw.run(this._sql, params);
      this._db._scheduleSave();
      return { changes: this._db._raw.getRowsModified() };
    } catch (e) {
      throw new Error('SQL run error [' + this._sql + ']: ' + e.message);
    }
  }

  get() {
    var params = Array.prototype.slice.call(arguments);
    if (params.length === 1 && Array.isArray(params[0])) params = params[0];
    params = params.map(function(v) { return v === undefined ? null : v; });
    var stmt;
    try {
      stmt = this._db._raw.prepare(this._sql);
      if (params.length > 0) stmt.bind(params);
      if (stmt.step()) {
        var row = stmt.getAsObject();
        stmt.free();
        return row;
      }
      stmt.free();
      return undefined;
    } catch (e) {
      if (stmt) try { stmt.free(); } catch (_) {}
      throw new Error('SQL get error [' + this._sql + ']: ' + e.message);
    }
  }

  all() {
    var params = Array.prototype.slice.call(arguments);
    if (params.length === 1 && Array.isArray(params[0])) params = params[0];
    params = params.map(function(v) { return v === undefined ? null : v; });
    var stmt;
    try {
      stmt = this._db._raw.prepare(this._sql);
      if (params.length > 0) stmt.bind(params);
      var rows = [];
      while (stmt.step()) {
        rows.push(stmt.getAsObject());
      }
      stmt.free();
      return rows;
    } catch (e) {
      if (stmt) try { stmt.free(); } catch (_) {}
      throw new Error('SQL all error [' + this._sql + ']: ' + e.message);
    }
  }
}

class Database {
  constructor(rawDb, filePath) {
    this._raw = rawDb;
    this._filePath = filePath;
    this._saveTimer = null;
  }

  prepare(sql) {
    return new Statement(this, sql);
  }

  exec(sql) {
    this._raw.exec(sql);
    this._scheduleSave();
    return this;
  }

  pragma(str) {
    try { this._raw.run('PRAGMA ' + str); } catch (e) { /* ignore */ }
  }

  transaction(fn) {
    var self = this;
    return function() {
      self._raw.run('BEGIN');
      try {
        fn();
        self._raw.run('COMMIT');
        self._scheduleSave();
      } catch (e) {
        self._raw.run('ROLLBACK');
        throw e;
      }
    };
  }

  _scheduleSave() {
    if (this._saveTimer) return;
    this._saveTimer = setTimeout(function () {
      this._saveTimer = null;
      this._saveSync();
    }.bind(this), 200);
  }

  _saveSync() {
    try {
      var data = this._raw.export();
      var buffer = Buffer.from(data);
      fs.writeFileSync(this._filePath, buffer);
    } catch (e) {
      console.error('[DB] 保存失败:', e.message);
    }
  }

  close() {
    if (this._saveTimer) {
      clearTimeout(this._saveTimer);
      this._saveSync();
    }
    this._raw.close();
  }
}

async function openDatabase(filePath) {
  var dir = path.dirname(filePath);
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });

  // locate the wasm file bundled with sql.js
  var wasmPath = path.join(path.dirname(require.resolve('sql.js')), 'dist', 'sql-wasm.wasm');
  if (!fs.existsSync(wasmPath)) {
    wasmPath = path.join(path.dirname(require.resolve('sql.js')), 'sql-wasm.wasm');
  }
  var wasmBinary = fs.readFileSync(wasmPath);

  var SQL = await initSqlJs({ wasmBinary: wasmBinary });
  var db;

  if (fs.existsSync(filePath)) {
    var buffer = fs.readFileSync(filePath);
    db = new SQL.Database(buffer);
    console.log('[DB] 已加载数据库文件:', filePath);
  } else {
    db = new SQL.Database();
    console.log('[DB] 创建新数据库');
  }

  var wrapped = new Database(db, filePath);
  wrapped.pragma('foreign_keys = ON');
  return wrapped;
}

module.exports = { openDatabase };
