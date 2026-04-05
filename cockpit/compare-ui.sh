#!/bin/bash
# Compare real Cockpit 9090 UI structure with our 9091 
echo "=============================================="
echo " Cockpit Frontend UI Comparison"
echo "=============================================="

echo ""
echo "=== Real Cockpit 9090 Page Structure ==="
echo "--- manifest.json ---"
cat /usr/share/cockpit/virtualization/manifest.json 2>/dev/null || echo "N/A"

echo ""
echo "--- Real Cockpit HTML structure ---"
cat /usr/share/cockpit/virtualization/index.html 2>/dev/null

echo ""
echo "--- Real Cockpit JS files ---"
ls -la /usr/share/cockpit/virtualization/js/ 2>/dev/null || echo "N/A"

echo ""
echo "--- Real Cockpit bundle.min.js key functions ---"
grep -oP 'function\s+\w+' /usr/share/cockpit/virtualization/js/bundle.min.js 2>/dev/null | sort | head -50

echo ""
echo "--- Real Cockpit JS source - key components ---"
# Check the source JS files we analyzed before
for f in /usr/share/cockpit/virtualization/js/*.js; do
  echo "File: $f ($(wc -l < $f) lines)"
done

echo ""
echo "=== Our Cockpit 9091 Page Structure ==="
echo "--- Key UI Features ---"
grep -oP "(?:el-tab-pane|el-table-column|el-form-item|v-if=\"|currentModule|maintainTab|deployStep|deployMode|settingTab)[^\"]*" /opt/kvm-space/cockpit/web/index.html | sort | uniq -c | sort -rn | head -30

echo ""
echo "--- Module Structure ---"
grep -n "====" /opt/kvm-space/cockpit/web/index.html 

echo ""
echo "--- Methods ---"
grep -oP '\w+:\s*function\s*\(' /opt/kvm-space/cockpit/web/index.html | sed 's/: function (//' | sort

echo ""
echo "--- Total lines ---"
wc -l /opt/kvm-space/cockpit/web/index.html
