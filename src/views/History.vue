<template>
  <div class="history-page">
    <header class="top-bar">
      <img v-if="settings.logo_url" :src="settings.logo_url" class="logo" />
      <h1>{{ settings.shop_name }}</h1>
    </header>

    <!-- 瀹㈡埛濮撳悕杈撳叆锛堢櫧鍚嶅崟楠岃瘉锛?-->
    <div v-if="!customerName" class="name-section">
      <input v-model="nameInput" placeholder="璇疯緭鍏ユ偍鐨勫鍚? @keyup.enter="verifyName" />
      <p v-if="nameError" class="name-error">{{ nameError }}</p>
      <button @click="verifyName">鏌ョ湅鍘嗗彶</button>
    </div>

    <div v-else>
      <div class="page-title">
        <h2>鎴戠殑鍘嗗彶璁㈠崟</h2>
        <button class="btn-back" @click="$router.push('/')">鈫?杩斿洖鐐归</button>
      </div>

      <div v-if="orders.length === 0" class="empty">
        <p>杩樻病鏈夎鍗曡褰?/p>
        <button @click="$router.push('/')">鍘荤偣椁?/button>
      </div>

      <div v-else class="order-list">
        <div v-for="order in orders" :key="order.id" class="order-card" @click="toggleOrder(order.id)">
          <div class="order-header">
            <span class="order-date">{{ formatDate(order.created_at) }}</span>
            <span v-if="order.expected_time" class="order-time">馃晲 {{ formatDateTime(order.expected_time) }}</span>
            <span class="order-duration">绾?{{ order.total_time }} 鍒嗛挓</span>
            <span class="order-arrow">{{ expandedOrder === order.id ? '鈻? : '鈻? }}</span>
          </div>
          <div class="order-dishes-summary">
            {{ order.dishes.map(d => d.name).join('銆?) }}
          </div>

          <!-- 灞曞紑璇︽儏 -->
          <div v-if="expandedOrder === order.id" class="order-detail">
            <h4>鑿滃搧璇︽儏锛?/h4>
            <div v-for="d in order.dishes" :key="d.id" class="detail-dish">
              <span>{{ d.name }}</span>
              <span v-if="d.customer_note" class="detail-note">澶囨敞锛歿{ d.customer_note }}</span>
            </div>

            <!-- 椋熸潗姹囨€?-->
            <h4>椋熸潗姹囨€伙細</h4>
            <div v-for="(ing, idx) in getOrderIngredients(order)" :key="idx" class="detail-row">
              <span>{{ ing.name }}</span>
              <span>{{ ing.amount }}</span>
            </div>

            <!-- 璋冩枡姹囨€?-->
            <h4>璋冩枡姹囨€伙細</h4>
            <div v-for="(s, idx) in getOrderSeasonings(order)" :key="idx" class="detail-row">
              <span>{{ s.name }}</span>
              <span>{{ s.amount }}</span>
            </div>

            <p v-if="order.note" class="order-note">璁㈠崟澶囨敞锛歿{ order.note }}</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, inject } from 'vue'
import { supabase } from '../lib/supabase'

const settings = inject('shopSettings')
const customerName = ref('')
const nameInput = ref('')
const nameError = ref('')
const orders = ref([])
const expandedOrder = ref(null)

onMounted(() => {
  const params = new URLSearchParams(window.location.search)
  const urlName = params.get('customer')
  const saved = localStorage.getItem('cook_customer_name')
  if (urlName) {
    customerName.value = urlName
    localStorage.setItem('cook_customer_name', urlName)
    verifyAndLoad(urlName)
  } else if (saved) {
    customerName.value = saved
    verifyAndLoad(saved)
  }
})

async function verifyName() {
  const name = nameInput.value.trim()
  if (!name) return
  await verifyAndLoad(name)
}

async function verifyAndLoad(name) {
  // 鍏堥獙璇佹槸鍚﹀湪鐧藉悕鍗?  const { data, error } = await supabase
    .from('customers')
    .select('name')
    .eq('name', name)
    .single()
  if (error || !data) {
    nameError.value = '濮撳悕涓嶅瓨鍦紝璇疯仈绯诲帹甯?
    customerName.value = ''
    localStorage.removeItem('cook_customer_name')
    return
  }
  customerName.value = name
  localStorage.setItem('cook_customer_name', name)
  nameError.value = ''
  loadOrders()
}

async function loadOrders() {
  const { data, error } = await supabase
    .from('orders')
    .select('*')
    .eq('customer_name', customerName.value)
    .order('created_at', { ascending: false })
  if (!error) orders.value = data || []
}

function toggleOrder(id) {
  expandedOrder.value = expandedOrder.value === id ? null : id
}

function formatDate(dateStr) {
  const d = new Date(dateStr)
  return `${d.getMonth()+1}鏈?{d.getDate()}鏃?${d.getHours()}:${String(d.getMinutes()).padStart(2,'0')}`
}

function formatDateTime(dt) {
  if (!dt) return ''
  const d = new Date(dt)
  return `${d.getMonth()+1}鏈?{d.getDate()}鏃?${d.getHours()}:${String(d.getMinutes()).padStart(2,'0')}`
}

function getOrderIngredients(order) {
  const map = {}
  ;(order.dishes || []).forEach(item => {
    ;(item.ingredients || []).forEach(ing => {
      if (map[ing.name]) {
        map[ing.name].amount += ' + ' + ing.amount
      } else {
        map[ing.name] = { name: ing.name, amount: ing.amount }
      }
    })
  })
  return Object.values(map)
}

function getOrderSeasonings(order) {
  const map = {}
  ;(order.dishes || []).forEach(item => {
    ;(item.seasonings || []).forEach(s => {
      if (map[s.name]) {
        map[s.name].amount += ' + ' + s.amount
      } else {
        map[s.name] = { name: s.name, amount: s.amount }
      }
    })
  })
  return Object.values(map)
}
</script>

<style scoped>
.history-page { max-width: 480px; margin: 0 auto; padding-bottom: 20px; }

.top-bar {
  display: flex; align-items: center; gap: 10px;
  padding: 12px 16px; background: var(--primary); color: #fff;
}
.top-bar .logo { width: 36px; height: 36px; border-radius: 50%; object-fit: cover; }
.top-bar h1 { font-size: 18px; font-weight: 600; }

.name-section {
  padding: 40px 16px; text-align: center;
}
.name-section input {
  width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 8px;
  margin-bottom: 8px;
}
.name-error { color: #e55a2b; font-size: 12px; margin-bottom: 8px; }
.name-section button {
  width: 100%; padding: 10px; background: var(--primary); color: #fff;
  border-radius: 8px;
}

.page-title {
  display: flex; justify-content: space-between; align-items: center;
  padding: 12px 16px;
}
.page-title h2 { font-size: 16px; }
.btn-back {
  font-size: 13px; color: var(--primary); background: none;
}

.empty { text-align: center; padding: 40px 0; color: var(--text-secondary); }
.empty button {
  margin-top: 12px; padding: 8px 20px; background: var(--primary);
  color: #fff; border-radius: 8px;
}

.order-list { padding: 0 12px; }
.order-card {
  background: #fff; border-radius: 12px; padding: 12px; margin-bottom: 10px;
  cursor: pointer;
}
.order-header {
  display: flex; gap: 12px; align-items: center; font-size: 13px;
  margin-bottom: 6px; flex-wrap: wrap;
}
.order-date { font-weight: 500; }
.order-time { color: var(--text-secondary); }
.order-duration { color: var(--primary); font-weight: 500; }
.order-arrow { margin-left: auto; color: #ccc; font-size: 10px; }
.order-dishes-summary {
  font-size: 13px; color: var(--text-secondary);
  white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
}

.order-detail {
  margin-top: 10px; padding-top: 10px; border-top: 1px solid var(--border);
  font-size: 13px;
}
.order-detail h4 { font-size: 13px; margin: 8px 0 4px; color: var(--primary); }
.detail-dish {
  display: flex; justify-content: space-between; padding: 4px 0;
}
.detail-note { font-size: 11px; color: #e55a2b; }
.detail-row {
  display: flex; justify-content: space-between; padding: 3px 0;
  border-bottom: 1px dashed #eee; font-size: 12px;
}
.order-note {
  margin-top: 8px; padding: 8px; background: #f9f9f9;
  border-radius: 6px; font-size: 12px; color: var(--text-secondary);
}
</style>
