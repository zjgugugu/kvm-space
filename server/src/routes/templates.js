// 黄金镜像/模板管理 API
const express = require('express');
const router = express.Router();

// 列表
router.get('/', async (req, res) => {
  try {
    const templates = await req.app.locals.driver.listTemplates();
    res.json({ data: templates, total: templates.length });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 详情
router.get('/:id', async (req, res) => {
  try {
    const tpl = await req.app.locals.driver.getTemplate(req.params.id);
    if (!tpl) return res.status(404).json({ error: '模板不存在' });
    res.json(tpl);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 创建黄金镜像
router.post('/', async (req, res) => {
  try {
    const tpl = await req.app.locals.driver.createTemplate(req.body);
    res.status(201).json(tpl);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// 编辑
router.put('/:id', async (req, res) => {
  try {
    const tpl = await req.app.locals.driver.editTemplate(req.params.id, req.body);
    res.json(tpl);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// 发布
router.post('/:id/publish', async (req, res) => {
  try {
    const tpl = await req.app.locals.driver.publishTemplate(req.params.id);
    res.json(tpl);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// 进入维护模式
router.post('/:id/maintain', async (req, res) => {
  try {
    const tpl = await req.app.locals.driver.maintainTemplate(req.params.id);
    res.json(tpl);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// 克隆
router.post('/:id/clone', async (req, res) => {
  try {
    const tpl = await req.app.locals.driver.cloneTemplate(req.params.id, req.body.name);
    res.status(201).json(tpl);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// 从虚拟机提取模板
router.post('/extract-from-vm', async (req, res) => {
  try {
    const { vm_id, name } = req.body;
    if (!vm_id || !name) return res.status(400).json({ error: '请提供虚拟机ID和模板名称' });
    const tpl = await req.app.locals.driver.createTemplateFromVM(vm_id, name);
    res.status(201).json(tpl);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// 删除
router.delete('/:id', async (req, res) => {
  try {
    const result = await req.app.locals.driver.deleteTemplate(req.params.id);
    res.json(result);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

module.exports = router;
