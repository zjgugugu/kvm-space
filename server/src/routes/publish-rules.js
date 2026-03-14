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

// 创建发布规则（将模板+桌面规格发布为可用虚拟机）
router.post('/', async (req, res) => {
  try {
    const rule = await req.app.locals.driver.createPublishRule(req.body);
    res.status(201).json(rule);
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
