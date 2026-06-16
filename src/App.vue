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

const version = ref('v2.1.5')

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
