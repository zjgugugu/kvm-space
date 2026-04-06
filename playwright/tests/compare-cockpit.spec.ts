/**
 * Cockpit 对比测试: 9091 (我们的) vs 9090 (真实的)
 *
 * 修复版: 正确处理 Playwright fixtures、真实 Cockpit iframe、服务可用性检测
 *
 * 运行前提: 两个服务均需在远程服务器 10.126.33.238 上运行
 *   - 9091: 我们的 Cockpit (node cockpit/server/src/app.js)
 *   - 9090: 真实 Cockpit (systemctl status cockpit)
 *
 * 运行: npx playwright test compare-cockpit.spec.ts
 */
import { test, expect, Page, Browser, BrowserContext } from '@playwright/test';
import * as fs from 'fs';
import * as path from 'path';

const OUR_URL = 'https://10.126.33.238:9091';
const REAL_URL = 'https://10.126.33.238:9090';

const OUR_CRED = { username: 'root', password: 'root' };
const REAL_CRED = { username: 'root', password: 'unikylinsec' };

const SCREENSHOT_DIR = path.join(__dirname, '..', 'screenshots');

// ==================== 工具函数 ====================

function ensureScreenshotDir() {
  if (!fs.existsSync(SCREENSHOT_DIR)) {
    fs.mkdirSync(SCREENSHOT_DIR, { recursive: true });
  }
}

/** 检测服务是否可达 */
async function isServiceReachable(page: Page, url: string): Promise<boolean> {
  try {
    const resp = await page.goto(url, { timeout: 10000, waitUntil: 'domcontentloaded' });
    return resp !== null && resp.status() < 500;
  } catch {
    return false;
  }
}

/** 登录 9091 (我们的 Express/Vue 界面) */
async function loginOur(page: Page) {
  await page.goto(OUR_URL, { waitUntil: 'networkidle' });
  // Element UI v2 inputs inside .login-box
  const inputs = page.locator('.login-box .el-input__inner');
  await inputs.nth(0).fill(OUR_CRED.username);
  await inputs.nth(1).fill(OUR_CRED.password);
  await page.click('.login-box .el-button');
  await page.waitForSelector('.area-ct-navbar', { timeout: 15000 });
  await page.waitForTimeout(1000);
}

/** 登录 9090 (真实 Cockpit) - 处理 iframe 架构 */
async function loginReal(page: Page) {
  await page.goto(REAL_URL, { waitUntil: 'domcontentloaded' });
  await page.waitForTimeout(2000);

  const userInput = page.locator('#login-user-input');
  if (await userInput.isVisible({ timeout: 8000 }).catch(() => false)) {
    await userInput.fill(REAL_CRED.username);
    await page.locator('#login-password-input').fill(REAL_CRED.password);
    await page.click('#login-button');
    // 真实 Cockpit 登录后加载 shell + iframes, 需更多时间
    await page.waitForTimeout(5000);
  }
}

/**
 * 获取真实 Cockpit 的内容 frame.
 * 真实 Cockpit 在导航切换后把内容渲染在 <iframe name="cockpit1:..."> 中.
 * 返回 Page 本身(用于截图)和 FrameLocator(用于交互).
 */
function getRealContentFrame(page: Page) {
  return page.frameLocator('iframe[name^="cockpit1"]');
}

/** 截图保存 */
async function screenshot(page: Page, name: string) {
  ensureScreenshotDir();
  const filepath = path.join(SCREENSHOT_DIR, `${name}.png`);
  await page.screenshot({ path: filepath, fullPage: true });
  console.log(`    📷 ${name}.png`);
  return filepath;
}

/** 对比截图 */
async function compareShots(ourPage: Page, realPage: Page, label: string) {
  await screenshot(ourPage, `ours_${label}`);
  await screenshot(realPage, `real_${label}`);
}

/** 提取元素列表的文本 */
async function getTexts(page: Page, selector: string): Promise<string[]> {
  const els = page.locator(selector);
  const count = await els.count();
  const texts: string[] = [];
  for (let i = 0; i < count; i++) {
    texts.push((await els.nth(i).innerText()).trim());
  }
  return texts;
}

// ==================== 测试用例 ====================

test.describe('Cockpit 9091 vs 9090 对比测试', () => {
  // 每个测试独立创建 context, 避免 beforeAll fixture 问题

  test('0. 服务可用性检查', async ({ browser }) => {
    const ctx = await browser.newContext({ ignoreHTTPSErrors: true });
    const page = await ctx.newPage();

    const ourOk = await isServiceReachable(page, OUR_URL);
    console.log(`  9091 (我们的): ${ourOk ? '✅ 可达' : '❌ 不可达'}`);

    const realOk = await isServiceReachable(page, REAL_URL);
    console.log(`  9090 (真实的): ${realOk ? '✅ 可达' : '❌ 不可达'}`);

    await ctx.close();

    if (!ourOk) {
      console.log('  ⚠️ 请先在服务器上启动我们的 Cockpit: cd /root/kvm-space && node cockpit/server/src/app.js');
    }
    if (!realOk) {
      console.log('  ⚠️ 真实 Cockpit 不可达, 请检查 systemctl status cockpit');
    }

    expect(ourOk, '9091 我们的 Cockpit 需要运行').toBe(true);
    expect(realOk, '9090 真实 Cockpit 需要运行').toBe(true);
  });

  test('1. 登录页截图对比', async ({ browser }) => {
    // 用未登录的干净上下文截取登录页
    const ctx1 = await browser.newContext({ ignoreHTTPSErrors: true });
    const ctx2 = await browser.newContext({ ignoreHTTPSErrors: true });
    const p1 = await ctx1.newPage();
    const p2 = await ctx2.newPage();

    await p1.goto(OUR_URL, { waitUntil: 'networkidle' });
    await screenshot(p1, 'ours_login');

    await p2.goto(REAL_URL, { waitUntil: 'domcontentloaded' });
    await p2.waitForTimeout(2000);
    await screenshot(p2, 'real_login');

    // 验证我们的登录页有必要元素
    await expect(p1.locator('.login-box')).toBeVisible();
    // 真实 Cockpit 登录页
    await expect(p2.locator('#login-user-input')).toBeVisible();

    await ctx1.close();
    await ctx2.close();
  });

  test('2. 导航栏结构对比', async ({ browser }) => {
    const ourCtx = await browser.newContext({ ignoreHTTPSErrors: true });
    const realCtx = await browser.newContext({ ignoreHTTPSErrors: true });
    const ourPage = await ourCtx.newPage();
    const realPage = await realCtx.newPage();

    await loginOur(ourPage);
    await loginReal(realPage);

    // === 我们的导航项 ===
    const ourTabs = await getTexts(ourPage, '.main-navbar > li');
    console.log(`  9091 导航项(${ourTabs.length}): ${ourTabs.join(' | ')}`);

    // === 真实 Cockpit 导航项 ===
    // 真实 Cockpit 的顶部导航在主页面(非 iframe)
    const realTabs = await getTexts(realPage, '#main-navbar > li');
    console.log(`  9090 导航项(${realTabs.length}): ${realTabs.join(' | ')}`);

    await compareShots(ourPage, realPage, 'navbar');

    // 验证: 至少3个 tab
    expect(ourTabs.length).toBeGreaterThanOrEqual(3);

    await ourCtx.close();
    await realCtx.close();
  });

  test('3. 本地服务器 - 系统概览', async ({ browser }) => {
    const ourCtx = await browser.newContext({ ignoreHTTPSErrors: true });
    const realCtx = await browser.newContext({ ignoreHTTPSErrors: true });
    const ourPage = await ourCtx.newPage();
    const realPage = await realCtx.newPage();

    await loginOur(ourPage);
    await loginReal(realPage);

    // 点击"本地服务器" (在我们的界面是第一个 tab, 可能默认已选中)
    await ourPage.click('.main-navbar > li:first-child');
    await ourPage.waitForTimeout(1500);

    // 真实 9090: 首页通常就是系统概览, 或者点 host-nav
    const realHostLink = realPage.locator('a[href="/system"]');
    if (await realHostLink.count() > 0) {
      await realHostLink.first().click();
      await realPage.waitForTimeout(3000);
    }

    await compareShots(ourPage, realPage, 'system_overview');

    // 验证我们的系统概览
    const content = await ourPage.locator('.area-ct-content').innerText();
    console.log(`  9091 系统概览(前200字): ${content.substring(0, 200)}`);
    expect(content).toContain('系统信息');

    await ourCtx.close();
    await realCtx.close();
  });

  test('4. 本地服务器 - 侧边栏对比', async ({ browser }) => {
    const ourCtx = await browser.newContext({ ignoreHTTPSErrors: true });
    const realCtx = await browser.newContext({ ignoreHTTPSErrors: true });
    const ourPage = await ourCtx.newPage();
    const realPage = await realCtx.newPage();

    await loginOur(ourPage);
    await loginReal(realPage);

    // 确保在"本地服务器"模式
    await ourPage.click('.main-navbar > li:first-child');
    await ourPage.waitForTimeout(1000);

    // 我们的侧边栏
    const ourItems = await getTexts(ourPage, '.area-ct-subnav .list-group-item');
    console.log(`  9091 侧边栏(${ourItems.length}): ${ourItems.join(' | ')}`);

    // 真实 Cockpit 侧边栏 - 在主页面的 nav 中
    const realItems = await getTexts(realPage, 'nav.sidebar a');
    if (realItems.length === 0) {
      // 备选选择器
      const fallback = await getTexts(realPage, '#sidebar-menu .list-group-item');
      console.log(`  9090 侧边栏(${fallback.length}): ${fallback.join(' | ')}`);
    } else {
      console.log(`  9090 侧边栏(${realItems.length}): ${realItems.join(' | ')}`);
    }

    await compareShots(ourPage, realPage, 'sidebar');

    await ourCtx.close();
    await realCtx.close();
  });

  test('5. 本地服务器 - 服务管理', async ({ browser }) => {
    const ourCtx = await browser.newContext({ ignoreHTTPSErrors: true });
    const ourPage = await ourCtx.newPage();
    await loginOur(ourPage);

    // 进入本地服务器
    await ourPage.click('.main-navbar > li:first-child');
    await ourPage.waitForTimeout(500);

    // 点击"服务"
    const servicesLink = ourPage.locator('.list-group-item', { hasText: '服务' });
    if (await servicesLink.isVisible().catch(() => false)) {
      await servicesLink.click();
      await ourPage.waitForTimeout(2000);
    }

    await screenshot(ourPage, 'ours_services');

    const content = await ourPage.locator('.area-ct-content').innerText();
    console.log(`  9091 服务页(前150字): ${content.substring(0, 150)}`);
    // 应该有服务列表或"系统服务"标题
    const hasServices = content.includes('系统服务') || content.includes('服务名称');
    expect(hasServices).toBe(true);

    await ourCtx.close();
  });

  test('6. 本地服务器 - 日志', async ({ browser }) => {
    const ourCtx = await browser.newContext({ ignoreHTTPSErrors: true });
    const ourPage = await ourCtx.newPage();
    await loginOur(ourPage);

    await ourPage.click('.main-navbar > li:first-child');
    await ourPage.waitForTimeout(500);

    const logsLink = ourPage.locator('.list-group-item', { hasText: '日志' });
    if (await logsLink.isVisible().catch(() => false)) {
      await logsLink.click();
      await ourPage.waitForTimeout(2000);
    }

    await screenshot(ourPage, 'ours_logs');

    const content = await ourPage.locator('.area-ct-content').innerText();
    expect(content).toContain('系统日志');

    await ourCtx.close();
  });

  test('7. 虚拟化模块', async ({ browser }) => {
    const ourCtx = await browser.newContext({ ignoreHTTPSErrors: true });
    const realCtx = await browser.newContext({ ignoreHTTPSErrors: true });
    const ourPage = await ourCtx.newPage();
    const realPage = await realCtx.newPage();

    await loginOur(ourPage);
    await loginReal(realPage);

    // 我们的: 点击"虚拟化" (第2个 tab)
    await ourPage.click('.main-navbar > li:nth-child(2)');
    await ourPage.waitForTimeout(2000);

    // 真实: 点击"虚拟化" tab
    const realVirtTab = realPage.locator('#main-navbar li', { hasText: '虚拟化' });
    if (await realVirtTab.isVisible({ timeout: 3000 }).catch(() => false)) {
      await realVirtTab.click();
      await realPage.waitForTimeout(3000);
    }

    await compareShots(ourPage, realPage, 'virtualization');

    // 我们的虚拟化模式下侧边栏应隐藏
    const hasSidebar = await ourPage.locator('.area-ct-subnav').isVisible().catch(() => false);
    console.log(`  虚拟化模式侧边栏: ${hasSidebar ? '显示(异常)' : '隐藏(正常)'}`);
    expect(hasSidebar).toBe(false);

    // 内容检查
    const content = await ourPage.locator('.area-ct-content').innerText();
    console.log(`  9091 虚拟化(前150字): ${content.substring(0, 150)}`);
    const valid = content.includes('集群状态') || content.includes('选择部署方式') || content.includes('虚拟化');
    expect(valid).toBe(true);

    await ourCtx.close();
    await realCtx.close();
  });

  test('8. 存储维护模块', async ({ browser }) => {
    const ourCtx = await browser.newContext({ ignoreHTTPSErrors: true });
    const realCtx = await browser.newContext({ ignoreHTTPSErrors: true });
    const ourPage = await ourCtx.newPage();
    const realPage = await realCtx.newPage();

    await loginOur(ourPage);
    await loginReal(realPage);

    // 我们的: 点击"存储维护" (第3个 tab)
    await ourPage.click('.main-navbar > li:nth-child(3)');
    await ourPage.waitForTimeout(2000);

    // 真实: 存储维护
    const realTab = realPage.locator('#main-navbar li', { hasText: '存储维护' });
    if (await realTab.isVisible({ timeout: 3000 }).catch(() => false)) {
      await realTab.click();
      await realPage.waitForTimeout(3000);
    }

    await compareShots(ourPage, realPage, 'maintain');

    // 侧边栏应隐藏
    const hasSidebar = await ourPage.locator('.area-ct-subnav').isVisible().catch(() => false);
    expect(hasSidebar).toBe(false);

    // 验证 4 个维护子标签
    const tabs = ourPage.locator('.maintain-tabs .maintain-tab');
    const tabCount = await tabs.count();
    console.log(`  存储维护标签数: ${tabCount}`);
    expect(tabCount).toBe(4);

    const tabNames: string[] = [];
    for (let i = 0; i < tabCount; i++) {
      tabNames.push((await tabs.nth(i).innerText()).trim());
    }
    console.log(`  标签: ${tabNames.join(' | ')}`);

    await ourCtx.close();
    await realCtx.close();
  });

  test('9. 存储维护 - 子功能逐一测试', async ({ browser }) => {
    const ctx = await browser.newContext({ ignoreHTTPSErrors: true });
    const page = await ctx.newPage();
    await loginOur(page);

    await page.click('.main-navbar > li:nth-child(3)');
    await page.waitForTimeout(1500);

    const subTabs = ['脑裂恢复', '备份管理', '日志记录', '网络监测'];

    for (const tabName of subTabs) {
      const tab = page.locator('.maintain-tab', { hasText: tabName });
      if (await tab.isVisible({ timeout: 2000 }).catch(() => false)) {
        await tab.click();
        await page.waitForTimeout(1500);
        await screenshot(page, `ours_maintain_${tabName}`);
        const content = await page.locator('.area-ct-content').innerText();
        console.log(`  ${tabName}: ${content.substring(0, 80)}...`);
      } else {
        console.log(`  ${tabName}: ⚠️ 标签不可见`);
      }
    }

    await ctx.close();
  });

  test('10. 导航样式对比', async ({ browser }) => {
    const ourCtx = await browser.newContext({ ignoreHTTPSErrors: true });
    const realCtx = await browser.newContext({ ignoreHTTPSErrors: true });
    const ourPage = await ourCtx.newPage();
    const realPage = await realCtx.newPage();

    await loginOur(ourPage);
    await loginReal(realPage);

    // 确保在本地服务器模式
    await ourPage.click('.main-navbar > li:first-child');
    await ourPage.waitForTimeout(800);

    // 获取样式信息
    const ourStyles = await ourPage.evaluate(() => {
      const navbar = document.querySelector('.area-ct-navbar');
      const sidebar = document.querySelector('.area-ct-subnav');
      const content = document.querySelector('.area-ct-content');
      return {
        navbar: navbar ? { height: getComputedStyle(navbar).height, bg: getComputedStyle(navbar).backgroundColor } : null,
        sidebar: sidebar ? { bg: getComputedStyle(sidebar).backgroundColor, width: getComputedStyle(sidebar).width } : null,
        content: content ? { bg: getComputedStyle(content).backgroundColor } : null,
      };
    });
    console.log('  9091 样式:', JSON.stringify(ourStyles, null, 2));

    const realStyles = await realPage.evaluate(() => {
      const navbar = document.querySelector('.area-ct-navbar');
      const sidebar = document.querySelector('.area-ct-subnav') || document.querySelector('nav.sidebar');
      const content = document.querySelector('.area-ct-content') || document.querySelector('#content');
      return {
        navbar: navbar ? { height: getComputedStyle(navbar).height, bg: getComputedStyle(navbar).backgroundColor } : null,
        sidebar: sidebar ? { bg: getComputedStyle(sidebar).backgroundColor, width: getComputedStyle(sidebar).width } : null,
        content: content ? { bg: getComputedStyle(content).backgroundColor } : null,
      };
    });
    console.log('  9090 样式:', JSON.stringify(realStyles, null, 2));

    await compareShots(ourPage, realPage, 'style_comparison');

    await ourCtx.close();
    await realCtx.close();
  });

  test('11. "登录管理控制台" 跳转验证', async ({ browser }) => {
    const ctx = await browser.newContext({ ignoreHTTPSErrors: true });
    const page = await ctx.newPage();
    await loginOur(page);

    // 查找 "登录管理控制台" 按钮/链接
    const mcLink = page.locator('text=管理控制台').first();
    if (await mcLink.isVisible({ timeout: 3000 }).catch(() => false)) {
      const href = await mcLink.getAttribute('href');
      console.log(`  管理控制台链接: ${href}`);
      // 应该指向 8444
      expect(href || '').toContain('8444');
    } else {
      console.log('  ⚠️ 未找到"管理控制台"入口');
    }

    await ctx.close();
  });
});
