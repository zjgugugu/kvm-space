#!/bin/bash
# Fetch missing pages with correct URLs
COOKIE=/tmp/mc_404_ck.txt
BASE="https://localhost:8443/mc"
OUTDIR="/tmp/mc_refetch"
mkdir -p $OUTDIR

# Correct URL mappings discovered from the left-nav
# Original 404 -> Correct URL
declare -A URL_MAP
URL_MAP["app_accessPolicy"]="visitPolicy/visitPolicys"
URL_MAP["app_adminList"]="user/list"
URL_MAP["app_alertList"]="monitoringNew/monitoringNew" 
URL_MAP["app_eventList"]="monitoringNew/monitoringNew"
URL_MAP["app_haConfig"]="generalSettings/showHA"
URL_MAP["app_licenseSetting"]="generalSettings/showLicense"
URL_MAP["app_maintenance"]="app/oneClickDetection"
URL_MAP["app_passwordPolicy"]="user/showPasswordPolicy"
URL_MAP["app_recycleBin"]="recycleBin/index"
URL_MAP["app_roleSetting"]="user/listRoles"
URL_MAP["app_smtpConfig"]="generalSettings/mailServerList"
URL_MAP["app_systemConfig"]="generalSettings/showGlobalPolicy"
URL_MAP["backup_list"]="VM/backups"
URL_MAP["host_list"]="servers/clusterMasters"
URL_MAP["storage_list"]="storageNew/storageNew"
URL_MAP["snapshot_policyList"]="VM/snapStrategy"
URL_MAP["VM_sessions"]="monitoring/sessions"
URL_MAP["virtualSwitch_list"]="network/list"
URL_MAP["generalSettings_showPasswordState"]="user/showPasswordPolicy"
# serverVirtualization sub-pages with correct URLs
URL_MAP["serverVirtualization_appHA_index"]="serverVirtualization/index"
URL_MAP["serverVirtualization_autoScaling"]="serverAutoScaling/listAutoScalingGroupPage"
URL_MAP["serverVirtualization_backup_highSetting"]="serverVMBackup/highSetting"
URL_MAP["serverVirtualization_loadBalance"]="loadBalance/index"
URL_MAP["serverVirtualization_serverCloudStartOrder"]="serverCloudStartOrder/index"
URL_MAP["serverVirtualization_zombieCloudServer"]="zombieCloudServer/index"

# New pages discovered in system management
URL_MAP["generalSettings_affinityGroup"]="generalSettings/affinityGroup"
URL_MAP["generalSettings_labelSettings"]="generalSettings/labelSettings"
URL_MAP["user_list"]="user/list"
URL_MAP["organization_list"]="organization/list"
URL_MAP["serverAutoScaling_strategy"]="serverAutoScaling/listAutoScalingStrategyPage"

for KEY in "${!URL_MAP[@]}"; do
    URL="${URL_MAP[$KEY]}"
    OUTFILE="$OUTDIR/${KEY}.html"
    HTTP_CODE=$(curl -sk -b $COOKIE -o "$OUTFILE" -w "%{http_code}" "$BASE/$URL" 2>/dev/null)
    SIZE=$(wc -c < "$OUTFILE" 2>/dev/null || echo 0)
    TITLE=$(grep -oP '<title>\K[^<]+' "$OUTFILE" 2>/dev/null | head -1)
    printf "%-45s | %s | %7s bytes | %s\n" "$KEY" "$HTTP_CODE" "$SIZE" "$TITLE"
done

echo ""
echo "Files saved to $OUTDIR"
ls -la $OUTDIR/*.html | wc -l
