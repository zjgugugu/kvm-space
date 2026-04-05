<!--
 Copyright 2006-2017 Hunan Kylin, Inc.  All Rights Reserved.

 NOTICE: ALL INFORMATION CONTAINED HEREIN IS, AND REMAINS THE PROPERTY OF
 HUNAN KYLIN, INC. AND ITS SUPPLIERS, IF ANY. THE INTELLECTUAL AND
 TECHNICAL CONCEPTS CONTAINED HEREIN ARE PROPRIETARY TO HUNAN KYLIN, INC.
 AND ITS SUPPLIERS AND MAY BE COVERED BY U.S. AND FOREIGN PATENTS, PATENTS IN
 PROCESS, AND ARE PROTECTED BY TRADE SECRET OR COPYRIGHT LAW. DISSEMINATION
 OF THIS INFORMATION OR REPRODUCTION OF THIS MATERIAL IS STRICTLY FORBIDDEN
 UNLESS PRIOR WRITTEN PERMISSION IS OBTAINED FROM HUNAN KYLIN, INC.

modify by ph
 1. 删除bootstrap.min.js

-->
<%@ page import="com.hnkylin.mc.ksvd.UICustomize; com.hnkylin.mc.user.Permission" %>
<%@ page import="com.hnkylin.mc.services.ServiceFactory" %>
<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="com.hnkylin.mc.services.impl.KsvdConfigService"%>
<g:set var="mcHideMode" value="${KsvdConfigService.getMcHideMode()}"/>
<g:set var="storageType" value="${KsvdConfigService.getStorageType()}"/>
<g:set var="helpAlias" value="${request.getServletPath().replaceAll('/grails', '').replaceAll('.dispatch', '').substring(1).replaceAll('/', '_')}"/>
<g:if test = "${filterPaths.indexOf(path) == -1}" >
    <g:javascript src="ace/bootstrap.min.js"/>
</g:if>

<g:if test="${session.user && session.user.isPermitted(Permission.JZGK_READ) && session.user.organization.isGlobalOrg()}">
        <section style="color: #fff;font-size: 1.4em;position: absolute;z-index: 1;left: 50%;transform: translateX(-50%);padding-top: 6px;
        width: 510px;height: 50px;background: url(../../mc/images/dashboard-exit-full-screen-wrap.png) no-repeat;background-size: 100%;text-align: center;">
            ${message(code: 'fe.module.zkbm.centerTitle')}
        </section>
</g:if>


<g:if test="${session.user}">
    <div id="navbar" class="navbar">
    <div class="navbar-container" id="navbar-container">
        <div class="navbar-header pull-left">
            <a href="${createLink(uri:'/')}reporting/dashboard" class="navbar-brand">
                <small>
                    <i class=""></i>
                    <g:if test="${lang.toLowerCase().indexOf('en') > -1}">
                        <img id="KylinCloudLogo" src="${createLink(uri:'/')}images/hnkylin/logo.png" height="70" width="229"/>
                    </g:if>
                    <g:else>
                        <img id="KylinCloudLogo" src="${createLink(uri:'/')}images/hnkylin/${UICustomize.logo}" height="70" width="229"/>
                    </g:else>
                </small>
            </a>
        </div>
        <nav role="navigation" class="navbar-menu">
            <ul class="nav navbar-nav">
                <g:if test="${!session.user.isSecAdmin() && !session.user.isSecAuditor()}">
                    <li id="nav_dashboard_li" ${(clr == 'monitoring' && act == 'dashboard')? 'class="active"':''}>
                        <g:link controller="monitoring" action="dashboard" title="${message(code: 'ui.main.nav.tabs.dashboard')}">${message(code: 'ui.main.nav.tabs.dashboard')}</g:link>
                    </li>
                </g:if>
                <g:if test="${session.user.isPermitted(Permission.DESKTOP_PUBLISH_READ)&& session.user.organization.isGlobalOrg()}">
                    <li id="nav_desktop_publish_id" ${path in desktopPublish? 'class="active"':''}>
                        <g:if test="${session.user.isPermitted(Permission.IMAGE_READ)}">
                            <g:link  controller="image" action="list" title="${message(code: 'ui.main.nav.tabs.desktop.publish')}">${message(code: 'ui.main.nav.tabs.desktop.publish')}</g:link>
                        </g:if>
                        <g:elseif test="${session.user.isPermitted(Permission.DP_READ) || session.user.isPermitted(Permission.AL_READ) || session.user.isPermitted(Permission.POLICY_READ) || session.user.isPermitted(Permission.PROV_READ)}">
                            <g:link  controller="userSelect" action="editList" title="${message(code: 'ui.main.nav.tabs.desktop.publish')}">${message(code: 'ui.main.nav.tabs.desktop.publish')}</g:link>
                        </g:elseif>
                        <g:elseif test="${!session.user.isPermitted(Permission.JZGK_READ)}">
                            <g:link  controller="user" action="listKsvdUsers" title="${message(code: 'ui.main.nav.tabs.desktop.publish')}">${message(code: 'ui.main.nav.tabs.desktop.publish')}</g:link>
                        </g:elseif>
                    </li>
                </g:if>
                <g:if test="${session.user.isPermitted(Permission.JZGK_READ) && session.user.organization.isGlobalOrg()}">
                    <li id="nav_document_id" ${clr == 'document'? 'class="active"':''}>
                        <g:link controller="document" action="list" title="${message(code: 'ui.main.nav.tabs.document.management')}">${message(code: 'ui.main.nav.tabs.document.management')}</g:link>
                    </li>
                </g:if>

                <g:if test="${session.user.isPermitted(Permission.VM_READ) && !session.user.isSecAdmin()}">
                    <li id="nav_virtual_machine_id_new" ${(clr == 'VM' && act == 'desktopVms')? 'class="active"':''}>
                        <g:link controller="VM" action="desktopVms" title="${message(code: 'ui.main.nav.tabs.virtual.machine.new')}">${message(code: 'ui.main.nav.tabs.virtual.machine.new')}</g:link>
                    </li>
                </g:if>


                <g:if test="${session.user.isPermitted(Permission.GS_READ) && session.user.organization.isGlobalOrg()}">
                    <li id="nav_serverVirtualization_id" ${clr == 'serverVirtualization' ? 'class="active"':''}>
                        <g:link controller="serverVirtualization" action="index" title="${message(code: 'ui.main.nav.tabs.server.virtualization')}">${message(code: 'ui.main.nav.tabs.server.virtualization')}</g:link>
                    </li>
                </g:if>
                <g:if test="${session.user.organization.isGlobalOrg()}">
                    <li id="nav_network_pool_id" ${clr == 'network'? 'class="active"':''}>
                        <g:if test="${session.user.isPermitted(Permission.NP_READ)&&((session.user.isSystemAdmin()||session.user.isMasterAdmin()))}">
                            <g:link controller="network" action="list" title="${message(code: 'ui.main.nav.tabs.network.pool')}">${message(code: 'ui.main.nav.tabs.network.pool')}</g:link>
                        </g:if>
                        <g:if test="${session.user.isPermitted(Permission.NP_READ)&&session.user.isSecAdmin()}">
                            <g:link controller="network" action="securityGroup" title="${message(code: 'ui.main.nav.tabs.network.pool')}">${message(code: 'ui.main.nav.tabs.network.pool')}</g:link>
                        </g:if>
                    </li>
                </g:if>
                <g:if test="${session.user.organization.isGlobalOrg()}">
%{--                    <li id="nav_storage_pool_id" ${clr == 'storage'? 'class="active"':''}>--}%
%{--                        <g:if test="${session.user.isPermitted(Permission.SP_READ)}">--}%
%{--                            <g:link controller="storage" action="dataStore" title="${message(code: 'ui.main.nav.tabs.storage.pool')}">${message(code: 'ui.main.nav.tabs.storage.pool')}</g:link>--}%
%{--                        </g:if>--}%
%{--                    </li>--}%
                    <li id="nav_storage_pool_id" ${clr == 'storageNew'? 'class="active"':''}>
                        <g:if test="${session.user.isPermitted(Permission.SP_READ)}">
                            <g:link controller="storageNew" action="storageNew" title="${message(code: 'ui.main.nav.tabs.storage.pool')}">${message(code: 'ui.main.nav.tabs.storage.pool')}</g:link>
                        </g:if>
                    </li>
                </g:if>
                <g:if test="${session.user.organization.isGlobalOrg()}">
                    <li id="nav_physical_machine_id" ${clr == 'servers'? 'class="active"':''}>
                        <g:if test="${session.user.isPermitted(Permission.SERVERS_READ)&&!session.user.isSecAdmin()}">
                            <g:link controller="servers" action="clusterMasters" title="${message(code: 'ui.main.nav.tabs.physical.machine')}">${message(code: 'ui.main.nav.tabs.physical.machine')}</g:link>
                        </g:if>
                    </li>
%{--                    <li id="nav_log_warning_id" ${path in alarms? 'class="active"':''}>--}%
%{--                        <g:if test="${!session.user.isPermitted(Permission.JZGK_READ) && session.user.isPermitted(Permission.MON_READ)}">--}%
%{--                            <g:link controller="monitoring" action="serverEvents" title="${message(code: 'ui.main.nav.tabs.log.warning')}">${message(code: 'ui.main.nav.tabs.log.warning')}</g:link>--}%
%{--                        </g:if>--}%
%{--                        <g:elseif test="${session.user.isPermitted(Permission.AUDIT_READ)}">--}%
%{--                            <g:link controller="monitoring" action="auditEvents" title="${message(code: 'ui.main.nav.tabs.log.warning')}">${message(code: 'ui.main.nav.tabs.log.warning')}</g:link>--}%
%{--                        </g:elseif>--}%
%{--                    </li>--}%
                    <g:if test="${(!session.user.isSecAdmin())&&(!session.user.isSystemAdmin())}">
                        <li id="nav_log_warning_id01" ${clr == 'monitoringNew'? 'class="active"':''}>
                            <g:link controller="monitoringNew" action="monitoringNew" title="${message(code: 'ui.main.nav.tabs.log.warning')}">${message(code: 'ui.main.nav.tabs.log.warning')}</g:link>
                        </li>
                    </g:if>
                </g:if>
                <g:if test="${session.user.isPermitted(Permission.JZGK_READ) && session.user.organization.isGlobalOrg()}">
                    <li id="nav_client_management_id" ${clr == 'client' ? 'class="active"':''}>
                        <g:link controller="client" action="index" title="${message(code: 'ui.main.nav.tabs.client.management')}">${message(code: 'ui.main.nav.tabs.client.management')}</g:link>
                    </li>
                </g:if>
                <g:if test="${session.user.organization.isGlobalOrg()}">
                    <li id="nav_statistic_id" ${clr == 'statistics'? 'class="active"':''}>
                        <g:if test="${(!session.user.isSecAdmin())&&(!session.user.isSystemAdmin())}">
                            <g:link controller="statistics" action="userLoginInfo" title="${message(code: 'ui.main.nav.tabs.statistics')}">${message(code: 'ui.main.nav.tabs.statistics')}</g:link>
                        </g:if>
                    </li>
                </g:if>
                <g:if test="${session.user.organization.isGlobalOrg()}">
                    <g:if test="${!session.user.isPermitted(Permission.JZGK_READ) && session.user.isPermitted(Permission.CLIENT_READ)}">
                        <li id="nav_client_management_id" ${clr == 'client' && act != 'fileManagerSet'? 'class="active"' : ''}>
                            <g:if test="${session.user.isPermitted(Permission.CLIENT_READ)}">
                                <g:link controller="client" action="index" title="${message(code: 'ui.main.nav.tabs.client.management')}">${message(code: 'ui.main.nav.tabs.client.management')}</g:link>
                            </g:if>
                        </li>
                    </g:if>
                </g:if>
                <li id="nav_system_management_id" ${(clr == 'generalSettings' && act != 'setRDP' && act != 'setSPICE' || (clr == 'organization' && act == 'list') || (clr == 'user' && (act == 'list' || act == 'listRoles' || act == 'showPasswordPolicy')) || (clr == 'app' && act == 'util') || (clr == 'app' && act == 'oneClickDetection') || (clr == 'app' && act == 'taskCenter') || (clr == 'recycleBin' && act == 'index') || (clr == 'VM' && act == 'backups') || (clr == 'VM' && act == 'restoreBackups') || (clr == 'VM' && act == 'snapStrategy') || (clr == 'backup' && act == 'backupServer') || (clr == 'VM' && act == 'snapSettings') || (clr == 'visitPolicy' && act == 'visitPolicys') || (clr == 'app' && act == 'approvalCenter') || (clr == 'app' && act == 'fileManage') || (clr == 'client' && act == 'fileManagerSet'))? 'class="active"':''}>
                    <g:if test="${session.user.isPermitted(Permission.GS_READ) && session.user.organization.isGlobalOrg()}">
                        <g:link controller="generalSettings" action="showGlobalPolicy" title="${message(code: 'ui.main.nav.tabs.system.management')}">${message(code: 'ui.main.nav.tabs.system.management')}</g:link>
                    </g:if>
                    <g:elseif test="${session.user.isPermitted(Permission.ORG_READ)}">
                        <g:link controller="organization" action="list" title="${message(code: 'ui.main.nav.tabs.system.management')}">${message(code: 'ui.main.nav.tabs.system.management')}</g:link>
                    </g:elseif>
                    <g:elseif test="${session.user.isPermitted(Permission.SEC_READ)}">
                        <g:link controller="user" action="listRoles" title="${message(code: 'ui.main.nav.tabs.system.management')}">${message(code: 'ui.main.nav.tabs.system.management')}</g:link>
                    </g:elseif>
                    <g:elseif test="${session.user.isSecAuditor()}">
                        <g:link controller="app" action="util" title="${message(code: 'ui.main.nav.tabs.system.management')}">${message(code: 'ui.main.nav.tabs.system.management')}</g:link>
                    </g:elseif>
                </li>
            </ul>
        </nav>
        <div class="navbar-buttons navbar-header pull-right" role="navigation">
            <ul class="nav navbar-nav j-fullscreen-text">

                <g:if test="${session.user.isPermitted(Permission.TASK_CENTER_READ) && session.user.organization.isGlobalOrg()}">
                    <li class="grey dropdown-modal">
                        <a  class="dropdown-toggle" href="#" title="${message(code: 'ui.main.mastthead.taskhint')}">
                            <i class="ksvd-task"></i>
                            <span class="badge badge-grey"></span>
                        </a>

                        <ul class="dropdown-menu-right dropdown-navbar dropdown-menu dropdown-caret dropdown-close" style="left: -215px;">
                            <li class="dropdown-header">
                                <i class="ace-icon fa fa-check"></i>
                                ${message(code: 'ui.task.notification.header')}
                            </li>

                            <li class="dropdown-content">
                                <ul class="dropdown-menu dropdown-navbar">
                                </ul>
                            </li>

                            <li class="dropdown-footer">
                                <g:link controller="app" action="taskCenter" style="cursor: pointer;" class="hide" >${message(code: 'ui.task.notification.more')}</g:link>
                                <a id="task_pending_id" style="cursor: pointer;" class="hide" >
                                    ${message(code: 'ui.task.notification.pending')}
                                </a>
                            </li>
                        </ul>
                    </li>
                </g:if>

                <g:if test="${session.user.isPermitted(Permission.APPROVAL_CENTER_READ) && session.user.organization.isGlobalOrg()}">
                    <li class="white dropdown-modal">
                        <a data-toggle="dropdown" class="dropdown-toggle" href="#" title="${message(code: 'ui.main.approvalCenter.notify')}">
                            <i class="icon-approval2"></i>
                            <span class="badge badge-light"></span>
                        </a>

                        <ul class="dropdown-menu-right dropdown-navbar dropdown-menu dropdown-caret dropdown-close" style="left: -215px;">
                            <li class="dropdown-header">
                                <i class="ace-icon fa fa-check"></i>
                                ${message(code: 'ui.main.approvalCenter.notify')}
                            </li>

                            <li class="dropdown-content">
                                <ul class="dropdown-menu dropdown-navbar">
                                </ul>
                            </li>

                            <li class="dropdown-footer">
                                <g:link controller="app" action="approvalCenter" style="cursor: pointer;">${message(code: 'ui.main.approvalCenter.view')}</g:link>
                            </li>
                        </ul>
                    </li>
                </g:if>

                <g:if test="${!session.user.isPermitted(Permission.JZGK_READ) && (!session.user.isSecAdmin())&&(!session.user.isSystemAdmin())}">
                    <li class="purple dropdown-modal">
                        <a data-toggle="dropdown" class="dropdown-toggle" href="#">
                            <i class="alarm"></i>
                            <span class="badge badge-important"></span>
                        </a>

                        <ul class="dropdown-menu-right dropdown-navbar dropdown-menu dropdown-caret dropdown-close" style="left: -215px;">
                            <li class="dropdown-header">
                                <i class="ace-icon fa fa-exclamation-triangle"></i>
                                ${message(code: 'ui.alarm.notification.header')}
                            </li>
                            <li class="dropdown-content">
                                <ul class="dropdown-menu dropdown-navbar j-alarm20200507">
                                </ul>
                            </li>
                            <div style="display: inline;line-height: 3.4;"%{--class="dropdown-footer"--}%>
                                <a id="more-notification" style="position: relative;left:40px;bottom:2px;">
                                    <u>${message(code: 'ui.alarm.notification.more')}</u>
                                    %{--<i class="ace-icon fa fa-arrow-right"></i>--}%
                                </a>

                                <a id="ignore-notification" style="position: absolute;right:40px;bottom:2px;visibility: hidden;">
                                    <u>${message(code: 'ui.alarm.notification.ignore')}</u>
                                    %{--<i class="ace-icon fa fa-arrow-right"></i>--}%
                                </a>
                            </div>
                        </ul>
                    </li>
                </g:if>

                <li class="light-blue dropdown-modal" ${session.user && session.user.isPermitted(Permission.JZGK_READ) ? 'style="border-left-width:0"' : ''}>
                    <a data-toggle="dropdown" href="#" class="dropdown-toggle">
                        <span class="username">
                            <g:if test="${session.user.organization.isGlobalOrg()}">
                                ${session.user.username}
                            </g:if>
                            <g:else>
                                ${session.user.username}#${session.user.organization}
                            </g:else>
                            <b class="arrow fa fa-angle-down"></b>
                        </span>
                    </a>

                    <ul class="dropdown-menu dropdown-user af-wautoi">
                        <li>
                            <g:link onclick="javascript:KSVD.loadModal(this, event, false, 'auto', '${createLink(uri: '/')}', 450);return false;"
                                    controller="user" action="resetPassword" id="${ksvdUser.username}"
                                    title="${message(code: 'user.ksvdUser.resetPasswd.label', args: [ksvdUser.username])}">
                                <i class="icon-resetPassowrd af-ml0i" ></i> ${message(code: 'user.ksvdUser.resetPasswd')}
                            </g:link>
                        </li>

                        <li>
                            <g:if test="${certsUsed != null && certsUsed.size() > 0}">
                                <g:link onclick="KSVD.removeCert();return false;" action="logout" controller="user">
                                    <i class="icon-logout af-ml0i" ></i> ${message(code:'logout.label')}
                                </g:link>
                            </g:if>
                            <g:else>
                                <g:link action="logout" controller="user">
                                    <i class="icon-logout af-ml0i" ></i> ${message(code:'logout.label')}
                                </g:link>
                            </g:else>
                        </li>

                        <li>
                            <a href="javascript: void(0);" id="buildinfo" class="j-dialog-info-trigger" data-info="${message(code: 'app.about.build', args: [app?.build?.version, app?.build?.revision])}">
                                <i class="icon-about af-ml0i" ></i> ${message(code: 'app.about.label')}
                            </a>
                        </li>
                    </ul>
                </li>
            </ul>
        </div>
    </div>
</div>
</g:if>
