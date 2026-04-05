// 快照策略管理 API
const express = require('express');
const router = express.Router();

// 策略列表
router.get('/', async (req, res) => {
  try {
    const policies = await req.app.locals.driver.listSnapshotPolicies();
    res.json({ data: policies, total: policies.length });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 创建策略
router.post('/', async (req, res) => {
  try {
    const policy = await req.app.locals.driver.createSnapshotPolicy(req.body);
    res.json(policy);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// 启用/禁用策略
router.post('/:id/toggle', async (req, res) => {
  try {
    const result = await req.app.locals.driver.toggleSnapshotPolicy(req.params.id, req.body.enabled);
    res.json(result);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// 删除策略
router.delete('/:id', async (req, res) => {
  try {
    const result = await req.app.locals.driver.deleteSnapshotPolicy(req.params.id);
    res.json(result);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

module.exports = router;
