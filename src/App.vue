<template>
  <div id="app-root">
    <div class="main-content">
      <router-view />
    </div>
  </div>
</template>

<script setup>
import { ref, provide, onMounted } from 'vue'
import { supabase } from './lib/supabase'

const version = ref('v2.3.0')

const shopSettings = ref({
  shop_name: '阿旺小厨房',
  logo_url: '',
  announcement: '',
  announcement_enabled: false
})

async function loadSettings() {
  const { data } = await supabase.from('settings').select('*').single()
  if (data) {
    // 保留所有数据库返回的字段 + 默认值
    shopSettings.value = {
      shop_name: data.shop_name || '阿旺小厨房',
      logo_url: data.logo_url || '',
      announcement: data.announcement || '',
      announcement_enabled: data.announcement_enabled || false,
      tab_menu_enabled: data.tab_menu_enabled !== false,
      tab_history_enabled: data.tab_history_enabled !== false,
      tab_roll_enabled: data.tab_roll_enabled !== false,
      tab_note_enabled: data.tab_note_enabled !== false
    }
    // 动态设置浏览器图标和标题
    if (data.logo_url) {
      const favicon = document.getElementById('dynamic-favicon')
      const appleIcon = document.getElementById('dynamic-apple-icon')
      if (favicon) favicon.href = data.logo_url
      if (appleIcon) appleIcon.href = data.logo_url
    }
    if (data.shop_name) {
      document.title = data.shop_name
    }
  }
}

onMounted(() => {
  loadSettings()
})

provide('shopSettings', shopSettings)
</script>

<style scoped>
#app-root {
  min-height: 100vh;
}
.main-content {
  min-height: 100vh;
}
</style>
