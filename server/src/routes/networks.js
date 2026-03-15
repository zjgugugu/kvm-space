// 网络管理 API（虚拟交换机 + 安全组 + MAC池）
const express = require('express');
const router = express.Router();

// ===== 安全组 =====
router.get('/security-groups', async (req, res) => {
  try {
    const groups = await req.app.locals.driver.listSecurityGroups();
    res.json({ data: groups, total: groups.length });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/security-groups/:id', async (req, res) => {
  try {
    const sg = await req.app.locals.driver.getSecurityGroup(req.params.id);
    if (!sg) return res.status(404).json({ error: '安全组不存在' });
    res.json(sg);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/security-groups', async (req, res) => {
  try {
    const sg = await req.app.locals.driver.createSecurityGroup(req.body);
    res.status(201).json(sg);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

router.put('/security-groups/:id', async (req, res) => {
  try {
    const sg = await req.app.locals.driver.updateSecurityGroup(req.params.id, req.body);
    res.json(sg);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

router.post('/security-groups/:id/rules', async (req, res) => {
  try {
    const rule = await req.app.locals.driver.addSecurityRule(req.params.id, req.body);
    res.status(201).json(rule);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

router.delete('/security-groups/rules/:ruleId', async (req, res) => {
  try {
    const result = await req.app.locals.driver.deleteSecurityRule(req.params.ruleId);
    res.json(result);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

router.delete('/security-groups/:id', async (req, res) => {
  try {
    const result = await req.app.locals.driver.deleteSecurityGroup(req.params.id);
    res.json(result);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// ===== MAC 地址池 =====
router.get('/mac-pools', async (req, res) => {
  try {
    const pools = await req.app.locals.driver.listMacPools();
    res.json({ data: pools, total: pools.length });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/mac-pools', async (req, res) => {
  try {
    const pool = await req.app.locals.driver.createMacPool(req.body);
    res.status(201).json(pool);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

router.put('/mac-pools/:id', async (req, res) => {
  try {
    const pool = await req.app.locals.driver.updateMacPool(req.params.id, req.body);
    res.json(pool);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

router.delete('/mac-pools/:id', async (req, res) => {
  try {
    const result = await req.app.locals.driver.deleteMacPool(req.params.id);
    res.json(result);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// ===== 网络/虚拟交换机 =====
router.get('/', async (req, res) => {
  try {
    const networks = await req.app.locals.driver.listNetworks();
    res.json({ data: networks, total: networks.length });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.get('/:id', async (req, res) => {
  try {
    const net = await req.app.locals.driver.getNetwork(req.params.id);
    if (!net) return res.status(404).json({ error: '网络不存在' });
    res.json(net);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

router.post('/', async (req, res) => {
  try {
    const net = await req.app.locals.driver.createNetwork(req.body);
    res.status(201).json(net);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

router.put('/:id', async (req, res) => {
  try {
    const net = await req.app.locals.driver.editNetwork(req.params.id, req.body);
    res.json(net);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

router.delete('/:id', async (req, res) => {
  try {
    const result = await req.app.locals.driver.deleteNetwork(req.params.id);
    res.json(result);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

module.exports = router;
