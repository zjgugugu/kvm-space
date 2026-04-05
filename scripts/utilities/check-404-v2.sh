#!/bin/bash
# Check 404 MC pages on real server
COOKIE=/tmp/mc_404_ck.txt
BASE="https://localhost:8443/mc"
rm -f $COOKIE

encrypt() {
    local KEY_HEX=$(echo -n 'ksvdqwerty147258' | xxd -p)
    local IV_HEX=$(echo -n 'ksvdqwerty147258' | xxd -p)
    echo -n "$1" | openssl enc -aes-128-cbc -K $KEY_HEX -iv $IV_HEX -base64 2>/dev/null | tr -d '\n'
}

EU=$(encrypt "mcadmin")
EP=$(encrypt '987qwe654asd*')

# Login
curl -sk -c $COOKIE "$BASE/" > /dev/null 2>&1
LR=$(curl -sk -b $COOKIE -c $COOKIE --data-urlencode "username=$EU" --data-urlencode "password=$EP" -H "X-Requested-With: XMLHttpRequest" "$BASE/user/loginCheck" 2>/dev/null)
FLAG=$(echo "$LR" | grep -oP '"flag"\s*:\s*\K[0-9]+')
echo "loginCheck flag=$FLAG"

SR=$(curl -sk -b $COOKIE -c $COOKIE -d "flag=$FLAG&username=mcadmin" -H "X-Requested-With: XMLHttpRequest" "$BASE/user/successSession" 2>/dev/null)
ORG_ID=$(echo "$SR" | grep -oP '"orgId"\s*:\s*"\K[^"]*')
[ -z "$ORG_ID" ] && ORG_ID=$(echo "$SR" | grep -oP '"orgId"\s*:\s*\K[0-9]+')
echo "orgId=$ORG_ID"

if [ -n "$ORG_ID" ]; then
    curl -sk -b $COOKIE -c $COOKIE -d "orgId=$ORG_ID" -H "X-Requested-With: XMLHttpRequest" "$BASE/user/setOrgUser" > /dev/null 2>&1
fi

# Quick auth test
AUTH_TEST=$(curl -sk -b $COOKIE -w "%{http_code}" -o /dev/null "$BASE/reporting/dashboard")
echo "Auth test (dashboard): HTTP $AUTH_TEST"
echo ""

# Test 404 URLs  
URLS="
app/accessPolicy
app/adminList
app/alertList
app/eventList
app/haConfig
app/licenseSetting
app/maintenance
app/passwordPolicy
app/recycleBin
app/roleSetting
app/smtpConfig
app/systemConfig
backup/list
generalSettings/showPasswordState
host/list
serverVirtualization/appHA/index
serverVirtualization/autoScaling/listAutoScalingGroup
serverVirtualization/backup/highSetting
serverVirtualization/loadBalance/index
serverVirtualization/serverCloudStartOrder/index
serverVirtualization/zombieCloudServer/index
snapshot/policyList
storage/list
virtualSwitch/list
VM/sessions
"

for URL in $URLS; do
    HTTP_CODE=$(curl -sk -b $COOKIE -o /tmp/mc_page_tmp.html -w "%{http_code}" "$BASE/$URL" 2>/dev/null)
    SIZE=$(wc -c < /tmp/mc_page_tmp.html 2>/dev/null || echo 0)
    
    HAS_404=$(grep -c "HTTP Status 404" /tmp/mc_page_tmp.html 2>/dev/null || echo 0)
    TITLE=$(grep -oP '<title>\K[^<]+' /tmp/mc_page_tmp.html 2>/dev/null | head -1)
    
    if [ "$HAS_404" -gt 0 ]; then
        STATUS="REAL_404"
    elif echo "$TITLE" | grep -q "Error\|错误" 2>/dev/null; then
        STATUS="ERROR"
    elif [ "$HTTP_CODE" = "200" ] && [ "$SIZE" -gt 1000 ]; then
        STATUS="OK_PAGE"
    elif [ "$HTTP_CODE" = "200" ]; then
        STATUS="OK_SMALL"
    elif [ "$HTTP_CODE" = "302" ]; then
        STATUS="REDIRECT"
    else
        STATUS="HTTP_$HTTP_CODE"
    fi
    
    printf "%-12s | %s | %6s bytes | %-55s | %s\n" "$STATUS" "$HTTP_CODE" "$SIZE" "/mc/$URL" "$TITLE"
done
