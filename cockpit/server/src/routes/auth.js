// Cockpit 认证
var express = require('express');
var bcrypt = require('bcryptjs');
var jwt = require('jsonwebtoken');
var router = express.Router();

var JWT_SECRET = 'cockpit-secret-key-ksvd';

// 登录
router.post('/login', function (req, res) {
  var { username, password } = req.body;
  if (!username || !password) {
    return res.status(400).json({ error: '请输入用户名和密码' });
  }
  // Cockpit 使用系统账号，我们模拟 root 账号
  if (username === 'root' && password === 'root') {
    var token = jwt.sign({ username: 'root', role: 'admin' }, JWT_SECRET, { expiresIn: '24h' });
    return res.json({ token: token, user: { username: 'root', role: 'admin' } });
  }
  return res.status(401).json({ error: '用户名或密码错误' });
});

// 获取当前用户
router.get('/me', function (req, res) {
  res.json({ user: req.user });
});

// JWT 验证中间件
function authMiddleware(req, res, next) {
  if (req.path === '/login' || req.path === '/api/auth/login') return next();
  var authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: '未登录' });
  }
  try {
    var token = authHeader.slice(7);
    req.user = jwt.verify(token, JWT_SECRET);
    next();
  } catch (e) {
    return res.status(401).json({ error: '登录已过期' });
  }
}

module.exports = { router: router, authMiddleware: authMiddleware };
