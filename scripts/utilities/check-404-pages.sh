#!/bin/bash
# Check all 404 MC pages - are they real 404s or just need auth/data?

COOKIE_FILE="/tmp/mc_404_check.txt"
BASE="https://localhost:8443/mc"
rm -f $COOKIE_FILE

# AES encryption
encrypt() {
    local KEY_HEX=$(echo -n 'ksvdqwerty147258' | xxd -p)
    local IV_HEX=$(echo -n 'ksvdqwerty147258' | xxd -p)
    echo -n "$1" | openssl enc -aes-128-cbc -K $KEY_HEX -iv $IV_HEX -base64 2>/dev/null | tr -d '\n'
}

# Login
ENC_USER=$(encrypt "mcadmin")
ENC_PASS=$(encrypt '987qwe654asd*')

curl -sk -c $COOKIE_FILE "$BASE/" > /dev/null 2>&1

LOGIN_RESP=$(curl -sk -b $COOKIE_FILE -c $COOKIE_FILE \
    --data-urlencode "username=$ENC_USER" \
    --data-urlencode "password=$ENC_PASS" \
    -H "X-Requested-With: XMLHttpRequest" \
    "$BASE/user/loginCheck" 2>/dev/null)
FLAG=$(echo "$LOGIN_RESP" | grep -oP '"flag"\s*:\s*\K[0-9]+')

SS_RESP=$(curl -sk -b $COOKIE_FILE -c $COOKIE_FILE \
    -d "flag=$FLAG&username=mcadmin" \
    -H "X-Requested-With: XMLHttpRequest" \
    "$BASE/user/successSession" 2>/dev/null)

ORG_ID=$(echo "$SS_RESP" | grep -oP '"orgId"\s*:\s*"\K[^"]*')
if [ -z "$ORG_ID" ]; then
    ORG_ID=$(echo "$SS_RESP" | grep -oP '"orgId"\s*:\s*\K[0-9]+')
fi

if [ -n "$ORG_ID" ]; then
    curl -sk -b $COOKIE_FILE -c $COOKIE_FILE \
        -d "orgId=$ORG_ID" \
        -H "X-Requested-With: XMLHttpRequest" \
        "$BASE/user/setOrgUser" > /dev/null 2>&1
fi

echo "Login: flag=$FLAG, orgId=$ORG_ID"
echo ""

# Test each 404 URL
URLS=(
    "/mc/app/accessPolicy"
    "/mc/app/adminList" 
    "/mc/app/alertList"
    "/mc/app/eventList"
    "/mc/app/haConfig"
    "/mc/app/licenseSetting"
    "/mc/app/maintenance"
    "/mc/app/passwordPolicy"
    "/mc/app/recycleBin"
    "/mc/app/roleSetting"
    "/mc/app/smtpConfig"
    "/mc/app/systemConfig"
    "/mc/backup/list"
    "/mc/generalSettings/showPasswordState"
    "/mc/host/list"
    "/mc/serverVirtualization/appHA/index"
    "/mc/serverVirtualization/autoScaling/listAutoScalingGroup"
    "/mc/serverVirtualization/backup/highSetting"
    "/mc/serverVirtualization/loadBalance/index"
    "/mc/serverVirtualization/serverCloudStartOrder/index"
    "/mc/serverVirtualization/zombieCloudServer/index"
    "/mc/snapshot/policyList"
    "/mc/storage/list"
    "/mc/virtualSwitch/list"
    "/mc/VM/sessions"
)

for URL in "${URLS[@]}"; do
    HTTP_CODE=$(curl -sk -b $COOKIE_FILE -o /dev/null -w "%{http_code}" "$BASE/../..$URL")
    CONTENT_SIZE=$(curl -sk -b $COOKIE_FILE -w "%{size_download}" -o /tmp/mc_page_check.html "$BASE/../..$URL" 2>/dev/null | tail -1)
    
    # Check if it's a redirect (302), real 404, or success with content
    HAS_404=$(grep -c "HTTP Status 404" /tmp/mc_page_check.html 2>/dev/null || echo 0)
    HAS_TITLE=$(grep -oP '<title>(.*?)</title>' /tmp/mc_page_check.html 2>/dev/null | head -1)
    
    if [ "$HAS_404" -gt 0 ]; then
        STATUS="REAL_404"
    elif [ "$HTTP_CODE" = "302" ]; then
        STATUS="REDIRECT"
    elif [ "$HTTP_CODE" = "200" ]; then
        STATUS="OK"
    else
        STATUS="HTTP_$HTTP_CODE"
    fi
    
    echo "$STATUS | $HTTP_CODE | Size:$CONTENT_SIZE | $URL | $HAS_TITLE"
done
