# encoding: utf-8
import os, re, json

DIR = r"e:\code\kvm-space\docs\research\mc_pages"
results = []

for fname in sorted(os.listdir(DIR)):
    if not fname.endswith('.html'):
        continue
    fpath = os.path.join(DIR, fname)
    with open(fpath, 'r', encoding='utf-8', errors='ignore') as f:
        content = f.read()
    
    # Check 404
    if 'HTTP Status 404' in content:
        results.append({'file': fname, 'status': '404'})
        continue
    
    info = {'file': fname, 'status': 'OK'}
    
    # Title
    m = re.search(r'<title>(.*?)</title>', content)
    info['title'] = m.group(1).strip() if m else ''
    
    # Nav tabs
    tabs = re.findall(r'<a\s+href="[^"]*"[^>]*>([^<]+)</a>\s*</li>', content)
    # Filter to tab-like items inside nav-tabs
    tab_sections = re.findall(r'id="myTab".*?</ul>', content, re.S)
    tab_items = []
    for sec in tab_sections:
        tab_items.extend(re.findall(r'<a[^>]*>([^<]+)</a>', sec))
    if tab_items:
        info['tabs'] = tab_items
    
    # jqGrid columns - look for updatei18nMap with _col patterns
    i18n_blocks = re.findall(r'KSVD\.updatei18nMap\(\{(.*?)\}\)', content, re.S)
    cols = {}
    for block in i18n_blocks:
        col_matches = re.findall(r'(\w+_col)\s*:\s*"([^"]*)"', block)
        for key, val in col_matches:
            cols[key] = val
    if cols:
        info['grid_columns'] = cols
    
    # Also look for colNames arrays with string literals  
    col_name_arrays = re.findall(r'colNames\s*:\s*\[(.*?)\]', content, re.S)
    for arr in col_name_arrays:
        literals = re.findall(r'"([^"]+)"', arr)
        if literals and len(literals) > 2:
            info['colNames_literal'] = literals
    
    # Buttons - look for class="btn" with text
    btn_matches = re.findall(r'class="btn[^"]*"[^>]*(?:title="([^"]*)")?[^>]*>([^<]*)<', content)
    btns = []
    for title, text in btn_matches:
        label = (title or text).strip()
        if label and label not in btns and len(label) < 30:
            btns.append(label)
    if btns:
        info['buttons'] = btns
    
    # tblControls buttons
    tbl_btns = re.findall(r'class="tblControls".*?</div>', content, re.S)
    for tb in tbl_btns:
        btn_texts = re.findall(r'title="([^"]*)"', tb)
        if btn_texts:
            info['toolbar_buttons'] = btn_texts
    
    # Left sidebar items
    sidebar_items = re.findall(r'class="submenu-title"[^>]*>([^<]+)', content)
    if sidebar_items:
        info['sidebar'] = sidebar_items
    
    # i18n labels and action labels
    action_labels = re.findall(r'(\w+_label)\s*:\s*"([^"]*)"', content)
    if action_labels:
        info['action_labels'] = {k: v for k, v in action_labels}
    
    results.append(info)

# Output as formatted text
for r in results:
    if r['status'] == '404':
        print(f"\n## {r['file']} [404 - NOT CAPTURED]")
        continue
    
    print(f"\n## {r['file']}")
    print(f"  Title: {r.get('title', 'N/A')}")
    if 'tabs' in r:
        print(f"  Tabs: {', '.join(r['tabs'])}")
    if 'grid_columns' in r:
        print(f"  Grid Columns: {r['grid_columns']}")
    if 'colNames_literal' in r:
        print(f"  ColNames: {r['colNames_literal']}")
    if 'buttons' in r:
        print(f"  Buttons: {', '.join(r['buttons'])}")
    if 'toolbar_buttons' in r:
        print(f"  Toolbar: {', '.join(r['toolbar_buttons'])}")
    if 'action_labels' in r:
        print(f"  Actions: {r['action_labels']}")
