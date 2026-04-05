// 桌面规格管理 API
const express = require('express');
const router = express.Router();

// 列表
router.get('/', async (req, res) => {
  try {
    const specs = await req.app.locals.driver.listDesktopSpecs();
    res.json({ data: specs, total: specs.length });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 详情
router.get('/:id', async (req, res) => {
  try {
    const spec = await req.app.locals.driver.getDesktopSpec(req.params.id);
    if (!spec) return res.status(404).json({ error: '桌面规格不存在' });
    res.json(spec);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 创建
router.post('/', async (req, res) => {
  try {
    const spec = await req.app.locals.driver.createDesktopSpec(req.body);
    res.json(spec);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// 编辑
router.put('/:id', async (req, res) => {
  try {
    const spec = await req.app.locals.driver.editDesktopSpec(req.params.id, req.body);
    res.json(spec);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// 删除
router.delete('/:id', async (req, res) => {
  try {
    const result = await req.app.locals.driver.deleteDesktopSpec(req.params.id);
    res.json(result);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

module.exports = router;
