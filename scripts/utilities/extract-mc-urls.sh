#!/bin/bash
# 从已抓取的MC页面中提取所有AJAX API URL
echo "=== 从MC HTML页面提取AJAX API URL ==="
echo ""

# 搜索所有可能的AJAX调用模式
cd /tmp/mc_pages 2>/dev/null || cd /opt/kvm-space/mc_pages 2>/dev/null || exit 1

echo "--- KSVD.ajax/post/get 调用 ---"
grep -rh "KSVD\." *.html 2>/dev/null | grep -oP "KSVD\.(ajax|post|get)\s*\(\s*['\"][^'\"]+['\"]" | sort -u

echo ""
echo "--- jQuery $.ajax url ---"
grep -rh 'url\s*:' *.html 2>/dev/null | grep -oP "url\s*:\s*['\"][^'\"]+['\"]" | sort -u | head -50

echo ""
echo "--- 直接的 $.post/$.get ---"
grep -rh '\$\.\(post\|get\|ajax\)' *.html 2>/dev/null | grep -oP "\\\$\.(post|get|ajax)\s*\(\s*['\"][^'\"]+['\"]" | sort -u | head -50

echo ""
echo "--- action= 表单URL ---"
grep -rh 'action=' *.html 2>/dev/null | grep -oP 'action="[^"]+' | sort -u

echo ""
echo "--- KSVD.* 函数调用 ---"
grep -rh 'KSVD\.' *.html 2>/dev/null | grep -oP 'KSVD\.[a-zA-Z.]+\(' | sort -u

echo ""
echo "--- 所有inline JS中的URL路径 ---"
grep -rh "mc/" *.html 2>/dev/null | grep -oP "['\"]/?mc/[^'\"]+['\"]" | sort -u | head -80
