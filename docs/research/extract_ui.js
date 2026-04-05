const fs = require('fs');
const path = require('path');

const DIR = 'e:\\code\\kvm-space\\docs\\research\\mc_pages';
const files = fs.readdirSync(DIR).filter(f => f.endsWith('.html')).sort();

const results = [];

for (const fname of files) {
  const content = fs.readFileSync(path.join(DIR, fname), 'utf-8');
  
  if (content.includes('HTTP Status 404')) {
    results.push({ file: fname, status: '404' });
    continue;
  }
  
  const info = { file: fname, status: 'OK' };
  
  // Title
  const titleM = content.match(/<title>(.*?)<\/title>/);
  info.title = titleM ? titleM[1].trim() : '';
  
  // Tabs in myTab
  const tabSec = content.match(/id="myTab"[\s\S]*?<\/ul>/);
  if (tabSec) {
    const tabs = [];
    const re = /<a[^>]*>([^<]+)<\/a>/g;
    let m;
    while ((m = re.exec(tabSec[0])) !== null) {
      tabs.push(m[1].trim());
    }
    if (tabs.length) info.tabs = tabs;
  }
  
  // Grid columns from i18n (_col pattern)
  const cols = {};
  const colRe = /(\w+_col)\s*:\s*"([^"]*)"/g;
  let cm;
  while ((cm = colRe.exec(content)) !== null) {
    cols[cm[1]] = cm[2];
  }
  if (Object.keys(cols).length) info.grid_columns = cols;
  
  // Buttons with class="btn"
  const btnRe = /class="btn[^"]*"[^>]*(?:title="([^"]*)")?[^>]*>([^<]*)</g;
  const btns = new Set();
  let bm;
  while ((bm = btnRe.exec(content)) !== null) {
    const label = (bm[1] || bm[2] || '').trim();
    if (label && label.length < 30) btns.add(label);
  }
  if (btns.size) info.buttons = [...btns];
  
  // Toolbar buttons (tblControls)
  const tblRe = /class="tblControls"[\s\S]*?<\/div>/g;
  const toolbarBtns = [];
  let tm;
  while ((tm = tblRe.exec(content)) !== null) {
    const titles = tm[0].match(/title="([^"]*)"/g);
    if (titles) {
      titles.forEach(t => {
        const v = t.match(/title="([^"]*)"/)[1];
        if (!toolbarBtns.includes(v)) toolbarBtns.push(v);
      });
    }
  }
  if (toolbarBtns.length) info.toolbar = toolbarBtns;
  
  // Action labels
  const actions = {};
  const actRe = /(\w+_label)\s*:\s*"([^"]*)"/g;
  let am;
  while ((am = actRe.exec(content)) !== null) {
    actions[am[1]] = am[2];
  }
  if (Object.keys(actions).length) info.actions = actions;
  
  // Main table IDs
  const tableIds = [];
  const tIdRe = /<table\s+id="([^"]+)"/g;
  let ti;
  while ((ti = tIdRe.exec(content)) !== null) {
    if (ti[1] !== 'desk-table') tableIds.push(ti[1]);
  }
  if (tableIds.length) info.tables = tableIds;
  
  results.push(info);
}

// Output
for (const r of results) {
  if (r.status === '404') {
    console.log(`\n## ${r.file} [404]`);
    continue;
  }
  console.log(`\n## ${r.file}`);
  console.log(`  Title: ${r.title}`);
  if (r.tabs) console.log(`  Tabs: ${r.tabs.join(' | ')}`);
  if (r.tables) console.log(`  Tables: ${r.tables.join(', ')}`);
  if (r.grid_columns) console.log(`  Grid Cols: ${JSON.stringify(r.grid_columns)}`);
  if (r.buttons) console.log(`  Buttons: ${r.buttons.join(', ')}`);
  if (r.toolbar) console.log(`  Toolbar: ${r.toolbar.join(', ')}`);
  if (r.actions) console.log(`  Actions: ${JSON.stringify(r.actions)}`);
}
