// 发布规则管理 API
const express = require('express');
const router = express.Router();

// 列表
router.get('/', async (req, res) => {
  try {
    const rules = await req.app.locals.driver.listPublishRules();
    res.json({ data: rules, total: rules.length });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 创建发布规则
router.post('/', async (req, res) => {
  try {
    const rule = await req.app.locals.driver.createPublishRule(req.body);
    res.json(rule);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// 获取单个发布规则
router.get('/:id', async (req, res) => {
  try {
    const rule = await req.app.locals.driver.getPublishRule(req.params.id);
    if (!rule) return res.status(404).json({ error: '发布规则不存在' });
    res.json(rule);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 更新发布规则
router.put('/:id', async (req, res) => {
  try {
    const rule = await req.app.locals.driver.updatePublishRule(req.params.id, req.body);
    res.json(rule);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// 切换发布规则状态
router.put('/:id/status', async (req, res) => {
  try {
    const { status } = req.body;
    const rule = await req.app.locals.driver.togglePublishRule(req.params.id, status);
    res.json(rule);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// 删除
router.delete('/:id', async (req, res) => {
  try {
    const result = await req.app.locals.driver.deletePublishRule(req.params.id);
    res.json(result);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

module.exports = router;
