// 存储管理 API
const express = require('express');
const router = express.Router();

// 存储池列表
router.get('/pools', async (req, res) => {
  try {
    const pools = await req.app.locals.driver.listStoragePools();
    res.json({ data: pools, total: pools.length });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 存储池详情
router.get('/pools/:id', async (req, res) => {
  try {
    const pool = await req.app.locals.driver.getStoragePool(req.params.id);
    if (!pool) return res.status(404).json({ error: '存储池不存在' });
    res.json(pool);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 创建存储池
router.post('/pools', async (req, res) => {
  try {
    const pool = await req.app.locals.driver.createStoragePool(req.body);
    res.status(201).json(pool);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// 扩容存储池
router.post('/pools/:id/expand', async (req, res) => {
  try {
    const { size } = req.body;
    if (!size || size <= 0) return res.status(400).json({ error: '请输入有效的扩容大小(GB)' });
    const pool = await req.app.locals.driver.expandStoragePool(req.params.id, size);
    res.json(pool);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// 编辑存储池
router.put('/pools/:id', async (req, res) => {
  try {
    const pool = await req.app.locals.driver.editStoragePool(req.params.id, req.body);
    res.json(pool);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// 删除存储池
router.delete('/pools/:id', async (req, res) => {
  try {
    const result = await req.app.locals.driver.deleteStoragePool(req.params.id);
    res.json(result);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// 卷列表
router.get('/volumes', async (req, res) => {
  try {
    const { pool_id } = req.query;
    const volumes = await req.app.locals.driver.listVolumes(pool_id);
    res.json({ data: volumes, total: volumes.length });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// 创建卷
router.post('/volumes', async (req, res) => {
  try {
    const vol = await req.app.locals.driver.createVolume(req.body);
    res.status(201).json(vol);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// 删除卷
router.delete('/volumes/:id', async (req, res) => {
  try {
    const result = await req.app.locals.driver.deleteVolume(req.params.id);
    res.json(result);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

module.exports = router;
