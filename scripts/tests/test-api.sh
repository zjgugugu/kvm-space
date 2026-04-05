#!/bin/bash
# Test API endpoints
BASE="http://localhost:8444"

echo "=== Testing Login ==="
TOKEN=$(curl -s -X POST "$BASE/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}' | python -c "import sys,json; print(json.load(sys.stdin)['token'])")
echo "Token: ${TOKEN:0:30}..."

echo ""
echo "=== Testing Dashboard ==="
curl -s "$BASE/api/dashboard/overview" -H "Authorization: Bearer $TOKEN" | python -m json.tool 2>/dev/null | head -20

echo ""
echo "=== Testing VMs ==="
curl -s "$BASE/api/vms" -H "Authorization: Bearer $TOKEN" | python -c "import sys,json; d=json.load(sys.stdin); print('Total VMs:', d.get('total',0))"

echo ""
echo "=== Testing Hosts ==="
curl -s "$BASE/api/hosts" -H "Authorization: Bearer $TOKEN" | python -c "import sys,json; d=json.load(sys.stdin); print('Hosts:', len(d) if isinstance(d,list) else d)"

echo ""
echo "=== Testing Templates ==="
curl -s "$BASE/api/templates" -H "Authorization: Bearer $TOKEN" | python -c "import sys,json; d=json.load(sys.stdin); print('Templates:', len(d) if isinstance(d,list) else d)"

echo ""
echo "=== Testing Networks ==="
curl -s "$BASE/api/networks" -H "Authorization: Bearer $TOKEN" | python -c "import sys,json; d=json.load(sys.stdin); print('Networks:', len(d) if isinstance(d,list) else d)"

echo ""
echo "=== Testing Storage ==="
curl -s "$BASE/api/storage/pools" -H "Authorization: Bearer $TOKEN" | python -c "import sys,json; d=json.load(sys.stdin); print('Storage pools:', len(d) if isinstance(d,list) else d)"

echo ""
echo "=== Testing Users ==="
curl -s "$BASE/api/users" -H "Authorization: Bearer $TOKEN" | python -c "import sys,json; d=json.load(sys.stdin); print('Users:', len(d) if isinstance(d,list) else d)"

echo ""
echo "=== Testing Specs ==="
curl -s "$BASE/api/specs" -H "Authorization: Bearer $TOKEN" | python -c "import sys,json; d=json.load(sys.stdin); print('Specs:', len(d) if isinstance(d,list) else d)"

echo ""
echo "=== Testing Events ==="
curl -s "$BASE/api/events" -H "Authorization: Bearer $TOKEN" | python -c "import sys,json; d=json.load(sys.stdin); print('Events response:', type(d).__name__)"

echo ""
echo "=== Testing Alerts ==="
curl -s "$BASE/api/alerts" -H "Authorization: Bearer $TOKEN" | python -c "import sys,json; d=json.load(sys.stdin); print('Alerts:', len(d) if isinstance(d,list) else d)"

echo ""
echo "=== Testing System Config ==="
curl -s "$BASE/api/system/config" -H "Authorization: Bearer $TOKEN" | python -c "import sys,json; d=json.load(sys.stdin); print('Config items:', len(d) if isinstance(d,list) else d)"

echo ""
echo "=== Testing Stats ==="
curl -s "$BASE/api/stats" -H "Authorization: Bearer $TOKEN" | python -m json.tool 2>/dev/null | head -15

echo ""
echo "=== Testing Frontend ==="
curl -s -o /dev/null -w "HTTP %{http_code}, Size: %{size_download} bytes" "$BASE/"

echo ""
echo ""
echo "=== ALL TESTS COMPLETE ==="
