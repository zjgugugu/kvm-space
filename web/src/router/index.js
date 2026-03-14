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
      { path: 'dashboard', name: 'Dashboard', component: () => import('../views/Dashboard.vue'), meta: { title: '总览' } },
      { path: 'hosts', name: 'Hosts', component: () => import('../views/Hosts.vue'), meta: { title: '主机管理' } },
      { path: 'templates', name: 'Templates', component: () => import('../views/Templates.vue'), meta: { title: '黄金镜像' } },
      { path: 'specs', name: 'Specs', component: () => import('../views/Specs.vue'), meta: { title: '桌面规格' } },
      { path: 'publish-rules', name: 'PublishRules', component: () => import('../views/PublishRules.vue'), meta: { title: '发布规则' } },
      { path: 'vms', name: 'VMs', component: () => import('../views/VMs.vue'), meta: { title: '虚拟机管理' } },
      { path: 'vms/:id', name: 'VMDetail', component: () => import('../views/VMDetail.vue'), meta: { title: '虚拟机详情' } },
      { path: 'networks', name: 'Networks', component: () => import('../views/Networks.vue'), meta: { title: '网络管理' } },
      { path: 'storage', name: 'Storage', component: () => import('../views/Storage.vue'), meta: { title: '存储管理' } },
      { path: 'users', name: 'Users', component: () => import('../views/Users.vue'), meta: { title: '用户管理' } },
      { path: 'events', name: 'Events', component: () => import('../views/Events.vue'), meta: { title: '操作日志' } },
      { path: 'alerts', name: 'Alerts', component: () => import('../views/Alerts.vue'), meta: { title: '告警管理' } },
      { path: 'system', name: 'System', component: () => import('../views/System.vue'), meta: { title: '系统设置' } }
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
