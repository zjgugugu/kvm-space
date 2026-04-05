#!/bin/bash
# Focus on the truly missing pages - try more URL patterns
COOKIE=/tmp/mc_404_ck.txt
BASE="https://localhost:8443/mc"

URLS="
servers/listServerDetail
servers/showServer
servers/showServerDetail
servers/showPhysicalMachine
servers/hostManagement
servers/physicalMachine
servers/physicalMachineList
host/hostManagement
host/physicalMachine
host/serverList
host/index
host/physicalMachineList
storage/index
storage/show
storage/showStorage
storage/storagePool
storage/storagePoolList
storage/storageManagement
storageNew/list
storageNew/index
storageNew/storagePool
storageNew/storagePoolList
storageNew/storageNewList
storageNew/dataStore
storage/dataStore
storage/dataStoreList
backup/index
backup/show
backup/management
backup/backupTask
backup/backupPlan
backup/backupServerList
backup/serverList
backup/backupManagement
serverVirtualization/list
serverVirtualization/cloudServerList
serverVirtualization/show
serverVirtualization/appHA/list
serverVirtualization/autoScaling/list
serverVirtualization/backup/list
serverVirtualization/backup/index
serverVirtualization/backup/backupIndex
serverVirtualization/loadBalance/list
serverVirtualization/zombieCloudServer/list
serverVirtualization/serverCloudStartOrder/list
snapshot/list
snapshot/index
snapshot/strategy
snapshot/policyList
snapshot/snapStrategy
VM/snapStrategy
VM/snapshotList
virtualSwitch/index
virtualSwitch/list
virtualSwitch/virtualSwitchList
app/accessPolicyList
app/accessPolicys
generalSettings/accessPolicy
generalSettings/showPasswordState
generalSettings/passwordState
app/maintenance
app/maintenanceTool
maintenance/index
maintenance/list
maintenance/show
generalSettings/maintenance
generalSettings/maintenanceTool
app/admin
app/administrators
app/adminManage
generalSettings/listAdmin
generalSettings/adminList
app/alert
app/alertManage
app/alertSetting
generalSettings/alertList
monitoring/alertList
app/event
app/eventManage
monitoring/eventList
"

for URL in $URLS; do
    HTTP_CODE=$(curl -sk -b $COOKIE -o /dev/null -w "%{http_code}" "$BASE/$URL" 2>/dev/null)
    if [ "$HTTP_CODE" = "200" ]; then
        SIZE=$(curl -sk -b $COOKIE -o /tmp/mc_alt2.html "$BASE/$URL" 2>/dev/null && wc -c < /tmp/mc_alt2.html)
        TITLE=$(grep -oP '<title>\K[^<]+' /tmp/mc_alt2.html 2>/dev/null | head -1)
        printf "OK  | %s | %6s bytes | /mc/%-55s | %s\n" "$HTTP_CODE" "$SIZE" "$URL" "$TITLE"
    fi
done

echo ""
echo "=== Also try serverVirtualization tabs ==="
# Check what the server virtualization page actually links to
curl -sk -b $COOKIE "$BASE/serverVirtualization/index" 2>/dev/null | grep -oP 'href="[^"]*serverVirtual[^"]*"' | sort -u
echo ""
echo "=== Storage page links ==="
curl -sk -b $COOKIE "$BASE/storageNew/storageNew" 2>/dev/null | grep -oP 'href="[^"]*storage[^"]*"' | sort -u
echo ""
echo "=== Servers page links ==="
curl -sk -b $COOKIE "$BASE/servers/clusterMasters" 2>/dev/null | grep -oP 'href="[^"]*servers[^"]*"' | sort -u
echo ""
echo "=== Backup page links ==="
curl -sk -b $COOKIE "$BASE/backup/backupServer" 2>/dev/null | grep -oP 'href="[^"]*backup[^"]*"' | sort -u
