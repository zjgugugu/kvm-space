const fs = require('fs');
const path = require('path');

const DIR = 'e:\\code\\kvm-space\\docs\\research\\mc_pages_refetch';
const files = fs.readdirSync(DIR).filter(f => f.endsWith('.html')).sort();

for (const fname of files) {
  const content = fs.readFileSync(path.join(DIR, fname), 'utf-8');
  
  if (content.includes('HTTP Status 404')) {
    console.log(`\n## ${fname} [STILL 404]`);
    continue;
  }
  
  // Title
  const titleM = content.match(/<title>(.*?)<\/title>/);
  const title = titleM ? titleM[1].trim() : '';
  
  // Tabs
  const tabSec = content.match(/id="myTab"[\s\S]*?<\/ul>/);
  let tabs = [];
  if (tabSec) {
    const re = /<a[^>]*>([^<]+)<\/a>/g;
    let m;
    while ((m = re.exec(tabSec[0])) !== null) tabs.push(m[1].trim());
  }
  
  // Grid columns
  const cols = {};
  const colRe = /(\w+_col)\s*:\s*"([^"]*)"/g;
  let cm;
  while ((cm = colRe.exec(content)) !== null) cols[cm[1]] = cm[2];
  
  // Buttons
  const btnRe = /class="btn[^"]*"[^>]*(?:title="([^"]*)")?[^>]*>([^<]*)</g;
  const btns = new Set();
  let bm;
  while ((bm = btnRe.exec(content)) !== null) {
    const label = (bm[1] || bm[2] || '').trim();
    if (label && label.length < 30) btns.add(label);
  }
  
  // Toolbar
  const tblRe = /class="tblControls"[\s\S]*?<\/div>/g;
  const toolbarBtns = [];
  let tm;
  while ((tm = tblRe.exec(content)) !== null) {
    const titles = tm[0].match(/title="([^"]*)"/g);
    if (titles) titles.forEach(t => {
      const v = t.match(/title="([^"]*)"/)[1];
      if (!toolbarBtns.includes(v)) toolbarBtns.push(v);
    });
  }
  
  // Tables
  const tableIds = [];
  const tIdRe = /<table\s+id="([^"]+)"/g;
  let ti;
  while ((ti = tIdRe.exec(content)) !== null) {
    if (ti[1] !== 'desk-table') tableIds.push(ti[1]);
  }
  
  // Actions
  const actions = {};
  const actRe = /(\w+_label)\s*:\s*"([^"]*)"/g;
  let am;
  while ((am = actRe.exec(content)) !== null) actions[am[1]] = am[2];
  
  // Left sidebar
  const sidebarLinks = [];
  const sideRe = /class="submenu-title"[^>]*>([^<]+)/g;
  let sm;
  while ((sm = sideRe.exec(content)) !== null) sidebarLinks.push(sm[1].trim());
  
  // sys-management sidebar
  const sysLinks = [];
  const sysRe = /class="[^"]*sidebar-menu[^"]*"[\s\S]*?<\/ul>/;
  const sysMatch = content.match(sysRe);
  
  console.log(`\n## ${fname}`);
  console.log(`  Title: ${title}`);
  if (tabs.length) console.log(`  Tabs: ${tabs.join(' | ')}`);
  if (tableIds.length) console.log(`  Tables: ${tableIds.join(', ')}`);
  if (Object.keys(cols).length) console.log(`  Grid Cols: ${JSON.stringify(cols)}`);
  if (btns.size) console.log(`  Buttons: ${[...btns].join(', ')}`);
  if (toolbarBtns.length) console.log(`  Toolbar: ${toolbarBtns.join(', ')}`);
  if (Object.keys(actions).length) console.log(`  Actions: ${JSON.stringify(actions)}`);
  if (sidebarLinks.length) console.log(`  Sidebar: ${sidebarLinks.join(', ')}`);
}
