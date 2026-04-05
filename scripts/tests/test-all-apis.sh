#!/bin/bash
# Comprehensive API test for all modules
RESP=$(curl -s -X POST http://localhost:8444/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"root","password":"root"}')
TOKEN=$(echo "$RESP" | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])" 2>/dev/null)

test_api() {
  local name="$1"
  local url="$2"
  echo "=== $name ==="
  RESP=$(curl -s "$url" -H "Authorization: Bearer $TOKEN")
  echo "$RESP" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    if isinstance(d, list):
        print('  items: %d' % len(d))
        if d: print('  sample keys: %s' % list(d[0].keys())[:8])
    elif isinstance(d, dict):
        if 'data' in d and isinstance(d['data'], list):
            print('  data items: %d, total: %s' % (len(d['data']), d.get('total','?')))
            if d['data']: print('  sample keys: %s' % list(d['data'][0].keys())[:8])
        elif 'error' in d:
            print('  ERROR: %s' % d['error'])
        else:
            for k,v in sorted(d.items()):
                if isinstance(v, dict):
                    print('  %s: %s' % (k, str(v)[:120]))
                elif isinstance(v, list):
                    print('  %s: %d items' % (k, len(v)))
                else:
                    print('  %s: %s' % (k, str(v)[:100]))
    else:
        print('  raw: %s' % str(d)[:200])
except:
    print('  PARSE ERROR - raw: %s' % sys.stdin.read()[:200])
" 2>/dev/null
  echo ""
}

test_api "Dashboard Overview" "http://localhost:8444/api/dashboard/overview"
test_api "Dashboard Trends" "http://localhost:8444/api/dashboard/trends"
test_api "Dashboard User Stats" "http://localhost:8444/api/dashboard/user-stats"
test_api "Dashboard User Ranking" "http://localhost:8444/api/dashboard/user-ranking"
test_api "Dashboard Recent Alerts" "http://localhost:8444/api/dashboard/recent-alerts"
test_api "VM List" "http://localhost:8444/api/vms"
test_api "Host List" "http://localhost:8444/api/hosts"
test_api "User List" "http://localhost:8444/api/users"
test_api "Network List" "http://localhost:8444/api/networks"
test_api "Storage Pools" "http://localhost:8444/api/storage/pools"
test_api "Templates" "http://localhost:8444/api/templates"
test_api "Events" "http://localhost:8444/api/events"
test_api "System Settings" "http://localhost:8444/api/system/settings"
test_api "Alert Settings" "http://localhost:8444/api/alerts/settings"
test_api "Specs" "http://localhost:8444/api/specs"
test_api "Snapshot Policies" "http://localhost:8444/api/snapshot-policies"
test_api "Backups" "http://localhost:8444/api/backups"
test_api "Publish Rules" "http://localhost:8444/api/publish-rules"
test_api "Stats Overview" "http://localhost:8444/api/stats/overview"
