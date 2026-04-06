#!/bin/bash
# Corrected MC 8444 Full Module Test - Using ACTUAL frontend endpoint names
set -e

TOKEN=$(curl -sk -X POST https://localhost:8444/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"root","password":"root"}' | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])")

echo "Login: OK"
PASS=0; FAIL=0; TOTAL=0

t() {
  local method=$1 ep=$2
  TOTAL=$((TOTAL+1))
  RESP=$(curl -sk -X $method -H "Authorization: Bearer $TOKEN" "https://localhost:8444/api/$ep" 2>/dev/null)
  IS=$(echo "$RESP" | python3 -c "import sys,json; json.load(sys.stdin); print('Y')" 2>/dev/null || echo "N")
  if [ "$IS" = "Y" ]; then
    PASS=$((PASS+1))
    echo "  OK  $method $ep"
  else
    FAIL=$((FAIL+1))
    echo "  FAIL $method $ep → $(echo "$RESP" | head -c 80)"
  fi
}

echo ""
echo "=== Dashboard ==="
t GET dashboard/overview
t GET dashboard/trends
t GET dashboard/user-stats
t GET dashboard/user-ranking
t GET dashboard/recent-alerts

echo ""
echo "=== VMs ==="
t GET vms
t GET "vms?status=running"

echo ""
echo "=== Hosts ==="
t GET hosts
t GET hosts/1

echo ""
echo "=== Templates ==="
t GET templates

echo ""
echo "=== Networks ==="
t GET networks
t GET networks/vswitches
t GET networks/subnets
t GET networks/security-groups
t GET networks/mac-pools

echo ""
echo "=== Storage ==="
t GET storage/pools
t GET storage/volumes
t GET storage/alerts

echo ""
echo "=== Users ==="
t GET users

echo ""
echo "=== Events ==="
t GET events

echo ""
echo "=== Alerts ==="
t GET alerts

echo ""
echo "=== Specs ==="
t GET specs

echo ""
echo "=== Publish Rules ==="
t GET publish-rules

echo ""
echo "=== Backups ==="
t GET backups

echo ""
echo "=== Snapshot Policies ==="
t GET snapshot-policies

echo ""
echo "=== System ==="
t GET system/config
t GET system/policies
t GET system/password-policy
t GET system/access-policy
t GET system/smtp
t GET system/notify-config

echo ""
echo "=== Stats ==="
t GET stats
t GET stats/user-login
t GET stats/usage-time
t GET stats/alert-stats

echo ""
echo "=== Desktop Pools ==="
t GET desktop-pools

echo ""
echo "=== App Management ==="
t GET apps/layers
t GET apps/software
t GET apps/software-publish
t GET apps/control-rules
t GET apps/virtual-groups
t GET apps/virtual-sessions

echo ""
echo "=== Clients ==="
t GET clients

echo ""
echo "=== Scaling ==="
t GET scaling/strategies
t GET scaling/groups
t GET scaling/load-balancers
t GET scaling/drs
t GET scaling/dpm

echo ""
echo "=== Recycle Bin ==="
t GET recycle-bin

echo ""
echo "=== File Manage ==="
t GET files

echo ""
echo "=== Network Extra ==="
t GET network-extra/vlan-pools
t GET network-extra/port-mirroring
t GET network-extra/firewalls
t GET network-extra/port-groups

echo ""
echo "=== System Extra ==="
t GET system-extra/zombie-servers
t GET system-extra/detection
t GET system-extra/boot-order
t GET system-extra/organizations
t GET system-extra/affinity-groups
t GET system-extra/labels

echo ""
echo "=== Terminal Bindings ==="
t GET terminal-bindings

echo ""
echo "========================================="
echo "  TOTAL: $PASS passed, $FAIL failed (of $TOTAL)"
echo "========================================="
