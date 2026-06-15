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
  </div>
</template>

<script setup>
import { ref, provide, onMounted, computed } from 'vue'
import { useRoute } from 'vue-router'
import { supabase } from './lib/supabase'

const route = useRoute()
const isAdminPage = computed(() => route.path.startsWith('/admin'))

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
