<template>
  <div class="admin-page">
    <header class="admin-header">
      <h1>客户订单</h1>
      <div class="header-actions">
        <button class="btn-nav" @click="$router.push('/admin/dishes')">菜品</button>
        <button class="btn-nav" @click="$router.push('/admin/customers')">客户</button>
        <button class="btn-nav active-nav" @click="$router.push('/admin/orders')">订单</button>
        <button class="btn-settings" @click="$router.push('/admin/settings')">设置</button>
        <button class="btn-logout" @click="logout">退出</button>
      </div>
    </header>

    <!-- 筛选 -->
    <div class="toolbar">
      <input v-model="searchName" placeholder="搜索客户姓名" class="search-input" />
      <input v-model="dateFilter" type="date" class="date-input" />
      <button v-if="dateFilter" @click="dateFilter = ''" class="btn-clear">清除日期</button>
    </div>

    <div v-if="filteredOrders.length === 0" class="empty-tip">暂无订单</div>

    <div v-else class="order-list">
      <div v-for="order in filteredOrders" :key="order.id" class="order-card">
        <div class="order-header" @click="toggleOrder(order.id)">
          <span class="order-name">{{ order.customer_name }}</span>
          <span v-if="order.customer_phone" class="order-phone">{{ order.customer_phone }}</span>
          <span class="order-date">{{ formatDate(order.created_at) }}</span>
          <span v-if="order.expected_time" class="expected-badge">{{ formatDateTime(order.expected_time) }}</span>
          <span class="order-arrow">{{ expandedOrder === order.id ? '▲' : '▼' }}</span>
        </div>
        <div class="order-summary">
          共 {{ order.dishes.length }} 道菜，约 {{ order.total_time }} 分钟
        </div>

        <!-- 展开详情 -->
        <div v-if="expandedOrder === order.id" class="order-detail">
          <p v-if="order.customer_phone" class="customer-info">手机号：{{ order.customer_phone }}</p>
          <p v-if="order.customer_address" class="customer-info">地址：{{ order.customer_address }}</p>
          <h4>菜品：</h4>
          <div v-for="d in order.dishes" :key="d.id" class="detail-row">
            <span v-if="d.category" :class="['detail-cat-tag', 'cat-' + d.category]">{{ d.category }}</span>
            <span>{{ d.name }}（{{ d.cook_time }}分钟）</span>
            <span v-if="d.customer_note" class="detail-note">{{ d.customer_note }}</span>
          </div>

          <h4>食材汇总：</h4>
          <div v-for="(ing, idx) in getIngredients(order)" :key="idx" class="summary-row">
            <span>{{ ing.name }}</span><span>{{ ing.amount }}</span>
          </div>

          <h4>调料汇总：</h4>
          <div v-for="(s, idx) in getSeasonings(order)" :key="idx" class="summary-row">
            <span>{{ s.name }}</span><span>{{ s.amount }}</span>
          </div>

          <p v-if="order.note" class="order-note">订单备注：{{ order.note }}</p>

          <!-- 删除订单 -->
          <button class="btn-delete-order" @click.stop="deleteOrder(order.id)">删除此订单</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { supabase } from '../lib/supabase'
import { useRouter } from 'vue-router'

const router = useRouter()
const orders = ref([])
const searchName = ref('')
const dateFilter = ref('')
const expandedOrder = ref(null)

const filteredOrders = computed(() => {
  let list = orders.value
  if (searchName.value) {
    list = list.filter(o => o.customer_name.includes(searchName.value.trim()))
  }
  if (dateFilter.value) {
    list = list.filter(o => o.created_at.startsWith(dateFilter.value))
  }
  return list
})

onMounted(() => {
  checkAuth()
  loadOrders()
})

async function checkAuth() {
  const { data } = await supabase.auth.getSession()
  if (!data.session) router.push('/admin')
}

async function loadOrders() {
  const { data: orderData, error } = await supabase
    .from('orders')
    .select('*')
    .order('created_at', { ascending: false })
  if (error) return
  // 再查所有客户，做 name -> info 映射
  const { data: custData } = await supabase
    .from('customers')
    .select('name, phone, address')
  const custMap = {}
  ;(custData || []).forEach(c => {
    custMap[c.name] = { phone: c.phone || '', address: c.address || '' }
  })
  // 合并客户信息到订单
  orders.value = (orderData || []).map(o => ({
    ...o,
    customer_phone: custMap[o.customer_name]?.phone || '',
    customer_address: custMap[o.customer_name]?.address || ''
  }))
}

function toggleOrder(id) {
  expandedOrder.value = expandedOrder.value === id ? null : id
}

async function deleteOrder(id) {
  if (!confirm('确定要删除这个订单吗？删除后不可恢复。')) return
  const { error } = await supabase.from('orders').delete().eq('id', id)
  if (error) {
    alert('删除失败：' + error.message)
    return
  }
  orders.value = orders.value.filter(o => o.id !== id)
  expandedOrder.value = null
}

function formatDate(dateStr) {
  const d = new Date(dateStr)
  return `${d.getMonth()+1}月${d.getDate()}日 ${d.getHours()}:${String(d.getMinutes()).padStart(2,'0')}`
}

function formatDateTime(dt) {
  if (!dt) return ''
  const d = new Date(dt)
  return `${d.getMonth()+1}月${d.getDate()}日 ${d.getHours()}:${String(d.getMinutes()).padStart(2,'0')}`
}

function getIngredients(order) {
  const map = {}
  ;(order.dishes || []).forEach(item => {
    ;(item.ingredients || []).forEach(ing => {
      map[ing.name] = { name: ing.name, amount: ing.amount }
    })
  })
  return Object.values(map)
}

function getSeasonings(order) {
  const map = {}
  ;(order.dishes || []).forEach(item => {
    ;(item.seasonings || []).forEach(s => {
      map[s.name] = { name: s.name, amount: s.amount }
    })
  })
  return Object.values(map)
}

async function logout() {
  await supabase.auth.signOut()
  router.push('/admin')
}
</script>

<style scoped>
.admin-page { max-width: 480px; margin: 0 auto; padding-bottom: 20px; }

.admin-header {
  display: flex; justify-content: space-between; align-items: center;
  padding: 12px 16px; background: var(--primary); color: #fff;
}
.admin-header h1 { font-size: 16px; }
.header-actions { display: flex; gap: 6px; align-items: center; }
.header-actions button {
  padding: 4px 10px; border-radius: 6px; font-size: 12px;
  color: #fff; background: rgba(255,255,255,0.2); border: none;
}
.header-actions .btn-nav { background: rgba(255,255,255,0.18); }
.header-actions .btn-nav.active-nav { background: rgba(255,255,255,0.4); font-weight: 600; }
.header-actions .btn-settings { background: rgba(255,255,255,0.2); }
.header-actions .btn-logout {
  background: rgba(255,255,255,0.15); border: 1px solid rgba(255,255,255,0.3);
}

.toolbar {
  display: flex; gap: 8px; padding: 10px 16px; background: #fff;
  border-bottom: 1px solid var(--border); align-items: center; flex-wrap: wrap;
}
.search-input {
  flex: 1; min-width: 120px; padding: 6px 10px; border: 1px solid #ddd;
  border-radius: 8px; font-size: 13px;
}
.date-input {
  padding: 6px 8px; border: 1px solid #ddd; border-radius: 8px; font-size: 13px;
}
.btn-clear {
  font-size: 12px; color: var(--text-secondary); background: none;
}

.empty-tip { text-align: center; color: var(--text-secondary); padding: 40px 0; }

.order-list { padding: 12px; }
.order-card {
  background: #fff; border-radius: 12px; padding: 12px; margin-bottom: 10px;
}
.order-header {
  display: flex; gap: 10px; align-items: center; font-size: 13px;
  margin-bottom: 4px; flex-wrap: wrap; cursor: pointer;
}
.order-name { font-weight: 500; }
.order-phone { font-size: 12px; color: var(--text-secondary); }
.order-date { color: var(--text-secondary); font-size: 12px; }
.expected-badge {
  display: inline-block;
  font-size: 13px;
  font-weight: 500;
  color: #1b7e3e;
  background: linear-gradient(135deg, #e8f5e9, #f1f8e9);
  padding: 5px 12px;
  border-radius: 4px;
  border: 1.5px solid #a5d6a7;
  margin-left: 4px;
}
.order-arrow { margin-left: auto; color: #ccc; font-size: 10px; }
.order-summary { font-size: 12px; color: var(--text-secondary); }

.order-detail {
  margin-top: 10px; padding-top: 10px; border-top: 1px solid var(--border);
  font-size: 13px;
}
.order-detail h4 { font-size: 13px; margin: 8px 0 4px; color: var(--primary); }
.customer-info { font-size: 12px; color: var(--text-secondary); margin-bottom: 6px; }

.detail-row { padding: 4px 0; display: flex; align-items: center; gap: 6px; flex-wrap: wrap; }
.detail-cat-tag {
  font-size: 10px; padding: 1px 7px; border-radius: 4px;
  font-weight: 500; color: #fff; flex-shrink: 0;
}
.detail-cat-tag.cat-荤菜 { background: rgba(229,57,53,0.85); }
.detail-cat-tag.cat-素菜 { background: rgba(67,160,71,0.85); }
.detail-cat-tag.cat-汤类 { background: rgba(30,136,229,0.85); }
.detail-cat-tag.cat-粉面类 { background: rgba(245,124,0,0.85); }

.detail-note { font-size: 11px; color: #e55a2b; margin-left: 4px; }

.summary-row {
  display: flex; justify-content: space-between; padding: 3px 0;
  border-bottom: 1px dashed #eee; font-size: 12px;
}
.order-note {
  margin-top: 8px; padding: 8px; background: #f9f9f9;
  border-radius: 6px; font-size: 12px; color: var(--text-secondary);
}

.btn-delete-order {
  display: inline-block;
  margin-top: 10px;
  padding: 5px 14px;
  border-radius: 6px;
  background: #fff2f0;
  color: #cf1322;
  border: 1px solid #ffccc7;
  font-size: 12px;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.15s;
}
.btn-delete-order:hover {
  background: #ffccc7;
  color: #a8071a;
}
</style>
