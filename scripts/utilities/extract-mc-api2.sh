#!/bin/bash
# 找出所有Grails controllers和actions  
MC="/usr/lib/ksvd/etc/apache-tomcat/webapps/mc"
VIEWS="$MC/WEB-INF/grails-app/views"

echo "=== Grails Controllers ==="
find "$MC/WEB-INF/classes/com/hnkylin/mc" -maxdepth 2 -name '*Controller.class' | sed 's/.*\///' | sed 's/\.class//' | sort

echo ""
echo "=== GSP视图目录结构 ==="
ls -d "$VIEWS"/*/ 2>/dev/null | sed "s|$VIEWS/||"

echo ""
echo "=== 每个视图文件夹的GSP文件 ==="
for d in "$VIEWS"/*/; do
    name=$(basename "$d")
    files=$(ls "$d"/*.gsp 2>/dev/null | sed 's/.*\///' | sed 's/\.gsp//' | tr '\n' ',' | sed 's/,$//')
    if [ -n "$files" ]; then
        echo "$name: $files"
    fi
done

echo ""
echo "=== 从dashboard GSP提取AJAX URL ==="
if [ -f "$VIEWS/monitoring/dashboard.gsp" ]; then
    grep -oP "controller:\s*'[^']+'" "$VIEWS/monitoring/dashboard.gsp" | sort -u
    grep -oP "action:\s*'[^']+'" "$VIEWS/monitoring/dashboard.gsp" | sort -u
fi

echo ""
echo "=== GSP中所有controller:action组合 ==="
find "$VIEWS" -name "*.gsp" | while read f; do
    name=$(echo "$f" | sed "s|$VIEWS/||")
    pairs=$(grep -oP "controller:\s*'([^']+)'[^}]*action:\s*'([^']+)'" "$f" 2>/dev/null | sort -u)
    if [ -n "$pairs" ]; then
        echo "[$name] $pairs"
    fi
done

echo ""
echo "=== 直接从mc.js提取所有API调用 ==="
MC_JS="$MC/js/hnkylin/mc.js"
# 提取所有 KSVD.ajax 调用中的URL
python3 -c "
import re
with open('$MC_JS','r',encoding='utf-8',errors='ignore') as f:
    content = f.read()
# 找所有 url: 和 action: 相关的字符串
urls = re.findall(r\"url\s*[:=]\s*['\\\"]([^'\\\"]+)\", content)
for u in sorted(set(urls)):
    print('URL:', u)
" 2>/dev/null

echo ""
echo "=== GSP中所有g:remoteLink ==="
find "$VIEWS" -name "*.gsp" -exec grep -ohP "g:remoteLink[^>]*>" {} \; 2>/dev/null | head -50

echo ""
echo "=== 最关键: mc.js中KSVD对象的所有方法中的URL ==="
python3 -c "
import re
with open('$MC_JS','r',encoding='utf-8',errors='ignore') as f:
    content = f.read()
# 找 $.ajax({ 或 $.post( 或 $.get( 调用
ajax_calls = re.findall(r'\\\$\.(ajax|post|get)\s*\(\s*[\{\"'\''](.*?)[\}\"'\'']', content[:50000], re.DOTALL)
for method, body in ajax_calls[:30]:
    url_match = re.search(r\"url\s*:\s*['\\\"]([^'\\\"]+)\", body)
    if url_match:
        print(f'{method}: {url_match.group(1)}')
    else:
        print(f'{method}: (inline) {body[:80]}')
" 2>/dev/null
