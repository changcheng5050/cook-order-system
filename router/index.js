import { createRouter, createWebHistory } from 'vue-router'
import { supabase } from '../lib/supabase'

const routes = [
  {
    path: '/',
    name: 'Menu',
    component: () => import('../views/Menu.vue')
  },
  {
    path: '/history',
    name: 'History',
    component: () => import('../views/History.vue')
  },
  {
    path: '/admin',
    name: 'AdminLogin',
    component: () => import('../views/AdminLogin.vue')
  },
  {
    path: '/admin/dishes',
    name: 'AdminDishes',
    component: () => import('../views/AdminDishes.vue')
  },
  {
    path: '/admin/orders',
    name: 'AdminOrders',
    component: () => import('../views/AdminOrders.vue')
  },
  {
    path: '/admin/customers',
    name: 'AdminCustomers',
    component: () => import('../views/AdminCustomers.vue')
  },
  {
    path: '/admin/settings',
    name: 'AdminSettings',
    component: () => import('../views/AdminSettings.vue')
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

// 全局导航守卫：所有 /admin/* 路由（除 /admin 登录页）必须已登录
router.beforeEach(async (to, from, next) => {
  if (to.path.startsWith('/admin') && to.path !== '/admin') {
    const { data: { session } } = await supabase.auth.getSession()
    if (!session) {
      // 未登录，跳转回管理员登录页
      next('/admin')
      return
    }
  }
  next()
})

export default router
