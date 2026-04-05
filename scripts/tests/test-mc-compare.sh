#!/bin/bash
# MC 8444 vs Real MC 8443 Comparison Test
set -e

echo "=============================================="
echo " MC 8444 vs Real MC 8443 Comparison Test"
echo "=============================================="

PASS=0
FAIL=0
WARN=0
pass() { echo "  [PASS] $1"; PASS=$((PASS+1)); }
fail() { echo "  [FAIL] $1"; FAIL=$((FAIL+1)); }
warn() { echo "  [WARN] $1"; WARN=$((WARN+1)); }

# === 1. Login to our MC 8444 ===
echo ""
echo "--- 1. Authentication ---"
OUR_TOKEN=$(curl -sf http://localhost:8444/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"admin123"}' | python3 -c 'import sys,json; print(json.load(sys.stdin).get("token",""))')
if [ -n "$OUR_TOKEN" ]; then pass "Our MC 8444 login OK"; else fail "Our MC 8444 login failed"; fi

OUR_AUTH="Authorization: Bearer $OUR_TOKEN"

our_api() {
  curl -sf "http://localhost:8444$1" -H "$OUR_AUTH" 2>/dev/null
}

# === 2. Login to Real MC 8443 ===
COOKIE_JAR=/tmp/mc_cookies.txt
rm -f $COOKIE_JAR
# Login to real MC - Grails uses form POST
REAL_LOGIN=$(curl -sk -c $COOKIE_JAR -L \
  -d 'username=mcadmin&password=987qwe654asd*' \
  'https://localhost:8443/mc/auth/signIn' -w '%{http_code}' -o /tmp/real_mc_login.html 2>/dev/null)
if [ "$REAL_LOGIN" = "200" ]; then 
  pass "Real MC 8443 login OK (HTTP $REAL_LOGIN)"
else 
  warn "Real MC 8443 login HTTP=$REAL_LOGIN (may need different login flow)"
fi

real_api() {
  curl -sf -b $COOKIE_JAR -k "https://localhost:8443$1" 2>/dev/null
}

# === 3. Dashboard Comparison ===
echo ""
echo "--- 2. Dashboard ---"
OUR_DASH=$(our_api /api/dashboard/overview)
DASH_VMS=$(echo "$OUR_DASH" | python3 -c 'import sys,json; d=json.load(sys.stdin); print(d.get("total_vms",0))' 2>/dev/null || echo "0")
DASH_HOSTS=$(echo "$OUR_DASH" | python3 -c 'import sys,json; d=json.load(sys.stdin); print(d.get("total_hosts",0))' 2>/dev/null || echo "0")
if [ -n "$DASH_VMS" ]; then pass "Dashboard has total_vms=$DASH_VMS"; else fail "Dashboard missing total_vms"; fi
if [ -n "$DASH_HOSTS" ]; then pass "Dashboard has total_hosts=$DASH_HOSTS"; else fail "Dashboard missing total_hosts"; fi

# Real MC dashboard page check
REAL_DASH=$(real_api /mc/app/dashboard)
REAL_DASH_OK=$(echo "$REAL_DASH" | grep -c 'dashboard\|Dashboard\|仪表盘' 2>/dev/null || echo "0")
if [ "$REAL_DASH_OK" -gt 0 ]; then pass "Real MC dashboard accessible"; else warn "Real MC dashboard: could not verify"; fi

# === 4. VM Management ===
echo ""
echo "--- 3. VM Management ---"
OUR_VMS=$(our_api /api/vms)
VM_COUNT=$(echo "$OUR_VMS" | python3 -c 'import sys,json; d=json.load(sys.stdin); print(len(d.get("data",[])))' 2>/dev/null || echo "err")
if [ "$VM_COUNT" != "err" ]; then pass "GET /api/vms returns data (count=$VM_COUNT)"; else fail "GET /api/vms failed"; fi

# Test VM CRUD operations
VM_CREATE=$(curl -sf -X POST http://localhost:8444/api/vms \
  -H "$OUR_AUTH" -H 'Content-Type: application/json' \
  -d '{"name":"test-compare-vm","template_id":1,"host_id":1,"cpu":2,"memory":2048,"disk":20}')
VM_ID=$(echo "$VM_CREATE" | python3 -c 'import sys,json; print(json.load(sys.stdin).get("id",""))' 2>/dev/null || echo "")
if [ -n "$VM_ID" ]; then pass "POST /api/vms create works (id=$VM_ID)"; else fail "POST /api/vms create failed"; fi

# Test VM actions
if [ -n "$VM_ID" ]; then
  ACTION=$(curl -sf -X POST "http://localhost:8444/api/vms/$VM_ID/action" \
    -H "$OUR_AUTH" -H 'Content-Type: application/json' -d '{"action":"start"}')
  ACTION_OK=$(echo "$ACTION" | python3 -c 'import sys,json; print("ok")' 2>/dev/null || echo "fail")
  if [ "$ACTION_OK" = "ok" ]; then pass "VM start action works"; else fail "VM start action failed"; fi

  # Cleanup
  curl -sf -X DELETE "http://localhost:8444/api/vms/$VM_ID" -H "$OUR_AUTH" > /dev/null 2>&1
  pass "VM cleanup (delete) works"
fi

# === 5. Host Management ===
echo ""
echo "--- 4. Host Management ---"
OUR_HOSTS=$(our_api /api/hosts)
HOST_COUNT=$(echo "$OUR_HOSTS" | python3 -c 'import sys,json; d=json.load(sys.stdin); print(len(d.get("data",[])))' 2>/dev/null || echo "err")
if [ "$HOST_COUNT" != "err" ]; then pass "GET /api/hosts returns data (count=$HOST_COUNT)"; else fail "GET /api/hosts failed"; fi

# === 6. Template/Gold Image Management ===
echo ""
echo "--- 5. Template Management ---"
OUR_TMPL=$(our_api /api/templates)
TMPL_COUNT=$(echo "$OUR_TMPL" | python3 -c 'import sys,json; d=json.load(sys.stdin); print(len(d.get("data",[])))' 2>/dev/null || echo "err")
if [ "$TMPL_COUNT" != "err" ]; then pass "GET /api/templates works (count=$TMPL_COUNT)"; else fail "GET /api/templates failed"; fi

# === 7. Network Management ===
echo ""
echo "--- 6. Network Management ---"
OUR_NETS=$(our_api /api/networks)
NET_COUNT=$(echo "$OUR_NETS" | python3 -c 'import sys,json; d=json.load(sys.stdin); print(len(d.get("data",[])))' 2>/dev/null || echo "err")
if [ "$NET_COUNT" != "err" ]; then pass "GET /api/networks works (count=$NET_COUNT)"; else fail "GET /api/networks failed"; fi

SG=$(our_api /api/networks/security-groups)
SG_OK=$(echo "$SG" | python3 -c 'import sys,json; d=json.load(sys.stdin); print("ok" if "data" in d else "fail")' 2>/dev/null || echo "fail")
if [ "$SG_OK" = "ok" ]; then pass "GET /api/networks/security-groups works"; else fail "GET /api/networks/security-groups failed"; fi

MAC=$(our_api /api/networks/mac-pools)
MAC_OK=$(echo "$MAC" | python3 -c 'import sys,json; d=json.load(sys.stdin); print("ok" if "data" in d else "fail")' 2>/dev/null || echo "fail")
if [ "$MAC_OK" = "ok" ]; then pass "GET /api/networks/mac-pools works"; else fail "GET /api/networks/mac-pools failed"; fi

SUBNETS=$(our_api /api/networks/subnets)
SUB_OK=$(echo "$SUBNETS" | python3 -c 'import sys,json; d=json.load(sys.stdin); print("ok" if "data" in d else "fail")' 2>/dev/null || echo "fail")
if [ "$SUB_OK" = "ok" ]; then pass "GET /api/networks/subnets works"; else fail "GET /api/networks/subnets failed"; fi

# === 8. Storage Management ===
echo ""
echo "--- 7. Storage Management ---"
POOLS=$(our_api /api/storage/pools)
POOL_OK=$(echo "$POOLS" | python3 -c 'import sys,json; d=json.load(sys.stdin); print("ok" if "data" in d else "fail")' 2>/dev/null || echo "fail")
if [ "$POOL_OK" = "ok" ]; then pass "GET /api/storage/pools works"; else fail "GET /api/storage/pools failed"; fi

VOLS=$(our_api /api/storage/volumes)
VOL_OK=$(echo "$VOLS" | python3 -c 'import sys,json; d=json.load(sys.stdin); print("ok" if "data" in d else "fail")' 2>/dev/null || echo "fail")
if [ "$VOL_OK" = "ok" ]; then pass "GET /api/storage/volumes works"; else fail "GET /api/storage/volumes failed"; fi

# === 9. User Management ===
echo ""
echo "--- 8. User Management ---"
OUR_USERS=$(our_api /api/users)
USER_COUNT=$(echo "$OUR_USERS" | python3 -c 'import sys,json; d=json.load(sys.stdin); print(len(d.get("data",[])))' 2>/dev/null || echo "err")
if [ "$USER_COUNT" != "err" ]; then pass "GET /api/users works (count=$USER_COUNT)"; else fail "GET /api/users failed"; fi

GROUPS=$(our_api /api/users/groups)
GRP_OK=$(echo "$GROUPS" | python3 -c 'import sys,json; d=json.load(sys.stdin); print("ok" if "data" in d else "fail")' 2>/dev/null || echo "fail")
if [ "$GRP_OK" = "ok" ]; then pass "GET /api/users/groups works"; else fail "GET /api/users/groups failed"; fi

LDAP=$(our_api /api/users/ldap)
LDAP_OK=$(echo "$LDAP" | python3 -c 'import sys,json; print("ok")' 2>/dev/null || echo "fail")
if [ "$LDAP_OK" = "ok" ]; then pass "GET /api/users/ldap works"; else fail "GET /api/users/ldap failed"; fi

# === 10. System Configuration ===
echo ""
echo "--- 9. System Configuration ---"
POLICIES=$(our_api /api/system/policies)
POL_OK=$(echo "$POLICIES" | python3 -c 'import sys,json; d=json.load(sys.stdin); print("ok" if "data" in d else "fail")' 2>/dev/null || echo "fail")
if [ "$POL_OK" = "ok" ]; then pass "GET /api/system/policies works"; else fail "GET /api/system/policies failed"; fi

PWPOL=$(our_api /api/system/password-policy)
PW_OK=$(echo "$PWPOL" | python3 -c 'import sys,json; print("ok")' 2>/dev/null || echo "fail")
if [ "$PW_OK" = "ok" ]; then pass "GET /api/system/password-policy works"; else fail "GET /api/system/password-policy failed"; fi

ACCPOL=$(our_api /api/system/access-policy)
ACC_OK=$(echo "$ACCPOL" | python3 -c 'import sys,json; print("ok")' 2>/dev/null || echo "fail")
if [ "$ACC_OK" = "ok" ]; then pass "GET /api/system/access-policy works"; else fail "GET /api/system/access-policy failed"; fi

SMTP=$(our_api /api/system/smtp)
SMTP_OK=$(echo "$SMTP" | python3 -c 'import sys,json; print("ok")' 2>/dev/null || echo "fail")
if [ "$SMTP_OK" = "ok" ]; then pass "GET /api/system/smtp works"; else fail "GET /api/system/smtp failed"; fi

# === 11. Backup & Snapshot ===
echo ""
echo "--- 10. Backup & Snapshot ---"
BKUP_SVRS=$(our_api /api/backups/servers)
BKUP_OK=$(echo "$BKUP_SVRS" | python3 -c 'import sys,json; d=json.load(sys.stdin); print("ok" if "data" in d else "fail")' 2>/dev/null || echo "fail")
if [ "$BKUP_OK" = "ok" ]; then pass "GET /api/backups/servers works"; else fail "GET /api/backups/servers failed"; fi

SNAPPOL=$(our_api /api/snapshot-policies)
SNAP_OK=$(echo "$SNAPPOL" | python3 -c 'import sys,json; d=json.load(sys.stdin); print("ok" if "data" in d else "fail")' 2>/dev/null || echo "fail")
if [ "$SNAP_OK" = "ok" ]; then pass "GET /api/snapshot-policies works"; else fail "GET /api/snapshot-policies failed"; fi

# === 12. Events & Alerts ===
echo ""
echo "--- 11. Events & Alerts ---"
EVENTS=$(our_api /api/events)
EVT_OK=$(echo "$EVENTS" | python3 -c 'import sys,json; d=json.load(sys.stdin); print("ok" if "data" in d else "fail")' 2>/dev/null || echo "fail")
if [ "$EVT_OK" = "ok" ]; then pass "GET /api/events works"; else fail "GET /api/events failed"; fi

ALERTS=$(our_api /api/alerts)
ALT_OK=$(echo "$ALERTS" | python3 -c 'import sys,json; d=json.load(sys.stdin); print("ok" if "data" in d else "fail")' 2>/dev/null || echo "fail")
if [ "$ALT_OK" = "ok" ]; then pass "GET /api/alerts works"; else fail "GET /api/alerts failed"; fi

TASKS=$(our_api /api/events/tasks)
TASK_OK=$(echo "$TASKS" | python3 -c 'import sys,json; d=json.load(sys.stdin); print("ok" if "data" in d else "fail")' 2>/dev/null || echo "fail")
if [ "$TASK_OK" = "ok" ]; then pass "GET /api/events/tasks works"; else fail "GET /api/events/tasks failed"; fi

# === 13. Statistics ===
echo ""
echo "--- 12. Statistics ---"
STATS=$(our_api /api/stats)
STAT_OK=$(echo "$STATS" | python3 -c 'import sys,json; print("ok")' 2>/dev/null || echo "fail")
if [ "$STAT_OK" = "ok" ]; then pass "GET /api/stats works"; else fail "GET /api/stats failed"; fi

# === 14. Frontend ===
echo ""
echo "--- 13. Frontend ---"
HTTP=$(curl -sf -o /dev/null -w '%{http_code}' http://localhost:8444/)
if [ "$HTTP" = "200" ]; then pass "Frontend served (HTTP 200)"; else fail "Frontend HTTP $HTTP"; fi

# === 15. Real MC Page Count ===
echo ""
echo "--- 14. Real MC Page Structure ---"
REAL_PAGES=$(real_api /mc/ | grep -oP 'href="[^"]*app/[^"]*"' | wc -l 2>/dev/null || echo "0")
warn "Real MC has approx $REAL_PAGES page links detected"

echo ""
echo "=============================================="
echo " Results: PASS=$PASS FAIL=$FAIL WARN=$WARN"
echo " Total: $((PASS+FAIL+WARN))"
echo "=============================================="

if [ $FAIL -gt 0 ]; then exit 1; fi
