<template>
  <div id="app-root">
    <router-view />
  </div>
</template>

<script setup>
import { ref, provide, onMounted } from 'vue'
import { supabase } from './lib/supabase'

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
</script>
