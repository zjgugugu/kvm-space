// 认证路由
const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const router = express.Router();

const JWT_SECRET = process.env.JWT_SECRET || 'kvm-cloud-secret-key-change-in-production';

// 登录
router.post('/login', (req, res) => {
  const { username, password } = req.body;
  if (!username || !password) {
    return res.status(400).json({ error: '请输入用户名和密码' });
  }

  const db = req.app.locals.db;
  const user = db.prepare('SELECT * FROM users WHERE username = ?').get(username);
  if (!user) {
    return res.status(401).json({ error: '用户名或密码错误' });
  }
  if (user.status !== 'active') {
    return res.status(403).json({ error: '账号已被禁用' });
  }
  if (!bcrypt.compareSync(password, user.password_hash)) {
    // 登录失败计数
    db.prepare('UPDATE users SET login_fail_count = login_fail_count + 1 WHERE id = ?').run(user.id);
    return res.status(401).json({ error: '用户名或密码错误' });
  }

  // 登录成功，重置失败计数，更新最后登录时间
  db.prepare("UPDATE users SET last_login = datetime('now'), login_fail_count = 0 WHERE id = ?").run(user.id);

  const token = jwt.sign(
    { id: user.id, username: user.username, role: user.role, display_name: user.display_name },
    JWT_SECRET,
    { expiresIn: '24h' }
  );

  res.json({
    token,
    user: { id: user.id, username: user.username, role: user.role, display_name: user.display_name }
  });
});

// 获取当前用户信息
router.get('/me', (req, res) => {
  res.json({ user: req.user });
});

// 修改密码
router.put('/password', (req, res) => {
  const { old_password, new_password } = req.body;
  const db = req.app.locals.db;
  const user = db.prepare('SELECT * FROM users WHERE id = ?').get(req.user.id);

  if (!bcrypt.compareSync(old_password, user.password_hash)) {
    return res.status(400).json({ error: '原密码错误' });
  }

  const hash = bcrypt.hashSync(new_password, 10);
  db.prepare('UPDATE users SET password_hash = ? WHERE id = ?').run(hash, user.id);
  res.json({ success: true });
});

// JWT 验证中间件
function authMiddleware(req, res, next) {
  // 登录接口不需要验证
  if (req.path === '/api/auth/login') return next();

  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: '未登录' });
  }

  try {
    const token = authHeader.slice(7);
    req.user = jwt.verify(token, JWT_SECRET);
    next();
  } catch (e) {
    return res.status(401).json({ error: '登录已过期，请重新登录' });
  }
}

module.exports = { router, authMiddleware };
