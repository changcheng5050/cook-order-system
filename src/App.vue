<template>
  <div id="app-root">
    <!-- 管理员侧边导航（仅管理员页面显示） -->
    <nav v-if="isAdminPage" class="admin-nav">
      <router-link to="/admin/dishes" class="nav-item">🍳 菜品管理</router-link>
      <router-link to="/admin/customers" class="nav-item">👥 客户管理</router-link>
      <router-link to="/admin/orders" class="nav-item">📋 订单查看</router-link>
      <router-link to="/admin/settings" class="nav-item">⚙️ 系统设置</router-link>
      <button class="nav-logout" @click="logout">退出登录</button>
    </nav>
    <router-view />
    <!-- 版本号（所有页面底部显示） -->
    <div class="version-footer">
      v{{ version }}
    </div>
  </div>
</template>

<script setup>
import { ref, provide, onMounted, computed } from 'vue'
import { useRoute } from 'vue-router'
import { supabase } from './lib/supabase'

const route = useRoute()
const isAdminPage = computed(() => route.path.startsWith('/admin'))

const version = ref('v1.2.0')

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
  window.location.href = '/admin'
}
</script>

<style scoped>
#app-root {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
}

.version-footer {
  text-align: center;
  font-size: 11px;
  color: #bbb;
  padding: 12px 0 8px;
  margin-top: auto;
}

.admin-nav {
  background: var(--primary, #e55a2b);
  padding: 10px 16px;
  display: flex;
  gap: 6px;
  flex-wrap: wrap;
  align-items: center;
}

.admin-nav .nav-item {
  color: #fff;
  text-decoration: none;
  padding: 6px 12px;
  border-radius: 6px;
  font-size: 13px;
  opacity: 0.85;
}

.admin-nav .nav-item:hover,
.admin-nav .nav-item.router-link-active {
  opacity: 1;
  background: rgba(255,255,255,0.18);
}

.admin-nav .nav-logout {
  margin-left: auto;
  background: rgba(255,255,255,0.18);
  color: #fff;
  border: none;
  padding: 6px 14px;
  border-radius: 6px;
  font-size: 13px;
  cursor: pointer;
}
</style>
