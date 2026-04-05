#!/bin/bash
# Quick API test - all endpoints
BASE="https://localhost:8444"
TOKEN=$(curl -sk -X POST $BASE/api/auth/login -H "Content-Type: application/json" -d '{"username":"root","password":"root"}' | python -c "import sys,json; print json.loads(sys.stdin.read())['token']" 2>/dev/null)
echo "TOKEN=${#TOKEN} chars"

test_ep() {
  local ep=$1
  local resp=$(curl -sk "$BASE/api/$ep" -H "Authorization: Bearer $TOKEN" 2>/dev/null)
  local is_html=$(echo "$resp" | head -1 | grep -c "DOCTYPE")
  if [ "$is_html" = "1" ]; then
    echo "FAIL $ep -> HTML (404/SPA fallback)"
  else
    local len=${#resp}
    echo "OK   $ep -> ${len} bytes: $(echo "$resp" | head -c 120)"
  fi
}

for ep in dashboard/overview vms hosts templates storage/pools storage/volumes networks networks/subnets events alerts users system/config stats/user-login publish-rules specs desktop-pools backups snapshot-policies clients recycle-bin files scaling/strategies scaling/groups system-extra/labels system-extra/affinity-groups network-extra/port-groups network-extra/vlan-pools apps/software apps/layers apps/control-rules apps/virtual-groups apps/virtual-sessions apps/software-publish terminal-bindings; do
  test_ep "$ep"
done
