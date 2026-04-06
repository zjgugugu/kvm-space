#!/bin/bash
# Compare real MC 8443 with our MC 8444
echo "========================================="
echo "  Real MC 8443 vs Our MC 8444"
echo "========================================="

# Login to real MC 8443
echo ""
echo "=== Real MC 8443 Login ==="
REAL_COOKIE=$(curl -sk -X POST 'https://localhost:8443/mc/login' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d 'username=mcadmin&password=987qwe654asd*' \
  -c /tmp/real-mc-cookies.txt \
  -D /tmp/real-mc-headers.txt \
  -L -o /dev/null -w "%{http_code}" 2>/dev/null)
echo "Login HTTP: $REAL_COOKIE"

# Check cookie
if [ -f /tmp/real-mc-cookies.txt ]; then
  echo "Cookies:"
  cat /tmp/real-mc-cookies.txt | grep -v "^#" | grep -v "^$"
fi

# Try to access main page
echo ""
echo "=== Real MC 8443 Main Page ==="
MAIN_STATUS=$(curl -sk -o /dev/null -w "%{http_code}" -b /tmp/real-mc-cookies.txt https://localhost:8443/mc/dashboard/index)
echo "Dashboard page: HTTP $MAIN_STATUS"

# Try known real MC URLs
echo ""
echo "=== Real MC 8443 Key Pages ==="
for path in mc/dashboard/index mc/serverVirtual/serverVirtualMain mc/host/index mc/template/index mc/network/index mc/storage/index mc/user/index mc/event/index; do
  STATUS=$(curl -sk -o /dev/null -w "%{http_code}" -b /tmp/real-mc-cookies.txt "https://localhost:8443/$path")
  echo "  /$path: HTTP $STATUS"
done

# Try real MC API patterns (Grails JSON endpoints)
echo ""
echo "=== Real MC 8443 API Endpoints ==="
for path in \
  "mc/serverVirtual/getServerVirtualList?sord=desc&sidx=&rows=20&page=1" \
  "mc/host/getHostList?sord=desc&sidx=&rows=20&page=1" \
  "mc/template/getTemplateList?sord=desc&sidx=&rows=20&page=1" \
  "mc/network/getNetList?sord=desc&sidx=&rows=20&page=1" \
  "mc/desktop/getDesktopOverview" \
  "mc/dashboard/getDashBoardVmInfo" \
  "mc/host/getHostOverview"; do
  RESP=$(curl -sk -b /tmp/real-mc-cookies.txt "https://localhost:8443/$path" 2>/dev/null)
  IS_JSON=$(echo "$RESP" | python3 -c "import sys,json; json.load(sys.stdin); print('JSON')" 2>/dev/null || echo "NOT_JSON")
  echo "  /$path"
  echo "    [$IS_JSON] $(echo "$RESP" | head -c 200)"
  echo ""
done

# Login to our MC 8444
echo ""
echo "=== Our MC 8444 Login ==="
OUR_TOKEN=$(curl -sk -X POST https://localhost:8444/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"root","password":"root"}' | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])")
echo "Our token: ${OUR_TOKEN:0:20}..."

# Compare key data points
echo ""
echo "=== Data Comparison ==="

echo "--- Our Hosts ---"
curl -sk -H "Authorization: Bearer $OUR_TOKEN" https://localhost:8444/api/hosts 2>/dev/null | python3 -c "
import sys,json
data = json.load(sys.stdin).get('data',[])
for h in (data if isinstance(data, list) else []):
  print(f'  {h.get(\"name\")}: ip={h.get(\"ip\")}, cpu={h.get(\"cpu_total\")}, mem={h.get(\"mem_total\")}MB, arch={h.get(\"arch\")}')
" 2>/dev/null

echo ""
echo "--- Real Host Info (from system) ---"
echo "  hostname: $(hostname)"
echo "  ip: $(hostname -I | awk '{print $1}')"
echo "  cpu: $(nproc)"
echo "  mem: $(free -m | awk '/Mem:/ {print $2}')MB"
echo "  arch: $(uname -m)"
echo "  kernel: $(uname -r)"
echo "  os: $(cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d '\"')"

echo ""
echo "--- Our VMs vs Real VMs ---"
echo "Our API:"
curl -sk -H "Authorization: Bearer $OUR_TOKEN" https://localhost:8444/api/vms 2>/dev/null | python3 -c "
import sys,json
data = json.load(sys.stdin).get('data',[])
for v in (data if isinstance(data, list) else []):
  print(f'  {v.get(\"name\")}: status={v.get(\"status\")}, cpu={v.get(\"cpu\")}, mem={v.get(\"memory\")}MB')
" 2>/dev/null

echo ""
echo "Real virsh:"
virsh list --all --title 2>&1

echo ""
echo "--- Our Networks ---"
curl -sk -H "Authorization: Bearer $OUR_TOKEN" https://localhost:8444/api/networks 2>/dev/null | python3 -c "
import sys,json
data = json.load(sys.stdin).get('data',[])
for n in (data if isinstance(data, list) else []):
  print(f'  {n.get(\"name\")}: type={n.get(\"type\")}, vlan={n.get(\"vlan_id\")}, status={n.get(\"status\")}')
" 2>/dev/null

echo ""
echo "Real virsh networks:"
virsh net-list --all 2>&1

echo ""
echo "--- Our Storage ---"
curl -sk -H "Authorization: Bearer $OUR_TOKEN" https://localhost:8444/api/storage/pools 2>/dev/null | python3 -c "
import sys,json
data = json.load(sys.stdin).get('data',[])
for p in (data if isinstance(data, list) else []):
  print(f'  {p.get(\"name\")}: type={p.get(\"type\")}, status={p.get(\"status\")}, total={p.get(\"total\")}GB')
" 2>/dev/null

echo ""
echo "Real virsh pools:"
virsh pool-list --all 2>&1
virsh pool-info default 2>&1 || true

echo ""
echo "========================================="
echo "  Comparison Complete"
echo "========================================="
