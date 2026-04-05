# MC管理控制台 (端口8443) 分析

## 访问信息
- **URL**: https://10.126.33.238:8443/mc/
- **账号**: mcadmin / 987qwe654asd*
- **技术栈**: Java + Grails + GSP模板 + jQuery + Bootstrap(Ace Admin) + Spring Security

## 登录页面分析

### 页面结构
- 标题: "管理控制台：登录"
- favicon: /mc/images/hnkylin/favicon.ico
- CSS框架: Bootstrap + Ace Admin + Font Awesome 4.5.0
- JS库: jQuery 3.5.1, jQuery UI 1.12.1, CryptoJS (AES加密)
- 键盘: jqkeyboard虚拟键盘

### 登录表单
```html
<form action="/mc/user/index" method="post" name="login" id="login">
  <input type="text" name="username" id="username" placeholder="用户名"/>
  <input type="password" name="password" id="password" placeholder="密码"/>
  <div id="verifycode_div" class="hidden">  <!-- 验证码(初始隐藏) -->
    <input type="text" maxlength="4" id="verifycode_input" placeholder="验证码"/>
  </div>
  <input type="checkbox" id="remember_me"/>  <!-- 记住密码 -->
  <input type="submit" name="_action_authenticate" value="登录"
         onclick="return KSVD.user.beformAuth(this);"/>
</form>
```

### 登录加密机制 (user.js)
- 函数: `KSVD.user.beformAuth(el)` (第924行)
- **密码加密**: 使用 `KSVD.encrypt()` 对用户名和密码进行AES加密后提交
- 提交方式: POST 到 `/mc/user/index?_action_authenticate`
- 加密后字段: `username=KSVD.encrypt(name)&password=KSVD.encrypt(pwd)`
- 还需要找到 `KSVD.encrypt()` 的具体实现（在 mc.js 中）

### 登录响应路由
- routeStr == 0: 登录成功，跳转目标URL
- routeStr == 1/11/12: 显示验证码
- routeStr == 2: 确认对话框（强制其他会话下线）
- routeStr == 3/6: 强制修改密码
- routeStr == 4/7: 提示修改密码（可跳过）
- routeStr == 5/8: 提示修改密码（可跳过直接登录）

### Cookie处理
- rmbUser: "true"/"false" - 是否记住密码
- username: btoa编码的用户名
- password: btoa编码的密码
- 使用 jquery.cookie.js 管理

## Webapp目录结构

### 顶级目录 (/usr/lib/ksvd/etc/apache-tomcat/webapps/mc/)
```
META-INF/
WEB-INF/
  cgi/
  classes/
  grails-app/views/     # GSP视图模板
  lib/
  plugins/
  spring/
  templates/
  tld/
appControl/
assets/jquery/
bootstrap-select-1.13.9/
css/
  ace/          # Ace Admin主题CSS
  fonts/
  gpl/
  hnkylin/       # 麒麟自定义CSS
  img/
  lib/
  mc/           # MC模块CSS
  upload/
files/
font-awesome/4.5.0/
images/
  hnkylin/       # 麒麟Logo等
  serverVirtualization/
js/
  ace/          # Ace Admin框架JS
  gpl/          # 开源JS库
  hnkylin/       # 麒麟自定义JS (mc.js, user.js, gVerify.js)
  jqkeyboard/    # 虚拟键盘
mc/              # MC模块前端
  auth/
  client/
  common/
  dashboard/
```

## GSP视图文件列表

### VM模块 (WEB-INF/grails-app/views/VM/)
- _batchSnapList.gsp, _listVuevm.gsp, _listvm.gsp, _ruleList.gsp, _snapList.gsp
- addBackup.gsp, addNic.gsp, backups.gsp
- batchApplySnapList.gsp, batchEditAdvanceConfig.gsp
- createSnapPolicy/ (listVirtual,reloadSnapManager,snapPolicyView,successSnapStrategy)
- csnapshotview.gsp, desktopVms.gsp
- editAdvanceConfig.gsp, editSession.gsp, editSessions.gsp
- editSnapPolicy/ (listVirtual,reloadSnapManager,snapPolicyView)
- index.gsp, managesnapshot/ (msnapshotview,showSnap)
- migrationConfig.gsp, monitoring.gsp
- restoreBackup.gsp, sessions.gsp
- showAdvanceConfig.gsp, showMigrationConfig.gsp
- showSession.gsp, showSessions.gsp, showSnap.gsp
- snapSettings.gsp, snapStrategy.gsp, snapshotList.gsp
- summary.gsp, tdetails.gsp, test.gsp, tmonitoring.gsp, tsummary.gsp

### 其他模块
- MACAddressPool/ (create,edit,list,show)
- app/ (about,approvalCenter,auditList,eventList等)
- auth/ (listAuthProviders)
- backup/ 
- client/
- host/
- image/
- layouts/ (主布局模板)
- monitoring/ (dashboard)
- network/ 
- policy/
- storage/
- user/
- virtualSwitch/

## KSVD.encrypt() 实现 (mc.js 第1092行)
```javascript
KSVD.encrypt = function (word) {
    let key = CryptoJS.enc.Utf8.parse('ksvdqwerty147258');
    let iv = CryptoJS.enc.Utf8.parse('ksvdqwerty147258');
    let src = CryptoJS.enc.Utf8.parse(word);
    var encrypted = CryptoJS.AES.encrypt(src, key, {
        iv: iv,
        mode: CryptoJS.mode.CBC,
        padding: CryptoJS.pad.Pkcs7
    });
    return CryptoJS.enc.Base64.stringify(encrypted.ciphertext);
}
```
- 算法: AES-128-CBC
- 密钥: ksvdqwerty147258 (16字节)
- IV: ksvdqwerty147258 (与密钥相同)
- 填充: PKCS7
- 输出: Base64

## 登录流程已验证 ✅
1. GET /mc/ → JSESSIONID cookie
2. POST /mc/user/loginCheck (AES加密的username+password) → {flag,msg,url}
3. POST /mc/user/successSession (flag, username明文) → {result,orgId}
4. POST /mc/user/setOrgUser (id=orgId) → {success}
5. 用JSESSIONID cookie访问任意页面

## 页面抓取完成 ✅
- 成功抓取96个有效页面(>2000字节)
- 所有页面HTML已保存到 docs/research/mc_pages/
- 详细URL映射见 07-mc-page-urls.md

## 待继续分析
- [ ] 分析管理控制台的主要页面结构和JS交互
- [ ] 提取所有AJAX API调用端点
- [ ] 分析Cockpit(9090)界面
