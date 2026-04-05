#!/bin/bash
# Find correct URLs for missing features by probing alternative paths
COOKIE=/tmp/mc_404_ck.txt
BASE="https://localhost:8443/mc"

# Test alternative URLs for the 404 pages
URLS="
servers/list
servers/listServer
servers/hostList
host/listHost
host/index
storage/index
storage/storageList
storageNew/list
storageNew/index
backup/index
backup/backupList
backup/listBackup
snapshot/list
snapshot/index
snapshot/policyList
VM/sessions
VM/listSessions
VM/sessionList
monitoring/sessions
generalSettings/passwordState
generalSettings/passwordPolicy
user/showPasswordPolicy
app/accessPolicys
visitPolicy/visitPolicys
visitPolicy/list
generalSettings/accessPolicy
serverVirtualization/appHA
serverVirtualization/autoScaling
serverVirtualization/backup
serverVirtualization/loadBalance
serverVirtualization/highSetting
serverVirtualization/zombieCloudServer
serverVirtualization/serverCloudStartOrder
app/admin
app/adminManage
user/listRoles
app/alert
monitoring/alarmEvents
app/event
monitoring/serverEvents
generalSettings/haConfig
generalSettings/showHA
app/license
generalSettings/showLicense
app/maintenanceTool
generalSettings/maintenance
app/password
user/showPasswordPolicy
app/recycle
recycleBin/index
serverRecycle/index
app/role
user/listRoles
app/smtp
generalSettings/mailServerList
app/system
generalSettings/showGlobalPolicy
virtualSwitch/index
network/list
network/virtualSwitch
"

for URL in $URLS; do
    HTTP_CODE=$(curl -sk -b $COOKIE -o /dev/null -w "%{http_code}" "$BASE/$URL" 2>/dev/null)
    if [ "$HTTP_CODE" = "200" ]; then
        SIZE=$(curl -sk -b $COOKIE -o /tmp/mc_alt.html "$BASE/$URL" 2>/dev/null && wc -c < /tmp/mc_alt.html)
        TITLE=$(grep -oP '<title>\K[^<]+' /tmp/mc_alt.html 2>/dev/null | head -1)
        printf "OK  | %s | %6s bytes | /mc/%-50s | %s\n" "$HTTP_CODE" "$SIZE" "$URL" "$TITLE"
    fi
done
