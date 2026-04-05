#!/bin/bash
# 从mc.js和其他JS文件提取所有AJAX API URL
MC_JS="/usr/lib/ksvd/etc/apache-tomcat/webapps/mc/js/hnkylin/mc.js"
MC_DIR="/usr/lib/ksvd/etc/apache-tomcat/webapps/mc"

echo "=== mc.js中所有URL路径 ==="
grep -oP "url\s*:\s*['\"][^'\"]+['\"]" "$MC_JS" 2>/dev/null | sort -u

echo ""
echo "=== mc.js中所有$.ajax/$.post/$.get ==="
grep -oP "\\\$\.(ajax|post|get)\s*\(\s*['\"][^'\"]+['\"]" "$MC_JS" 2>/dev/null | sort -u

echo ""  
echo "=== 所有GSP视图中的AJAX URL ==="
find "$MC_DIR/WEB-INF" -name "*.gsp" -exec grep -ohP "url\s*:\s*['\"][^'\"]+['\"]" {} \; 2>/dev/null | sort -u | head -100

echo ""
echo "=== GSP中的g:remoteLink/g:formRemote action ==="  
find "$MC_DIR/WEB-INF" -name "*.gsp" -exec grep -ohP '(action|url)\s*=\s*"[^"]+' {} \; 2>/dev/null | sort -u | head -100

echo ""
echo "=== Grails controller中的action列表 ==="
find "$MC_DIR/WEB-INF" -name "*Controller*" -type f 2>/dev/null | head -5
ls -la "$MC_DIR/WEB-INF/grails-app/controllers/" 2>/dev/null | head -10
# Grails编译后controller信息
find "$MC_DIR/WEB-INF/classes" -name "*Controller*" -type f 2>/dev/null | head -30

echo ""
echo "=== URL映射 ==="
cat "$MC_DIR/WEB-INF/grails-app/conf/UrlMappings.groovy" 2>/dev/null | head -50
find "$MC_DIR/WEB-INF/classes" -name "UrlMappings*" 2>/dev/null

echo ""
echo "=== JS文件中所有createLink ==="
grep -rh "createLink" "$MC_DIR/js/" 2>/dev/null | grep -oP "createLink\s*\([^)]+\)" | sort -u | head -50

echo ""
echo "=== GSP中所有createLink ==="
find "$MC_DIR/WEB-INF" -name "*.gsp" -exec grep -ohP 'createLink[^}]*}' {} \; 2>/dev/null | sort -u | head -100
