import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '../store/auth'

const routes = [
  {
    path: '/login',
    name: 'Login',
    component: () => import('../views/Login.vue'),
    meta: { public: true }
  },
  {
    path: '/',
    component: () => import('../layouts/MainLayout.vue'),
    redirect: '/dashboard',
    children: [
      { path: 'dashboard', name: 'Dashboard', component: () => import('../views/Dashboard.vue'), meta: { title: '仪表板' } },
      // 桌面发布
      { path: 'templates', name: 'Templates', component: () => import('../views/Templates.vue'), meta: { title: '黄金镜像', parent: '桌面发布' } },
      { path: 'specs', name: 'Specs', component: () => import('../views/Specs.vue'), meta: { title: '桌面规格', parent: '桌面发布' } },
      { path: 'publish-rules', name: 'PublishRules', component: () => import('../views/PublishRules.vue'), meta: { title: '发布规则', parent: '桌面发布' } },
      { path: 'desktop-users', name: 'DesktopUsers', component: () => import('../views/Users.vue'), meta: { title: '用户管理', parent: '桌面发布' } },
      // 虚拟机
      { path: 'vms', name: 'VMs', component: () => import('../views/VMs.vue'), meta: { title: '桌面虚拟机' } },
      { path: 'vms/:id', name: 'VMDetail', component: () => import('../views/VMDetail.vue'), meta: { title: '虚拟机详情' } },
      // 一体机/主机
      { path: 'hosts', name: 'Hosts', component: () => import('../views/Hosts.vue'), meta: { title: '服务器管理', parent: '一体机' } },
      { path: 'hosts/:id', name: 'HostDetail', component: () => import('../views/HostDetail.vue'), meta: { title: '服务器详情', parent: '一体机' } },
      // 网络池
      { path: 'networks', name: 'Networks', component: () => import('../views/Networks.vue'), meta: { title: '网络池' } },
      // 存储池
      { path: 'storage', name: 'Storage', component: () => import('../views/Storage.vue'), meta: { title: '存储池' } },
      // 日志告警
      { path: 'events', name: 'Events', component: () => import('../views/Events.vue'), meta: { title: '日志', parent: '日志告警' } },
      { path: 'alerts', name: 'Alerts', component: () => import('../views/Alerts.vue'), meta: { title: '告警事件', parent: '日志告警' } },
      // 任务/审批
      { path: 'tasks', name: 'TaskCenter', component: () => import('../views/TaskCenter.vue'), meta: { title: '任务中心' } },
      { path: 'approvals', name: 'ApprovalCenter', component: () => import('../views/ApprovalCenter.vue'), meta: { title: '审批中心' } },
      // 统计报表
      { path: 'reports', name: 'Reports', component: () => import('../views/Reports.vue'), meta: { title: '统计报表' } },
      // 系统管理
      { path: 'system', name: 'System', component: () => import('../views/System.vue'), meta: { title: '系统管理' } },
    ]
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

router.beforeEach((to, from, next) => {
  if (to.meta.public) return next()
  const auth = useAuthStore()
  if (!auth.isLoggedIn) return next('/login')
  next()
})

export default router
