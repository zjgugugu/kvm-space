#!/bin/bash
# Analyze real cockpit bundle.min.js
BUNDLE=/usr/share/cockpit/virtualization/bundle.min.js

echo "=== cockpit.* API calls ==="
cat $BUNDLE | tr ',' '\n' | grep 'cockpit\.' | grep -oP 'cockpit\.\w+' | sort -u

echo ""
echo "=== Vue component names ==="
cat $BUNDLE | tr ',' '\n' | grep -oP 'name:\s*"[^"]*"' | sort -u

echo ""
echo "=== Chinese strings (features) ==="
cat $BUNDLE | grep -oP '"[^"]*[\x{4e00}-\x{9fff}][^"]*"' | sort -u

echo ""
echo "=== Key feature keywords ==="
cat $BUNDLE | tr ',' '\n' | grep -iP '脑裂|备份|日志|网络|部署|集群|虚拟化|存储|仲裁|维护|恢复|监测|NFS|CIFS|GlusterFS|NTP|LDAP|docker' | head -40
