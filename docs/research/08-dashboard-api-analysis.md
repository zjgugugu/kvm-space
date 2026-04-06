# MC Dashboard API - Real System Analysis

## Real MC Dashboard Endpoints (from real system at 8443)

The dashboard page (monitoring/dashboard) uses RequireJS modules that each fetch from separate AJAX endpoints.

### 1. VM Pie Chart: `chartQuery/getPieChart?type=vm`
**Response:**
```json
{"displayName":"vm","data":{"connected":0,"disConnected":1,"total":14,"isRunning":1,"unRun":0,"servertotal":1}}
```
- `connected` = Desktop VMs with active user sessions
- `disConnected` = Desktop VMs running but without active sessions
- `total` = Desktop VMs not in session (idle/stopped)
- `isRunning` = Running server VMs
- `unRun` = Stopped server VMs
- `servertotal` = Total server VMs

### 2. Server VM Pie Chart: `chartQuery/getPieChart?type=serverVm`
**Response:**
```json
{"displayName":"serverVm","data":{}}
```
(Empty in test environment - only populated in server virtualization mode)

### 3. CPU Utilization: `chartQuery/getPieChart?type=cpu`
**Response:**
```json
{"displayName":"cpu","data":{"used":0.054599997,"total":2.6}}
```
- `used` = CPU usage (GHz)
- `total` = Total CPU capacity (GHz)

### 4. Memory Utilization: `chartQuery/getPieChart?type=mem`
**Response:**
```json
{"displayName":"mem","data":{"used":43.95215,"total":255.38574}}
```
- `used` / `total` in GB

### 5. Storage Utilization: `chartQuery/getPieChart?type=storage`
**Response:**
```json
{"displayName":"storage","data":{
  "used":184,"total":7959,
  "storageList":[{
    "class":"com.hnkylin.mc.storage.NewDataStore","id":1,
    "name":"MStorage","state":"online",
    "totalSize":808.7,"usedSize":8.6,
    "type":{"enumType":"...","name":"DISTRIBUTED"},
    "usage":{"enumType":"...","name":"MANAGE"},
    "status":{"enumType":"...","name":"NORMAL"},
    "relatedMahine":1,"relatedVM":0,"relatedVS":0,
    "runningMachine":1,"runningVM":0,"runningVS":0,
    "arbiter":false,"brickCnt":"1","cacheSize":0,"createStatus":0
  },{
    "id":2,"name":"data","state":"online",
    "totalSize":7151.8,"usedSize":176.2,
    "type":{"name":"DISTRIBUTED"},"usage":{"name":"DATA"},"status":{"name":"NORMAL"},
    "relatedMahine":1,"relatedVM":15,"relatedVS":1,
    "runningMachine":1,"runningVM":1,"runningVS":1,
    "arbiter":false,"brickCnt":"2"
  }]
}}
```

### 6. Server Stats: `chartQuery/getPieChart?type=server`
**Response:**
```json
{"displayName":"server","data":{"online":1,"offline":0}}
```

### 7. Trend Chart: `chartQuery/getChart?id=<uuid>&granularity=HOUR&numDataPoints=12`
**Response:**
```json
{
  "chart":{
    "lines":[
      {"lineQuery":{"dataType":{"name":"CONNECTED_SESSION_COUNT"},"computationType":{"name":"CLUSTER_TOTAL"},"sampleType":{"name":"PEAK"}},"values":[[timestamp,value],...]},
      {"lineQuery":{"dataType":{"name":"ONLINE_USER_COUNT"},  ...},"values":[...]},
      {"lineQuery":{"dataType":{"name":"SESSION_COUNT"},      ...},"values":[...]},
      {"lineQuery":{"dataType":{"name":"ONLINE_CLINET_COUNT"},...},"values":[...]},
      {"lineQuery":{"dataType":{"name":"SERVER_VIRTUAL_SESSION_COUNT"},...},"values":[...]}
    ]
  },
  "displayName":"群集",
  "granularityMap":{"MINUTE":"分钟","HOUR":"小时","DAY":"日","WEEK":"周","MONTH":"月"},
  "dataTypeMap":{"SESSION_COUNT":"虚拟机数","ONLINE_USER_COUNT":"在线用户","ONLINE_CLINET_COUNT":"在线终端","CONNECTED_SESSION_COUNT":"会话数","SERVER_VIRTUAL_SESSION_COUNT":"..."}
}
```

### 8. Terminal Types: `statistics/getClientNumber`
**Response:**
```json
{"success":true,"data":{"normal":0.0,"vde":0.0,"tc":1.0}}
```
- `normal` = PC terminals
- `vde` = VDE thin clients
- `tc` = TC thin clients

### 9. User Online Stats: `statistics/getUserInfos`
**Response:**
```json
{"success":true,"data":{"totalUserNum":16,"onlineUserNum":0.0,"monthUserNum":1.0,"yearUserNum":2.0}}
```

### 10. User Online Ranking: `statistics/listUsageTimeInfoOnMonth?rows=20&page=1`
**Response:**
```json
{"total":1.0,"pager":1.0,"records":1.0,"rows":[{
  "id":1.0,"cell":{
    "desktopName":"golden_new","total":0.34,
    "user_name":"xunshi01","loginName":"xunshi01","username":"xunshi01"
  }
}],"timestamp":""}
```

### 11. Alerts: `monitoring/listAlarmEvents?rows=20&page=1&sidx=date&sord=desc`
**Response:**
```json
{"total":2,"pager":1,"records":32,"rows":[{
  "id":0,"cell":{
    "severity":"严重","date":"2026/04/04 10:59:32",
    "objectName":"10.126.33.238","type":"服务器IPMI事件告警",
    "objectType":"服务器","info":"System Boot Initiated #0x01,System Restart,Asserted,"
  }
},...]}
```

## Dashboard JS Modules (from real system)
Located at: `/usr/lib/ksvd/etc/apache-tomcat/webapps/mc/mc/dashboard/`
- `entry-require.js` - RequireJS entry, loads all modules
- `virtual-machine.js` - VM pie chart (desktop VMs: connected vs disconnected + server VMs)
- `server-virtual-machine.js` - Server VM pie (separate from desktop)
- `trend-map.js` - Online trend chart (5 line series)
- `system-type.js` - Terminal type bar chart
- `utilization-rate.js` - CPU/Mem/Storage 3 pie charts
- `server-statistics.js` - Server online/offline count
- `warn.js` - Alert table
- `user-online.js` - User online ranking table
- `user-online-statistics.js` - User online stats table

## Mapping: Real MC → Our Implementation
| Real MC Endpoint | Our Endpoint | Status |
|---|---|---|
| chartQuery/getPieChart?type=vm | /dashboard/overview → vm | ✅ working (desktop VMs) |
| chartQuery/getPieChart?type=server | /dashboard/overview → server | ✅ working |
| chartQuery/getPieChart?type=cpu | /dashboard/overview → cpu | ✅ working |
| chartQuery/getPieChart?type=mem | /dashboard/overview → mem | ✅ working |
| chartQuery/getPieChart?type=storage | /dashboard/overview → storage | ✅ working |
| statistics/getClientNumber | /dashboard/overview → systemType | ⚠️ hardcoded zeros → needs DB |
| chartQuery/getChart | /dashboard/trends | ✅ working (synthetic data) |
| statistics/getUserInfos | /dashboard/user-stats | ✅ working |
| statistics/listUsageTimeInfoOnMonth | /dashboard/user-ranking | ✅ working |
| monitoring/listAlarmEvents | /dashboard/recent-alerts | ✅ working |
| - | /dashboard/overview → vm.isRunning/unRun/servertotal | ⚠️ hardcoded zeros → needs vm_type |
