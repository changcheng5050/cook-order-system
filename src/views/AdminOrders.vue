<template>
  <div class="admin-page">
    <header class="admin-header">
      <h1>瀹㈡埛璁㈠崟</h1>
      <div class="header-actions">
        <button class="btn-nav" @click="$router.push('/admin/dishes')">鑿滃搧</button>
        <button class="btn-nav" @click="$router.push('/admin/customers')">瀹㈡埛</button>
        <button class="btn-nav active-nav" @click="$router.push('/admin/orders')">璁㈠崟</button>
        <button class="btn-settings" @click="$router.push('/admin/settings')">璁剧疆</button>
        <button class="btn-logout" @click="logout">閫€鍑?/button>
        <span class="version-badge">v2.0.25</span>
      </div>
    </header>

    <!-- 绛涢€?-->
    <div class="toolbar">
      <input v-model="searchName" placeholder="鎼滅储瀹㈡埛濮撳悕" class="search-input" />
      <input v-model="dateFilter" type="date" class="date-input" />
      <button v-if="dateFilter" @click="dateFilter = ''" class="btn-clear">娓呴櫎鏃ユ湡</button>
    </div>

    <div v-if="filteredOrders.length === 0" class="empty-tip">鏆傛棤璁㈠崟</div>

    <div v-else class="order-list">
      <div v-for="order in filteredOrders" :key="order.id" class="order-card">
        <div class="order-header" @click="toggleOrder(order.id)">
          <span class="order-name">{{ order.customer_name }}</span>
          <span v-if="order.customer_phone" class="order-phone">{{ order.customer_phone }}</span>
          <span class="order-date">{{ formatDate(order.created_at) }}</span>
          <span v-if="order.expected_time" class="expected-badge">{{ formatDateTime(order.expected_time) }}</span>
          <span class="order-arrow">{{ expandedOrder === order.id ? '鈻? : '鈻? }}</span>
        </div>
        <div class="order-summary">
          鍏?{{ order.dishes.length }} 閬撹彍锛岀害 {{ order.total_time }} 鍒嗛挓
        </div>

        <!-- 灞曞紑璇︽儏 -->
        <div v-if="expandedOrder === order.id" class="order-detail">
          <p v-if="order.customer_phone" class="customer-info">鎵嬫満鍙凤細{{ order.customer_phone }}</p>
          <p v-if="order.customer_address" class="customer-info">鍦板潃锛歿{ order.customer_address }}</p>
          <h4>鑿滃搧锛?/h4>
          <div v-for="d in order.dishes" :key="d.id" class="detail-row">
            <img v-if="d.image_url" :src="d.image_url" class="admin-detail-dish-img" @error="$event.target.style.display='none';$event.target.nextElementSibling.style.display='flex'" />
            <div v-else class="admin-dish-img-ph">馃嵔锔?/div>
            <div class="detail-dish-text">
              <span v-if="d.category" :class="['detail-cat-tag', 'cat-' + d.category]">{{ d.category }}</span>
              <strong>{{ d.name }}</strong>锛坽{ d.cook_time }}鍒嗛挓锛?              <span v-if="d.customer_note" class="detail-note">{{ d.customer_note }}</span>
            </div>
          </div>

          <h4>椋熸潗姹囨€伙細</h4>
          <div v-for="(ing, idx) in getIngredients(order)" :key="idx" class="summary-row">
            <span>{{ ing.name }}</span><span>{{ ing.amount }}</span>
          </div>

          <h4>璋冩枡姹囨€伙細</h4>
          <div v-for="(s, idx) in getSeasonings(order)" :key="idx" class="summary-row">
            <span>{{ s.name }}</span><span>{{ s.amount }}</span>
          </div>

          <p v-if="order.note" class="order-note">璁㈠崟澶囨敞锛歿{ order.note }}</p>

          <!-- 鍒犻櫎璁㈠崟 -->
          <button class="btn-delete-order" @click.stop="deleteOrder(order.id)">鍒犻櫎姝よ鍗?/button>
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
  // 鏌ユ墍鏈夊鎴凤紝鍋?name -> info 鏄犲皠
  const { data: custData } = await supabase
    .from('customers')
    .select('name, phone, address')
  const custMap = {}
  ;(custData || []).forEach(c => {
    custMap[c.name] = { phone: c.phone || '', address: c.address || '' }
  })
  // 鏀堕泦闇€瑕佽ˉ鍏ㄧ殑 dish id
  const needIds = new Set()
  ;(orderData || []).forEach(o => {
    ;(o.dishes || []).forEach(d => {
      if (!d.image_url || !d.category) needIds.add(d.id)
    })
  })
  // 鏌?dishes 琛ㄨˉ鍏ㄥ浘鐗囧拰鍒嗙被
  let dishMap = {}
  if (needIds.size > 0) {
    const { data: dishData } = await supabase
      .from('dishes')
      .select('id, image_url, category')
      .in('id', Array.from(needIds))
    ;(dishData || []).forEach(d => { dishMap[d.id] = d })
  }
  // 鍚堝苟瀹㈡埛淇℃伅 + 琛ュ叏鑿滃搧鏁版嵁
  orders.value = (orderData || []).map(o => ({
    ...o,
    customer_phone: custMap[o.customer_name]?.phone || '',
    customer_address: custMap[o.customer_name]?.address || '',
    dishes: (o.dishes || []).map(d => {
      const fullDish = dishMap[d.id]
      return {
        ...d,
        image_url: d.image_url || (fullDish ? fullDish.image_url : ''),
        category: d.category || (fullDish ? fullDish.category : '')
      }
    })
  }))
}

function toggleOrder(id) {
  expandedOrder.value = expandedOrder.value === id ? null : id
}

async function deleteOrder(id) {
  if (!confirm('纭畾瑕佸垹闄よ繖涓鍗曞悧锛熷垹闄ゅ悗涓嶅彲鎭㈠銆?)) return
  const { error } = await supabase.from('orders').delete().eq('id', id)
  if (error) {
    alert('鍒犻櫎澶辫触锛? + error.message)
    return
  }
  orders.value = orders.value.filter(o => o.id !== id)
  expandedOrder.value = null
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
.header-actions .version-badge {
  font-size: 11px; color: rgba(255,255,255,0.7);
  background: rgba(0,0,0,0.18); padding: 2px 8px; border-radius: 10px;
  white-space: nowrap; margin-left: 4px;
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

.detail-row { padding: 5px 0; display: flex; align-items: flex-start; gap: 8px; flex-wrap: wrap; }
.admin-detail-dish-img { width: 44px; height: 44px; border-radius: 8px; object-fit: cover; flex-shrink: 0; }
.admin-dish-img-ph {
  width: 44px; height: 44px; border-radius: 8px;
  background: linear-gradient(135deg,#f5f5f0,#e8e8e0);
  display: flex; align-items: center; justify-content: center;
  font-size: 18px; flex-shrink: 0;
}
.detail-dish-text { flex: 1; min-width: 0; display: flex; align-items: center; gap: 4px; flex-wrap: wrap; }
.detail-cat-tag {
  font-size: 10px; padding: 1px 7px; border-radius: 4px;
  font-weight: 500; color: #fff; flex-shrink: 0;
}
.detail-cat-tag.cat-鑽よ彍 { background: rgba(229,57,53,0.85); }
.detail-cat-tag.cat-绱犺彍 { background: rgba(67,160,71,0.85); }
.detail-cat-tag.cat-姹ょ被 { background: rgba(30,136,229,0.85); }
.detail-cat-tag.cat-绮夐潰绫?{ background: rgba(245,124,0,0.85); }

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
