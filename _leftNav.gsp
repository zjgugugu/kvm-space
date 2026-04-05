<!--
 Copyright 2006-2017 Hunan Kylin, Inc.  All Rights Reserved.
 
 NOTICE: ALL INFORMATION CONTAINED HEREIN IS, AND REMAINS THE PROPERTY OF
 HUNAN KYLIN, INC. AND ITS SUPPLIERS, IF ANY. THE INTELLECTUAL AND
 TECHNICAL CONCEPTS CONTAINED HEREIN ARE PROPRIETARY TO HUNAN KYLIN, INC.
 AND ITS SUPPLIERS AND MAY BE COVERED BY U.S. AND FOREIGN PATENTS, PATENTS IN
 PROCESS, AND ARE PROTECTED BY TRADE SECRET OR COPYRIGHT LAW. DISSEMINATION
 OF THIS INFORMATION OR REPRODUCTION OF THIS MATERIAL IS STRICTLY FORBIDDEN
 UNLESS PRIOR WRITTEN PERMISSION IS OBTAINED FROM HUNAN KYLIN, INC.
-->
<%@ page import="com.hnkylin.mc.ksvd.UICustomize; com.hnkylin.mc.user.Permission" %>
<%@ page import="com.hnkylin.mc.services.ServiceFactory" %>
<%@ page import="com.hnkylin.mc.services.impl.KsvdConfigService"%>
<%@ page import="com.hnkylin.mc.utils.ControllerUtils"%>
<g:if test="${session?.user}">
  <g:set var="mcHideMode" value="${KsvdConfigService.getMcHideMode()}"/>
  <g:set var="monitoringService" value="${ServiceFactory.getService('monitoring')}"/>
  <g:set var="leafEnabled" value="${ControllerUtils.leafEnabled()}"/>
  <g:if test="${(clr == 'monitoring' && act == 'dashboard') || (clr == 'client' && act == 'index') || (clr == 'VM' && act == 'sessions')}" />
  <g:else>
    <div id="sidebar" class="sidebar sidebar-style1">
      <script type="text/javascript">
        try{ace.settings.loadState('sidebar')}catch(e){}
      </script>
      <g:if test="${path in desktopPublish}">
        <ul class="nav nav-list">
          <g:if test="${session.user.isPermitted(Permission.IMAGE_READ)}">
            <li ${path == 'image/list'? 'class="active"':''}>
              <g:link controller="image" action="list">
                <i class="icon-gold"></i>
                <span class="menu-text"> <g:message code="ui.main.lftnav.gold_images"/> </span>
              </g:link>
              <b class="arrow"></b>
            </li>
          </g:if>

          <g:if test="${session.user.isPermitted(Permission.PROV_READ) || session.user.isPermitted(Permission.POLICY_READ) || session.user.isPermitted(Permission.DP_READ) || session.user.isPermitted(Permission.AL_READ)}">
            <li class="open">
              <a href="#" class="dropdown-toggle" data-redirect="userSelect/editList">
                <i class="icon-desktop"></i>
                <span class="menu-text"> <g:message code="ui.main.lftnav.desktop.publish"/> </span>
                <b class="arrow fa fa-angle-down"></b>
              </a>
              <ul class="submenu">
                <g:if test="${session.user.isPermitted(Permission.PROV_READ)}">
                  <li ${(clr == 'userSelect' && act == 'editList')? 'class="active"':''}>
                    <g:link controller="userSelect" action="editList"><g:message code="ui.main.lftnav.desktop_assignment"/></g:link>
                  </li>
                </g:if>

                <g:if test="${session.user.isPermitted(Permission.POLICY_READ)}">
                  <li ${(clr == 'policy' && act == 'list')? 'class="active"':''}>
                    <g:link controller="policy" action="list"><g:message code="ui.main.lftnav.session_settings"/></g:link>
                  </li>
                </g:if>

                <g:if test="${UICustomize.show("desktop_pool") && session.user.isPermitted(Permission.DP_READ) && !session.user.isSecAdmin()}">
                  <li ${(clr == 'desktopPool' && act == 'list') ? 'class="active"':''}>
                    <g:link controller="desktopPool" action="list"><g:message code="ui.main.lftnav.desktop_pools"/></g:link>
                  </li>
                </g:if>
                <g:if test="${UICustomize.show('app_layer') && session.user.isPermitted(Permission.AL_READ)}">
                  <li ${(clr == 'image' && act == 'listAppLayers')? 'class="active"':''}>
                    <g:link controller="image" action="listAppLayers"><g:message code="ui.main.lftnav.appLayers"/></g:link>
                  </li>
                </g:if>

                <g:if test="${session.user.isPermitted(Permission.SOFTWARE_LIB_READ)}">
                  <li ${(clr == 'imageApp' && act == 'listAppLib')? 'class="active"':''}>
                    <g:link controller="imageApp" action="listAppLib"><g:message code="ui.main.lftnav.image_app.lib"/></g:link>
                  </li>
                </g:if>
                <g:if test="${session.user.isPermitted(Permission.SOFTWARE_PUB_READ)}">
                  <li ${(clr == 'imageApp' && act == 'listMachineApp')? 'class="active"':''}>
                      <g:link controller="imageApp" action="listMachineApp"><g:message code="ui.main.lftnav.machine_app.lib"/></g:link>
                  </li>
                </g:if>
              </ul>
            </li>
          </g:if>
          <g:if test="${UICustomize.show("app_control") && session.user.isPermitted(Permission.SEC_READ)}">
            <li class="open">
              <a href="#" class="dropdown-toggle">
                <i class="icon-client"></i>
                <span class="menu-text"> <g:message code="imageApp.appControl.title"/> </span>
                <b class="arrow fa fa-angle-down"></b>
              </a>
              <ul class="submenu">
                <li ${(clr == 'imageApp' && act == 'builtinRule')? 'class="active"':''}>
                  <g:link controller="imageApp" action="builtinRule">${message(code: 'imageApp.appControl.built_in.title')}</g:link>
                </li>
                <li ${(clr == 'imageApp' && act == 'customApp')? 'class="active"':''}>
                  <g:link controller="imageApp" action="customApp">${message(code: 'imageApp.appControl.custom.title')}</g:link>
                </li>
              </ul>
            </li>
          </g:if>
          <g:if test="${UICustomize.show("app_publish") && !session.user.isSecAdmin()}">
            <li class="open">
              <a href="#" class="dropdown-toggle">
                <i class="icon-app-publish"></i>
                <span class="menu-text"> <g:message code="ui.main.lftnav.virtual_app.publish"/> </span>
                <b class="arrow fa fa-angle-down"></b>
              </a>
              <ul class="submenu">
                  <li ${act == 'virtualAppGroups'? 'class="active"':''}>
                    <g:link controller="virtualApp" action="virtualAppGroups">${message(code: 'ui.main.lftnav.virtual_app.group')}</g:link>
                  </li>
                  <g:if test="${session.user.isPermitted(Permission.UG_READ)}">
                    <li ${act == 'appSessions'? 'class="active"':''}>
                      <g:link controller="virtualApp" action="appSessions">${message(code: 'ui.main.lftnav.virtual_app.session')}</g:link>
                    </li>
                  </g:if>
              </ul>
            </li>
          </g:if>
          <li class="open">
            <a href="#" class="dropdown-toggle">
              <i class="icon-user"></i>
              <span class="menu-text"> <g:message code="ui.main.lftnav.user.management"/> </span>
              <b class="arrow fa fa-angle-down"></b>
            </a>
            <ul class="submenu">
              <li ${act == 'listKsvdUsers'? 'class="active"':''}>
                <g:link controller="user" action="listKsvdUsers">${message(code: 'ui.main.lftnav.ksvdUsers')}</g:link>
              </li>
              <g:if test="${session.user.isPermitted(Permission.UG_READ)}">
                <li ${act == 'listKsvdGroups'? 'class="active"':''}>
                  <g:link controller="user" action="listKsvdGroups">${message(code: 'ui.main.lftnav.ksvdGroups')}</g:link>
                </li>
              </g:if>

              <g:if test="${session.user.organization.isGlobalOrg()}">
                <g:if test="${UICustomize.show("ldap") && (session.user.isMasterAdmin(session.user.organization) || session.user.isPermitted(Permission.LDAP_SERVER_READ))}">
                  <li ${act == 'listAuthProviders'? 'class="active"':''}>
                    <g:link controller="auth" action="listAuthProviders">${message(code: 'ui.main.lftnav.ldap_servers')}</g:link>
                  </li>
                </g:if>
              </g:if>
              <g:if test="${session.user.organization.isGlobalOrg()}">
                <g:if test="${!session.user.isSecAuditor()}">
                  <li ${act == 'terminalAndUser'? 'class="active"':''}>
                    <g:link controller="user" action="terminalAndUser">${message(code: 'fe.desktop.terminauser')}</g:link>
                  </li>
                </g:if>
              </g:if>
            </ul>
          </li>
        </ul>
      </g:if>

      <g:elseif test="${clr == 'network' || clr == 'virtualFireWall'}">
        <ul class="nav nav-list">
          <li class="${clr == 'network' && (act == 'list' || act == 'macAddress' || act == 'networkConfigure') ? 'active' : ''}">
            <g:if test="${session.user.isPermitted(Permission.NP_READ)}">
              <g:if test="${session.user.isSecAdmin()}">
                <g:link controller="network" action="securityGroup">
                  <i class="icon-net"></i>
                  <span class="menu-text">${message(code: 'network.title')}</span>
                </g:link>
              </g:if>
              <g:else>
                <g:link controller="network" action="list">
                  <i class="icon-net"></i>
                  <span class="menu-text">${message(code: 'network.title')}</span>
                </g:link>
              </g:else>
            </g:if>
            <g:else>
              <a disabled="disabled" title="${message(code: 'roles.no_permission.label')}">
                <span class="menu-text">${message(code: 'network.title')}</span>
              </a>
            </g:else>
          </li>
          <g:if test="${!session.user.isSecAdmin()}">
          <li class="open%{--${clr == 'network' && act != 'list' && act != 'macAddress' ? 'open' : ''}--}%">
            <a href="#" class="dropdown-toggle">
              <i class="icon-vs"></i>
              <span class="menu-text">${message(code: 'network.pool.virtualSwitch.tab.label')}</span>
              <b class="arrow fa fa-angle-down"></b>
            </a>
            <ul class="submenu">
              <g:each in="${virtualSwitch}" var="vswitch">
                <li ${vswitch.name == params.name ? 'class="active"':''}>
                  <g:if test="${session.user.isPermitted(Permission.NP_READ)}">
                      <g:link controller="network" action="summary" params="[name:vswitch.name]">${vswitch.name}</g:link>
                  </g:if>
                  <g:else>
                    <a disabled="disabled" title="${message(code: 'roles.no_permission.label')}">${vswitch.name}</a>
                  </g:else>
                </li>
              </g:each>
            </ul>
          </li>
          </g:if>
        </ul>
      </g:elseif>

      <g:elseif test="${clr == 'storage'}">
        <ul class="nav nav-list">
          <li class="${clr == 'storage' && (act == 'storageResource' || act == 'dataStore') ? 'active' : ''}">
            <g:if test="${session.user.isPermitted(Permission.SP_READ)}">
              <g:link controller="storage" action="dataStore">
                <i class="icon-store"></i>
                <span class="menu-text">${message(code: 'ui.main.lftnav.storage.pool')}</span>
              </g:link>
            </g:if>
            <g:else>
              <a disabled="disabled" title="${message(code: 'roles.no_permission.label')}">
                <span class="menu-text">${message(code: 'ui.main.lftnav.storage.pool')}</span>
              </a>
            </g:else>
          </li>
          <li class="open">
            <a href="#" class="dropdown-toggle">
              <i class="icon-ds"></i>
              <span class="menu-text">${message(code: 'storage.pool.dataStore.tab.label')}</span>
              <b class="arrow fa fa-angle-down"></b>
            </a>
            <ul class="submenu">
              <g:each in="${dataStore}" var="ds">
                <li ${ds.name == params.name? 'class="active"':''}>
                  <g:if test="${session.user.isPermitted(Permission.SP_READ)}">
                    <g:link controller="storage" action="summary" params="[name:ds.name]">${ds.name}</g:link>
                  </g:if>
                  <g:else>
                    <a disabled="disabled" title="${message(code: 'roles.no_permission.label')}">${ds.name}</a>
                  </g:else>
                </li>
              </g:each>
            </ul>
          </li>
        </ul>
      </g:elseif>

      <g:elseif test="${(clr == 'VM' && act == 'sessions') || (clr == 'VM' && act == 'summary') || (clr == 'VM' && act == 'monitoring')}">
        <ul class="nav nav-list">
            <li class="${path == 'VM/sessions' ? 'active' : ''}">
              <g:if test="${session.user.isPermitted(Permission.VM_READ)}">
                <g:link controller="VM" action="sessions"><i class="icon-vm"></i><g:message code="ui.main.nav.tabs.virtual.machine"/></g:link>
              </g:if>
              <g:else>
                <a disabled="disabled" title="${message(code: 'roles.no_permission.label')}"><g:message code="ui.main.lftnav.sessions"/></a>
              </g:else>
            </li>
            <li class="open%{--${((clr == 'VM' && act == 'summary') || (clr == 'VM' && act == 'monitoring')) ? 'open' : ''}--}%">
              <a href="#" class="dropdown-toggle">
                <i class="icon-history"></i>
                <span class="menu-text"><g:message code="ui.main.lftnav.vm.rencents"/></span>
                <b class="arrow fa fa-angle-down"></b>
              </a>
              <ul class="submenu">
                <g:each in="${vms}" var="vm">
                  <li ${(vm.desktopName == params.desktopName && vm.username == params.username && vm.serverAddr == params.serverAddr)? 'class="active"':''}>
                    <g:if test="${session.user.isPermitted(Permission.VM_READ)}">
                      <g:link controller="VM" action="summary" params="[desktopName: vm.desktopName,username:vm.username,serverAddr:vm.serverAddr]">${vm.desktopName}(${vm.username})</g:link>
                    </g:if>
                    <g:else>
                      <a disabled="disabled" title="${message(code: 'roles.no_permission.label')}">${vm}</a>
                    </g:else>
                  </li>
                </g:each>
              </ul>
            </li>
        </ul>
      </g:elseif>

      <g:elseif test="${path in alarms}">
        <ul class="nav nav-list">
          <li class="open">
            <a href="#" class="dropdown-toggle">
                <i class="icon-log"></i>
                <span class="menu-text"> <g:message code="ui.main.lftnav.log"/> </span>
                <b class="arrow fa fa-angle-down"></b>
            </a>
            <ul class="submenu">
              <g:if test="${session.user.isPermitted(Permission.MON_READ)}">
                <li ${act == 'serverEvents'? 'class="active"':''}>
                  <g:link controller="monitoring" action="serverEvents"><g:message code="ui.main.lftnav.events"/></g:link>
                </li>
                <li ${act == 'sessionEvents'? 'class="active"':''}>
                  <g:link controller="monitoring" action="sessionEvents"><g:message code="ui.main.lftnav.desktops"/></g:link>
                </li>
                <li ${act == 'serverVirtualEvents'? 'class="active"':''}>
                  <g:link controller="monitoring" action="serverVirtualEvents"><g:message code="ui.main.lftnav.serverVirtual"/></g:link>
                </li>
              </g:if>
              <g:if test="${session.user.isPermitted(Permission.AUDIT_READ)}">
                <li ${act == 'auditEvents'? 'class="active"':''}>
                  <g:link controller="monitoring" action="auditEvents"><g:message code="ui.main.lftnav.audit_events"/></g:link>
                </li>
              </g:if>
              <g:if test="${leafEnabled && session.user.organization.isGlobalOrg() && session.user.isPermitted(Permission.MON_READ)}">
                <li ${act == 'vdeEvents'? 'class="active"':''}>
                  <g:link controller="monitoring" action="vdeEvents"><g:message code="ui.main.lftnav.leaf_events"/></g:link>
                </li>
              </g:if>
              <g:if test="${session.user.isPermitted(Permission.AUDIT_READ)}">
                <li ${act == 'clientAuditEvents'? 'class="active"':''}>
                  <g:link controller="monitoring" action="clientAuditEvents"><g:message code="ui.main.lftnav.client_audit_events"/></g:link>
                </li>
              </g:if>
            </ul>
          </li>
          <g:if test="${session.user.isPermitted(Permission.MON_ALARM)}">
            <li class="open">
              <a href="#" class="dropdown-toggle">
                <i class="icon-warn"></i>
                <span class="menu-text"> <g:message code="ui.main.lftnav.alarm"/> </span>
                <b class="arrow fa fa-angle-down"></b>
              </a>
              <ul class="submenu">
                <li ${act == 'alarmEvents'? 'class="active"':''}>
                  <g:link controller="monitoring" action="alarmEvents"><g:message code="ui.main.lftnav.alarm_events"/></g:link>
                </li>
                <li ${act == 'alarmSettings'? 'class="active"':''}>
                  <g:link controller="monitoring" action="alarmSettings"><g:message code="ui.main.lftnav.alarm_settings"/></g:link>
                </li>
              </ul>
            </li>
          </g:if>

        </ul>
      </g:elseif>

      <g:elseif test="${clr == 'statistics'}">
        <ul class="nav nav-list">
          <g:if test="${session.user.isPermitted(Permission.STAT_USER)}">
            <li class="open${path in alarms.subList(0, 3)? 'open' : ''}">
              <a href="#" class="dropdown-toggle">
                <i class="icon-statistics-user"></i>
                <span class="menu-text"> <g:message code="ui.main.lftnav.statistics.user"/> </span>
                <b class="arrow fa fa-angle-down"></b>
              </a>
              <ul class="submenu">
                <g:if test = "${!session.user.isSecAdmin()}">
                  <li ${act == 'userLoginInfo'? 'class="active"':''}>
                    <g:link controller="statistics" action="userLoginInfo"><g:message code="ui.main.lftnav.statistics.user.login"/></g:link>
                  </li>
                  <li ${act == 'onlineUserNumberInfo'? 'class="active"':''}>
                    <g:link controller="statistics" action="onlineUserNumberInfo"><g:message code="ui.main.lftnav.statistics.user.online"/></g:link>
                  </li>
                  <li ${act == 'usageTimeInfo'? 'class="active"':''}>
                    <g:link controller="statistics" action="usageTimeInfo"><g:message code="ui.main.lftnav.statistics.user.time"/></g:link>
                  </li>
                </g:if>
                <li ${act == 'userUsbInfo'? 'class="active"':''}>
                  <g:link controller="statistics" action="userUsbInfo"><g:message code="ui.main.lftnav.statistics.user.usb"/></g:link>
                </li>
                <li ${act == 'dataCopyAudit'? 'class="active"':''}>
                  <g:link controller="statistics" action="dataCopyAudit"><g:message code="ui.main.lftnav.statistics.data.copy.audit"/></g:link>
                </li>
              </ul>
            </li>
          </g:if>
          <g:if test="${session.user.isPermitted(Permission.STAT_VM)}">
            <li class="open%{--${path in alarms.subList(3, 5)? 'open' : ''}--}%">
              <a href="#" class="dropdown-toggle">
                <i class="icon-statistics-vm"></i>
                <span class="menu-text"> <g:message code="ui.main.lftnav.statistics.vm"/> </span>
                <b class="arrow fa fa-angle-down"></b>
              </a>
              <ul class="submenu">
                <li ${act == 'vmStatusInfo'? 'class="active"':''}>
                  <g:link controller="statistics" action="vmStatusInfo"><g:message code="ui.main.lftnav.statistics.vm.state"/></g:link>
                </li>
                <li ${act == 'unusedVMInfo'? 'class="active"':''}>
                  <g:link controller="statistics" action="unusedVMInfo"><g:message code="ui.main.lftnav.statistics.vm.unused"/></g:link>
                </li>
              </ul>
            </li>
          </g:if>
          <g:if test="${session.user.isPermitted(Permission.STAT_READ)}">
            <li class="open%{--${path in alarms.subList(3, 5)? 'open' : ''}--}%">
              <a href="#" class="dropdown-toggle">
                <i class="icon-statistics-vm"></i>
                <span class="menu-text"> <g:message code="ui.main.lftnav.statistics.servervirtualvm"/> </span>
                <b class="arrow fa fa-angle-down"></b>
              </a>
              <ul class="submenu">

                <li ${act == 'serverVirtualResource'? 'class="active"':''}>
                  <g:link controller="statistics" action="serverVirtualResource"><g:message code="ui.main.lftnav.statistics.resource"/></g:link>
                </li>
                <li ${act == 'serverVirtualTop'? 'class="active"':''}>
                  <g:link controller="statistics" action="serverVirtualTop"><g:message code="ui.main.lftnav.statistics.top"/></g:link>
                </li>
              </ul>
            </li>
          </g:if>
          <g:if test="${!session.user.isPermitted(Permission.JZGK_READ) && session.user.isPermitted(Permission.STAT_OP)}">
            <li class="open">
              <a href="#" class="dropdown-toggle">
                <i class="icon-statistics-operation"></i>
                <span class="menu-text"> <g:message code="ui.main.lftnav.statistics.operation"/> </span>
                <b class="arrow fa fa-angle-down"></b>
              </a>
              <ul class="submenu">
                <li ${act == 'operationUserInfo'? 'class="active"':''}>
                  <g:link controller="statistics" action="operationUserInfo"><g:message code="ui.main.lftnav.statistics.operation.user"/></g:link>
                </li>
                <li ${act == 'operationEventInfo'? 'class="active"':''}>
                  <g:link controller="statistics" action="operationEventInfo"><g:message code="ui.main.lftnav.statistics.operation.event"/></g:link>
                </li>
                <li ${act == 'vmRecoverInfo'? 'class="active"':''}>
                  <g:link controller="statistics" action="vmRecoverInfo"><g:message code="ui.main.lftnav.statistics.operation.recover"/></g:link>
                </li>
              </ul>
            </li>
          </g:if>
          <g:if test="${!session.user.isPermitted(Permission.JZGK_READ) && session.user.isPermitted(Permission.STAT_FAULT)}">
            <li class="open">
              <a href="#" class="dropdown-toggle">
                <i class="icon-statistics-fault"></i>
                <span class="menu-text"> <g:message code="ui.main.lftnav.statistics.fault"/> </span>
                <b class="arrow fa fa-angle-down"></b>
              </a>
              <ul class="submenu">
                <li ${act == 'userFaultInfo'? 'class="active"':''}>
                  <g:link controller="statistics" action="userFaultInfo"><g:message code="ui.main.lftnav.statistics.fault.user"/></g:link>
                </li>
                <li ${act == 'faultTypeInfo'? 'class="active"':''}>
                  <g:link controller="statistics" action="faultTypeInfo"><g:message code="ui.main.lftnav.statistics.fault.type"/></g:link>
                </li>
              </ul>
            </li>
          </g:if>
          <g:if test="${session.user.isPermitted(Permission.JZGK_READ)}">
            <li class="open">
              <a href="#" class="dropdown-toggle">
                <i class="icon-statistics-operation"></i>
                <span class="menu-text"> <g:message code="ui.main.lftnav.statistics.client"/> </span>
                <b class="arrow fa fa-angle-down"></b>
              </a>
              <ul class="submenu">
                <li ${act == 'clientStateInfo'? 'class="active"':''}>
                  <g:link controller="statistics" action="clientStateInfo"><g:message code="ui.main.lftnav.statistics.client.state"/></g:link>
                </li>
                <li ${act == 'onlineClientInfo'? 'class="active"':''}>
                  <g:link controller="statistics" action="onlineClientInfo"><g:message code="ui.main.lftnav.statistics.client.online"/></g:link>
                </li>
              </ul>
            </li>
          </g:if>
          <g:if test="${session.user.isPermitted(Permission.STAT_ALARM)}">
            <li class="open">
              <a href="#" class="dropdown-toggle">
                <i class="icon-statistics-alarm"></i>
                <span class="menu-text"> <g:message code="ui.main.lftnav.statistics.alarm"/> </span>
                <b class="arrow fa fa-angle-down"></b>
              </a>
              <ul class="submenu">
                <li ${act == 'alarmStatisticsInfo'? 'class="active"':''}>
                  <g:link controller="statistics" action="alarmStatisticsInfo"><g:message code="ui.main.lftnav.statistics.alarm.count"/></g:link>
                </li>
                <li ${act == 'serverAlarmInfo'? 'class="active"':''}>
                  <g:link controller="statistics" action="serverAlarmInfo"><g:message code="ui.main.lftnav.statistics.alarm.server_time"/></g:link>
                </li>
                <li ${act == 'vmAlarmInfo'? 'class="active"':''}>
                  <g:link controller="statistics" action="vmAlarmInfo"><g:message code="ui.main.lftnav.statistics.alarm.vm_time"/></g:link>
                </li>
              </ul>
            </li>
          </g:if>
        </ul>
      </g:elseif>

      <g:elseif test="${path in general}">
        <ul class="nav nav-list">
          <g:if test="${session.user.isPermitted(Permission.SEC_READ) && session.user.organization.isGlobalOrg()}">
            <li class="open">
              <a href="#" class="dropdown-toggle">
                <i class="icon-perm"></i>
                <span class="menu-test"><g:message code="ui.main.lftnav.authority_management"/></span>
                <b class="arrow fa fa-angle-down"></b>
              </a>

              <ul class="submenu">
                <g:if test="${!ServiceFactory.getService('app').isSeparatePower()}">
                  <g:if test="${session.user.isPermitted(Permission.UG_READ) && session.user.organization.isGlobalOrg()}">
                    <li class="${path == 'user/list'? 'active' : ''}">
                      <g:link controller="user" action="list"><g:message code="ui.main.lftnav.administrator_account"/></g:link>
                      <b class="arrow"></b>
                    </li>
                  </g:if>
                </g:if>
                <g:if test="${session.user.organization.isGlobalOrg()}">
                  <li class="${path == 'user/showPasswordPolicy'? 'active' : ''}">
                    <g:link controller="user" action="showPasswordPolicy"><g:message code="globalPolicy.passwordPolicy.label"/></g:link>
                    <b class="arrow"></b>
                  </li>
                </g:if>

                <!-- ip策略调用入口 -->
                <li class="${path == 'visitPolicy/visitPolicys'? 'active' : ''}">
                  <g:link controller="visitPolicy" action="visitPolicys"><g:message code="ui.main.lftnav.access__policy"/></g:link>
                  <b class="arrow"></b>
                </li>

                <li class="${path == 'user/listRoles'? 'active' : ''}">
                  <g:link controller="user" action="listRoles"><g:message code="ui.main.lftnav.role_management"/></g:link>
                  <b class="arrow"></b>
                </li>
              </ul>
            </li>
          </g:if>
          <g:if test="${session.user.isPermitted(Permission.GS_READ) && session.user.organization.isGlobalOrg() || session.user.isPermitted(Permission.ORG_READ)}">
            <li class="open">
              <a href="#" class="dropdown-toggle">
                <i class="icon-sys"></i>
                <span class="menu-test"><g:message code="ui.main.lftnav.system_configuration"/></span>
                <b class="arrow fa fa-angle-down"></b>
              </a>
              <ul class="submenu">
                <g:if test="${session.user.isPermitted(Permission.GS_READ) && session.user.organization.isGlobalOrg()}">
                  <li ${act == 'showGlobalPolicy'? 'class="active"':''}>
                    <g:link controller="generalSettings" action="showGlobalPolicy"><g:message code="ui.main.lftnav.general"/></g:link>
                    <b class="arrow"></b>
                  </li>
                  <li ${path == 'generalSettings/videoRedirectList'? 'class="active"':''}>
                    <g:link controller="generalSettings" action="videoRedirectList">${message(code: 'generalSettings.videoRedirect.title')}</g:link>
                    <b class="arrow"></b>
                  </li>
                  <li ${path == 'generalSettings/trafficServerSettings'? 'class="active"':''}>
                    <g:link controller="generalSettings" action="trafficServerSettings">${message(code: 'generalSettings.trafficServer.title')}</g:link>
                    <b class="arrow"></b>
                  </li>
                  <li ${path == 'generalSettings/mailServerList'? 'class="active"':''}>
                    <g:link controller="generalSettings" action="mailServerList">${message(code: 'generalSettings.mailServerList.title')}</g:link>
                    <b class="arrow"></b>
                  </li>
                  <li ${path == 'generalSettings/welcomeMessageList'? 'class="active"':''}>
                    <g:link controller="generalSettings" action="welcomeMessageList">${message(code: 'generalSettings.welcomeMessage.menu')}</g:link>
                    <b class="arrow"></b>
                  </li>
                  <g:if test="${leafEnabled}">
                    <li ${path == 'generalSettings/vdeSettings'? 'class="active"':''}>
                      <g:link controller="generalSettings" action="vdeSettings"><g:message code="ui.main.lftnav.leaf"/></g:link>
                      <b class="arrow"></b>
                    </li>
                  </g:if>
                  <g:if test="${leafEnabled}">
                    <li ${path == 'generalSettings/labelSettings'? 'class="active"':''} title="${message(code: 'fe.common.onlyVirtualServer')}">
                      <g:link controller="generalSettings" action="labelSettings"><g:message code="serverVirutal.page.label.labelSettings"/></g:link>

                      <b class="arrow"></b>
                    </li>
                  </g:if>
                  <g:if test="${leafEnabled}">
                    <li ${path == 'generalSettings/affinityGroup'? 'class="active"':''} title="${message(code: 'fe.common.onlyVirtualServer')}">
                      <g:link controller="generalSettings" action="affinityGroup"><g:message code="serverVirutal.page.affinity.affinityGroupSetting"/></g:link>

                      <b class="arrow"></b>
                    </li>
                  </g:if>
                  <g:if test="${leafEnabled}">
                  <li ${path == 'generalSettings/dynamicSetting'? 'class="active"':''} title="${message(code: 'fe.common.onlyVirtualServer')}">
                    <g:link controller="generalSettings" action="dynamicSetting"><g:message code="serverVirutal.dynamicPolicy"/></g:link>

                    <b class="arrow"></b>
                  </li>
                </g:if>
                </g:if>

                <g:if test="${session.user.isPermitted(Permission.ORG_READ)}">
                  <li ${path == 'organization/list'? 'class="active"':''}>
                    <g:link controller="organization" action="list">
                      <g:if test="${UICustomize.show("organization")}">
                        <g:message code="ui.main.lftnav.system_scheduling"/>
                      </g:if><g:else>
                        <g:message code="ui.main.lftnav.resources"/>
                      </g:else>
                    </g:link>
                    <b class="arrow"></b>
                  </li>
                </g:if>

                <g:if test="${session.user.isPermitted(Permission.GS_READ) && session.user.organization.isGlobalOrg()}">
                  <li ${act == 'showLicense'? 'class="active"':''}>
                    <g:link controller="generalSettings" action="showLicense"><g:message code="ui.main.lftnav.license"/></g:link>
                    <b class="arrow"></b>
                  </li>
                </g:if>
                <g:if test="${session.user.isPermitted(Permission.GS_READ) && session.user.organization.isGlobalOrg()}">
                  <li ${act == 'showHA'? 'class="active"':''}>
                    <g:link controller="generalSettings" action="showHA"><g:message code="generalSettings.ha.title"/></g:link>
                    <b class="arrow"></b>
                  </li>
                </g:if>

                <g:if test="${session.user.isPermitted(Permission.GS_READ) && session.user.organization.isGlobalOrg()}">
                  <li ${path == 'zombieCloudServer/index'? 'class="active"':''}>
                    <g:link controller="zombieCloudServer" action="index"><g:message code="ui.main.lftnav.zombieCloudServer"/></g:link>
                    <b class="arrow"></b>
                  </li>
                </g:if>

                <g:if test="${session.user.isPermitted(Permission.GS_READ) && session.user.organization.isGlobalOrg()}">
                  <li ${path == 'serverCloudStartOrder/index'? 'class="active"':''}>
                    <g:link controller="serverCloudStartOrder" action="index"><g:message code="server.cloud.start.order.title"/></g:link>
                    <b class="arrow"></b>
                  </li>
                </g:if>
                %{--<g:if test="${session.user.isPermitted(Permission.GS_READ) && session.user.organization.isGlobalOrg()}">--}%
                  %{--<li ${path == 'appHA/index'? 'class="active"':''}>--}%
                    %{--<g:link controller="appHA" action="index"><g:message code="serverVirtualizationService.ha.navTitle"/></g:link>--}%
                    %{--<b class="arrow"></b>--}%
                  %{--</li>--}%
                %{--</g:if>--}%
            </ul>
          </li>
          </g:if>
          <g:if test="${session.user.organization.isGlobalOrg() && session.user.isPermitted(Permission.MAINT_READ)}">
            <g:if test="${UICustomize.show("vm_backup")}">
              <li class="open">
                <a href="#" class="dropdown-toggle">
                  <i class="icon-backup"></i>
                  <span class="menu-test"><g:message code="ui.main.lftnav.vm_backup"/></span>
                  <b class="arrow fa fa-angle-down"></b>
                </a>

                <ul class="submenu">
                  <li class="${path == 'VM/backups' ? 'active' : ''}">
                    <g:link controller="VM" action="backups"><g:message code="ui.main.lftnav.create_backup"/></g:link>
                    <b class="arrow"></b>
                  </li>
                  <li class="${path == 'backup/backupServer' ? 'active' : ''}">
                    <g:link controller="backup" action="backupServer"><g:message code="ui.main.lftnav.backup"/></g:link>
                    <b class="arrow"></b>
                  </li>
                  <li class="${path == 'serverVMBackup/highSetting' ? 'active' : ''}" title="${message(code: 'fe.common.onlyVirtualServer')}">
                    <g:link controller="serverVMBackup" action="highSetting"><g:message code="ui.main.lftnav.backup.high.setting"/></g:link>
                    <b class="arrow"></b>
                  </li>
                </ul>
              </li>
            </g:if>

            <g:if test="${UICustomize.show("vm_snapshot")}">
              <li class="open">
                <a href="#" class="dropdown-toggle">
                  <i class="icon-snap"></i>
                  <span class="menu-test"><g:message code="ui.main.lftnav.snapshot.center"/></span>
                  <b class="arrow fa fa-angle-down"></b>
                </a>

                <ul class="submenu">
                  <li class="${path == 'VM/snapStrategy' ? 'active' : ''}">
                    <g:link controller="VM" action="snapStrategy"><g:message code="ui.main.lftnav.snapshot.strategy"/></g:link>
                    <b class="arrow"></b>
                  </li>
                  <li class="${path == 'VM/snapSettings' ? 'active' : ''}">
                    <g:link controller="VM" action="snapSettings"><g:message code="ui.main.lftnav.snapshot.settings"/></g:link>
                    <b class="arrow"></b>
                  </li>
                </ul>
              </li>
            </g:if>





            <g:if test="${UICustomize.show("server_autoScaling")}">
              <li class="open">
                <a href="#" class="dropdown-toggle" title="${message(code: 'fe.common.onlyVirtualServer')}">
                  <i class="icon-backup"></i>
                  <span class="menu-test"><g:message code="ui.main.lftnav.server_auto_scaling.and.elastic_load_balance"/></span>
                  <b class="arrow fa fa-angle-down"></b>
                </a>

                <ul class="submenu">
                  <li class="${path == 'serverAutoScaling/listAutoScalingStrategyPage' ? 'active' : ''}">
                    <g:link controller="serverAutoScaling" action="listAutoScalingStrategyPage"><g:message code="ui.main.lftnav.server_auto_scaling.strategy"/></g:link>
                    <b class="arrow"></b>
                  </li>
                  <li class="${path == 'serverAutoScaling/listAutoScalingGroupPage' ? 'active' : ''}">
                    <g:link controller="serverAutoScaling" action="listAutoScalingGroupPage"><g:message code="ui.main.lftnav.server_auto_scaling.group"/></g:link>
                    <b class="arrow"></b>
                  </li>
                  <li class="${path == 'loadBalance/index' ? 'active' : ''}">
                    <g:link controller="loadBalance" action="index"><g:message code="server.virtual.left.nav.load.balance"/></g:link>
                    <b class="arrow"></b>
                  </li>
                </ul>
              </li>
            </g:if>
          </g:if>

          <g:if test="${session.user.organization.isGlobalOrg() && session.user.isPermitted(Permission.MAINT_READ)}">
            <g:if test="${UICustomize.show("cluster_manage")}">
              <li class="open">
                <a href="#" class="dropdown-toggle" title="${message(code: 'fe.common.onlyVirtualServer')}">
                  <i class="icon-backup"></i>
                  <span class="menu-test"><g:message code="ui.main.lftnav.cluster_manage"/></span>
                  <b class="arrow fa fa-angle-down"></b>
                </a>

                <ul class="submenu">
                  <li class="${path == 'generalSettings/drsSetting' ? 'active' : ''}">
                    <g:link controller="GeneralSettings" action="drsSetting"><g:message code="ui.main.lftnav.drs_manage"/></g:link>
                    <b class="arrow"></b>
                  </li>

                  <li class="${path == 'generalSettings/dpmSetting' ? 'active' : ''}">
                    <g:link controller="GeneralSettings" action="dpmSetting"><g:message code="ui.main.lftnav.dpm_manage"/></g:link>
                    <b class="arrow"></b>
                  </li>

                </ul>
              </li>
            </g:if>

          </g:if>
          <g:if test="${session.user.organization.isGlobalOrg() && session.user.isPermitted(Permission.CLIENT_READ)}">
            <li ${(path == 'app/fileManage' || path == 'client/fileManagerSet') ? 'class="active"':''}>
              <g:link controller="app" action="fileManage"><i class="icon-filemanage"></i><g:message code="ui.main.lftnav.fileManage"/></g:link>
            </li>
          </g:if>
          <g:if test="${session.user.organization.isGlobalOrg() && session.user.isPermitted(Permission.TASK_CENTER_READ)}">
            <li ${path == 'app/taskCenter'? 'class="active"':''}>
              <g:link controller="app" action="taskCenter"><i class="icon-task"></i><g:message code="ui.main.lftnav.showTask"/></g:link>
            </li>
          </g:if>
          <g:if test="${session.user.organization.isGlobalOrg() && session.user.isPermitted(Permission.APPROVAL_CENTER_READ)}">
            <li ${path == 'app/approvalCenter'? 'class="active"':''}>
              <g:link controller="app" action="approvalCenter"><i class="icon-approval"></i><g:message code="ui.main.lftnav.approvalCenter.title"/></g:link>
            </li>
          </g:if>
          <g:if test="${(session.user.organization.isGlobalOrg() && session.user.isPermitted(Permission.MAINT_READ)) || session.user.isSecAuditor()}">
            <li ${path == 'app/util'? 'class="active"':''}>
              <g:link controller="app" action="util"><i class="icon-app"></i><g:message code="ui.main.lftnav.maintenance"/></g:link>
            </li>
          </g:if>
          <g:if test="${session.user.organization.isGlobalOrg() && session.user.isPermitted(Permission.MAINT_READ)}">
            <li ${path == 'recycleBin/index'? 'class="active"':''}>
              <g:link controller="recycleBin" action="index"><i class="icon-app"></i><g:message code="ui.main.lftnav.recycle"/></g:link>
            </li>
          </g:if>
          %{--<g:if test="${session.user.organization.isGlobalOrg() && session.user.isPermitted(Permission.MAINT_READ)}">
            <li ${path == 'serverRecycle/index'? 'class="active"':''}>
              <g:link controller="serverRecycle" action="index"><i class="icon-recycle"></i><g:message code="ui.main.lftnav.recycle"/></g:link>
            </li>
          </g:if>--}%
          <g:if test="${session.user.organization.isGlobalOrg() && session.user.isPermitted(Permission.ONE_CLICK_DETECTION_READ)}">
            <li ${path == 'app/oneClickDetection'? 'class="active"':''}>
              <g:link controller="app" action="oneClickDetection"><i class="icon-task"></i>${message(code: 'generalSettings.oneclick.detection')}</g:link>
            </li>
          </g:if>
        </ul>
      </g:elseif>

      <g:elseif test="${(clr == 'servers' && act == 'monitoring') || (clr == 'servers' && act == 'configuration') || (clr == 'servers' && act == 'virtualMachine') || (clr == 'servers' && act == 'clusterMasters') ||(clr == 'servers' && act == 'summary')||(clr == 'servers' && act == 'branchServers') || (clr == 'servers' && act == 'network') || (clr == 'servers' && act == 'gpu') || (clr == 'servers' && act == 'storageResource') || (clr == 'servers' && act == 'serverVirtualMachine') ||(clr == 'servers' && act == 'serverUsb') ||(clr == 'servers' && act == 'serverPci')}">
        <g:set var="servers" value="${monitoringService.listClusterMasters()}"/>
        <g:set var="branchServs" value="${monitoringService.listBranchServersInMap()}"/>
        <g:set var="clusterName" value="${monitoringService.getClusterName()}"/>
        <ul class="nav nav-list">
          <li class="open%{--${path == 'servers/summary'? 'open' : ''}--}%">
              <a href="#" class="dropdown-toggle" data-redirect="servers/clusterMasters">
                <i class="icon-cm"></i>
                <g:if test="${clusterName}">
                  <span class="menu-text"> ${clusterName} </span>
                </g:if>
                <g:else>
                  <span class="menu-text"> ${message(code: 'machine.server.role.cm')} </span>
                </g:else>
                <b class="arrow fa fa-angle-down"></b>
              </a>
                <ul class="submenu">
                  <g:each in="${servers}" var="server">
                  <li ${server.serverAddr == params.ip? 'class="active"':''}>
                    <g:if test="${session.user.isPermitted(Permission.SERVERS_READ)}">
                      <g:if test="${server.status.toString() != 'HALT'}">
                        <g:link controller="servers" action="summary" params="[ip:server.serverAddr]">${server.serverAddr}</g:link>
                      </g:if>
                      <g:else>
                        <a disabled="disabled" title="${message(code: 'machine.server.halt.link.inactive')}">${server.serverAddr}</a>
                      </g:else>
                    </g:if>
                    <g:else>
                      <a disabled="disabled" title="${message(code: 'roles.no_permission.label')}">${server.serverAddr}</a>
                    </g:else>
                  </li>
                  </g:each>
                </ul>
          </li>
          <g:if test="${UICustomize.show("branch")}">
            <g:each in="${branchServs.keySet()}" var="cmFQDN">
              <li class="open">
                <a href="#" class="dropdown-toggle" data-redirect="servers/branchServers?cm=${cmFQDN}">
                  <i class="icon-cm-b"></i>
                  <span class="menu-text">${cmFQDN}</span>
                  <b class="arrow fa fa-angle-down"></b>
                </a>
                <ul class="submenu">
                  <g:each in="${branchServs[cmFQDN]}" var="server">
                    <li class="">
                      <g:if test="${session.user.isPermitted(Permission.POLICY_READ)}">
                        <a href="https://${server.serverAddr}:8443/mc">${server.serverAddr}</a>
                      </g:if>
                      <g:else>
                        <a disabled="disabled" title="${message(code: 'roles.no_permission.label')}">${server.serverAddr}</a>
                      </g:else>
                    </li>
                  </g:each>
                </ul>
              </li>
            </g:each>
          </g:if>
        </ul>
      </g:elseif>

      <g:elseif test="${(clr == 'servers' && UICustomize.show("branch") && act == 'branchServersManage')}">
        <g:set var="branchServs" value="${monitoringService.listServers()}"/>
        <ul class="nav nav-list">
          <li class="open%{--${path == 'servers/summary'? 'open' : ''}--}%">
            <a href="#" class="dropdown-toggle">
              <i class="icon-cm"></i>
              <span class="menu-text"> ${message(code: 'ui.main.lftnav.branch_servers')} </span>
              <b class="arrow fa fa-angle-down"></b>
            </a>
            <ul class="submenu">
              <g:each in="${branchServs}" var="server">
                <li ${server.serverAddr == params.ip? 'class="active"':''}>
                    <a disabled="disabled" title="${message(code: 'roles.no_permission.label')}">${server.serverAddr}</a>
                </li>
              </g:each>
            </ul>
          </li>
        </ul>
      </g:elseif>

      <g:elseif test="${clr == 'client'}">
        <ul class="nav nav-list">
          <li ${path == 'client/list'? 'class="active"':''}>
            <g:link controller="client" action="list">
              <i class="icon2-client"></i>
              <span class="menu-text"> <g:message code="ui.main.lftnav.clients"/> </span>
            </g:link>
            <b class="arrow"></b>
          </li>
          <li ${path == 'client/listTask'? 'class="active"':''}>
            <g:link controller="client" action="listTask">
              <i class="icon2-task"></i>
              <span class="menu-text"> <g:message code="ui.main.lftnav.tasks"/> </span>
            </g:link>
            <b class="arrow"></b>
          </li>
        </ul>
      </g:elseif>

      <g:elseif test="${clr == 'client'}">
        <ul class="nav nav-list">
          <li ${path == 'client/list'? 'class="active"':''}>
            <g:link controller="client" action="list">
              <i class="icon2-client"></i>
              <span class="menu-text"> <g:message code="ui.main.lftnav.clients"/> </span>
            </g:link>
            <b class="arrow"></b>
          </li>
          <li ${path == 'client/listTask'? 'class="active"':''}>
            <g:link controller="client" action="listTask">
              <i class="icon2-task"></i>
              <span class="menu-text"> <g:message code="ui.main.lftnav.tasks"/> </span>
            </g:link>
            <b class="arrow"></b>

          </li>
        </ul>
      </g:elseif>

      <g:elseif test="${clr == 'serverVirtualization'}">
        <ul class="widget-box widget-color-gray f-bni">
          <li class="${path == 'serverVirtualization/index'? 'active' : ''}" >
              <div class="widget-header f-bni" style="background: #090f26 !important;border-bottom: 0px solid #DDD;">
                <h4 class="widget-title lighter smaller s-white">
                  <i class="fa fa-users s-white"></i>&nbsp;${message(code: 'ui.main.lftnav.VirtualServers')}
                </h4>
                <div class="widget-toolbar">
                  <g:if test="${session.user.isPermitted(Permission.UG_FULL)}">
                    <a id="create" href="/mc/serverVirtualization/_createGroup" data-action=""
                       onclick="javascript:if(selectGroupFalg){KSVD.loadModal(this, event, false, 'auto', '${createLink(uri: '/')}', '600');}"
                       title="${message(code: 'ksvd.client.group.create_new_title')}">
                      <i class="ace-icon fa fa-plus s-blue1"></i>
                    </a>
                    <a id="edit" href="/mc/serverVirtualization/_createGroup?groupName=" data-action=""
                       onclick="javascript:if(selectGroupFalg){var now_href=$(this).attr('href');$(this).attr('href',now_href+selectedGroupName);KSVD.loadModal(this, event, false, 'auto', '${createLink(uri: '/')}', '600');$(this).attr('href',now_href)}"
                       title="${message(code: 'ksvd.client.group.edit_title')}">
                      <i class="ace-icon fa fa-edit s-blue1"></i>
                    </a>
                  %{--自动搜索按钮--}%
                    %{--<a id="groupBySearch" href="#" data-action="" disabled="disabled"--}%
                       %{--title="${message(code: 'ksvd.client.group.button.autosearch')}">--}%
                      %{--<i class="ace-icon fa fa-refresh s-blue1"></i>--}%
                    %{--</a>--}%
                    <a id="deletegroup" onclick="return false;" href="javascript:void(0)"
                       title="${message(code: 'ksvd.client.group.delete_title')}">
                      <i class="ace-icon fa fa-trash s-blue1"></i>
                    </a>
                  </g:if>
                </div>
              </div>

          </li>
        </ul>
        <g:render template="/serverVirtualization/grouplist" model="[skin:'dark']"/>
      </g:elseif>

    </div>
  </g:else>
</g:if>
