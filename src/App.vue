<template>
  <div id="app-root">
    <!-- 管理员左侧导航（仅管理员已登录且在管理页面时显示） -->
    <aside v-if="isAdminPage && isAdmin" class="admin-sidebar">
      <div class="sidebar-logo">
        <span class="logo-icon">🍳</span>
        <span v-if="!sidebarCollapsed" class="logo-text">{{ shopSettings.shop_name }}</span>
      </div>
      <nav class="sidebar-nav">
        <router-link to="/admin/dishes" class="nav-item">
          <span class="nav-icon">🍳</span>
          <span v-if="!sidebarCollapsed" class="nav-label">菜品管理</span>
        </router-link>
        <router-link to="/admin/customers" class="nav-item">
          <span class="nav-icon">👥</span>
          <span v-if="!sidebarCollapsed" class="nav-label">客户管理</span>
        </router-link>
        <router-link to="/admin/orders" class="nav-item">
          <span class="nav-icon">📋</span>
          <span v-if="!sidebarCollapsed" class="nav-label">订单查看</span>
        </router-link>
        <router-link to="/admin/settings" class="nav-item">
          <span class="nav-icon">⚙️</span>
          <span v-if="!sidebarCollapsed" class="nav-label">系统设置</span>
        </router-link>
      </nav>
      <div class="sidebar-footer">
        <button class="nav-logout" @click="logout">
          <span class="nav-icon">🚪</span>
          <span v-if="!sidebarCollapsed" class="nav-label">退出登录</span>
        </button>
      </div>
    </aside>

    <!-- 主内容区 -->
    <div :class="['main-content', { 'with-sidebar': isAdminPage && isAdmin }]">
      <router-view />
    </div>
  </div>
</template>

<script setup>
import { ref, provide, onMounted, computed, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { supabase } from './lib/supabase'

const route = useRoute()
const router = useRouter()
const sidebarCollapsed = ref(false)
const isAdmin = ref(false)

const isAdminPage = computed(() => route.path.startsWith('/admin'))

// 检查管理员登录状态
async function checkAdmin() {
  const { data: { session } } = await supabase.auth.getSession()
  isAdmin.value = !!session
}

// 监听路由变化，每次切换页面都检查登录状态
watch(() => route.path, () => {
  if (route.path.startsWith('/admin')) {
    checkAdmin()
  }
}, { immediate: true })

const version = ref('v2.0.1')

const shopSettings = ref({
  shop_name: '阿旺小厨房',
  logo_url: ''
})

async function loadSettings() {
  const { data } = await supabase.from('settings').select('*').single()
  if (data) {
    shopSettings.value = {
      shop_name: data.shop_name || '阿旺小厨房',
      logo_url: data.logo_url || ''
    }
  }
}

onMounted(() => {
  loadSettings()
})

provide('shopSettings', shopSettings)

function logout() {
  supabase.auth.signOut()
  isAdmin.value = false
  router.push('/admin')
}
</script>

<style scoped>
#app-root {
  min-height: 100vh;
  display: flex;
  position: relative;
}

/* 版本号：页面顶部右侧 */
.admin-sidebar {
  position: fixed;
  left: 0;
  top: 0;
  bottom: 0;
  width: 140px;
  background: var(--primary-gradient);
  display: flex;
  flex-direction: column;
  z-index: 100;
  box-shadow: var(--shadow-md);
}

.sidebar-logo {
  padding: 12px 10px;
  display: flex;
  align-items: center;
  gap: 6px;
  color: #fff;
  font-size: 13px;
  font-weight: 600;
  border-bottom: 1px solid rgba(255,255,255,0.15);
}

.logo-icon {
  font-size: 18px;
}

.sidebar-nav {
  flex: 1;
  padding: 8px 6px;
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.sidebar-nav .nav-item {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 10px;
  border-radius: var(--radius-sm);
  color: rgba(255,255,255,0.85);
  text-decoration: none;
  font-size: 12px;
  transition: background 0.2s;
}

.sidebar-nav .nav-item:hover {
  background: rgba(255,255,255,0.15);
  color: #fff;
}

.sidebar-nav .nav-item.router-link-active {
  background: rgba(255,255,255,0.2);
  color: #fff;
  font-weight: 500;
}

.nav-icon {
  font-size: 15px;
  width: 20px;
  text-align: center;
  flex-shrink: 0;
}

.sidebar-footer {
  padding: 8px 6px;
  border-top: 1px solid rgba(255,255,255,0.15);
}

.sidebar-footer .nav-logout {
  width: 100%;
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 8px 10px;
  border-radius: var(--radius-sm);
  background: rgba(255,255,255,0.1);
  color: #fff;
  border: none;
  font-size: 12px;
  cursor: pointer;
  transition: background 0.2s;
}

.sidebar-footer .nav-logout:hover {
  background: rgba(255,255,255,0.2);
}

.main-content {
  flex: 1;
  min-height: 100vh;
  display: flex;
  flex-direction: column;
}

.main-content.with-sidebar {
  margin-left: 140px;
}

/* 手机端：侧边栏缩小 */
@media (max-width: 480px) {
  .admin-sidebar {
    width: 48px;
  }
  .main-content.with-sidebar {
    margin-left: 48px;
  }
  .sidebar-logo .logo-text,
  .sidebar-nav .nav-label,
  .sidebar-footer .nav-label {
    display: none;
  }
  .sidebar-nav .nav-item {
    justify-content: center;
    padding: 8px;
  }
  .sidebar-footer .nav-logout {
    justify-content: center;
    padding: 8px;
  }
}
</style>
