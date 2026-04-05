#!/bin/bash
COOKIE=/tmp/mc_404_ck.txt
BASE="https://localhost:8443/mc"

echo "=== serverVirtualization links ==="
curl -sk -b $COOKIE "$BASE/serverVirtualization/index" 2>/dev/null | grep -oP 'href="[^"]*"' | sort -u | head -40

echo ""
echo "=== Storage links ==="
curl -sk -b $COOKIE "$BASE/storageNew/storageNew" 2>/dev/null | grep -oP 'href="[^"]*"' | sort -u | head -20

echo ""
echo "=== Servers links ==="
curl -sk -b $COOKIE "$BASE/servers/clusterMasters" 2>/dev/null | grep -oP 'href="[^"]*"' | sort -u | head -20

echo ""
echo "=== Backup links ==="
curl -sk -b $COOKIE "$BASE/backup/backupServer" 2>/dev/null | grep -oP 'href="[^"]*"' | sort -u | head -20

echo ""
echo "=== System management left nav ==="
curl -sk -b $COOKIE "$BASE/generalSettings/showGlobalPolicy" 2>/dev/null | grep -oP 'href="/mc/[^"]*"' | sort -u

echo ""
echo "=== All unique /mc/ links from dashboard ==="
curl -sk -b $COOKIE "$BASE/reporting/dashboard" 2>/dev/null | grep -oP 'href="/mc/[^"]*"' | sort -u
