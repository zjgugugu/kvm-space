// 数据库包装层 - 使用 better-sqlite3
const BetterSqlite3 = require('better-sqlite3');
const fs = require('fs');
const path = require('path');

/**
 * 打开数据库（保持 async 签名以兼容 app.js 的 await 调用）
 * @param {string} filePath - 数据库文件路径
 * @returns {Promise<BetterSqlite3.Database>}
 */
async function openDatabase(filePath) {
  const dir = path.dirname(filePath);
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });

  const db = new BetterSqlite3(filePath);
  db.pragma('journal_mode = WAL');
  db.pragma('foreign_keys = ON');

  if (fs.existsSync(filePath)) {
    console.log('[DB] 已加载数据库文件:', filePath);
  } else {
    console.log('[DB] 创建新数据库');
  }

  return db;
}

module.exports = { openDatabase };
