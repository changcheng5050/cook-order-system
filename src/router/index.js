import { createRouter, createWebHistory } from 'vue-router'

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

export default router
