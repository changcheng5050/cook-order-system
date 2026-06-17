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
        <button class="btn-batch" @click="toggleBatch">{{ batchMode ? '取消' : '批量删除' }}</button>
        <button v-if="notificationPermission !== 'granted'" class="btn-notify" @click="requestNotificationPermission">🔔 开启通知</button>
        <span v-else class="notify-active">🔔 通知已开启</span>
        <span class="version-badge">v2.2.4</span>
      </div>
    </header>

    <!-- 筛选 -->
    <div class="toolbar">
      <input v-model="searchName" placeholder="搜索客户姓名" class="search-input" />
      <select v-model="customerFilter" class="filter-select">
        <option value="">全部客户</option>
        <option v-for="name in customerOptions" :key="name" :value="name">{{ name }}</option>
      </select>
      <input v-model="dateFilter" type="date" class="date-input" />
      <button v-if="dateFilter || customerFilter" @click="clearFilters" class="btn-clear">清除筛选</button>
    </div>

    <div v-if="filteredOrders.length === 0" class="empty-tip">暂无订单</div>

    <div v-else class="order-list">
      <div v-for="order in filteredOrders" :key="order.id" class="order-card">
        <!-- 批量模式：复选框 -->
        <input v-if="batchMode" type="checkbox" class="order-checkbox"
          :checked="selectedOrders.includes(order.id)"
          @click.stop
          @change="toggleSelectOrder(order.id)" />
        <div class="order-header" @click="batchMode ? toggleSelectOrder(order.id) : toggleOrder(order.id)">
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
            <img v-if="d.image_url" :src="d.image_url" class="admin-detail-dish-img" @error="$event.target.style.display='none';$event.target.nextElementSibling.style.display='flex'" />
            <div v-else class="admin-dish-img-ph">🍽️</div>
            <div class="detail-dish-text">
              <span v-if="d.category" :class="['detail-cat-tag', 'cat-' + d.category]">{{ d.category }}</span>
              <strong>{{ d.name }}</strong>（{{ d.cook_time }}分钟）
              <span v-if="d.customer_note" class="detail-note">{{ d.customer_note }}</span>
            </div>
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

    <!-- 批量删除操作栏 -->
    <div v-if="batchMode && selectedOrders.length > 0" class="batch-bar">
      <span class="batch-count">已选 {{ selectedOrders.length }} 个订单</span>
      <button class="btn-batch-delete" @click="batchDelete">删除选中</button>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { supabase } from '../lib/supabase'
import { useRouter } from 'vue-router'

const router = useRouter()
const orders = ref([])
const searchName = ref('')
const dateFilter = ref('')
const customerFilter = ref('')  // 当前选中的客户名
const customerOptions = ref([]) // 所有客户名列表
const expandedOrder = ref(null)
const batchMode = ref(false)       // 是否批量模式
const selectedOrders = ref([])     // 选中的订单ID列表
const notificationPermission = ref('default')  // 通知权限状态
const lastOrderCount = ref(0)       // 上次检查的订单数量
let orderCheckTimer = null          // 轮询定时器

const filteredOrders = computed(() => {
  let list = orders.value
  if (searchName.value) {
    list = list.filter(o => o.customer_name.includes(searchName.value.trim()))
  }
  // 按客户名下拉筛选
  if (customerFilter.value) {
    list = list.filter(o => o.customer_name === customerFilter.value)
  }
  if (dateFilter.value) {
    list = list.filter(o => o.created_at.startsWith(dateFilter.value))
  }
  return list
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
  // 查所有客户，做 name -> info 映射
  const { data: custData } = await supabase
    .from('customers')
    .select('name, phone, address')
  const custMap = {}
  ;(custData || []).forEach(c => {
    custMap[c.name] = { phone: c.phone || '', address: c.address || '' }
  })
  // 收集需要补全的 dish id
  const needIds = new Set()
  ;(orderData || []).forEach(o => {
    ;(o.dishes || []).forEach(d => {
      if (!d.image_url || !d.category) needIds.add(d.id)
    })
  })
  // 查 dishes 表补全图片和分类
  let dishMap = {}
  if (needIds.size > 0) {
    const { data: dishData } = await supabase
      .from('dishes')
      .select('id, image_url, category')
      .in('id', Array.from(needIds))
    ;(dishData || []).forEach(d => { dishMap[d.id] = d })
  }
  // 合并客户信息 + 补全菜品数据
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
  // 收集所有不重复的客户名
  const nameSet = new Set()
  ;(orderData || []).forEach(o => { if (o.customer_name) nameSet.add(o.customer_name) })
  customerOptions.value = Array.from(nameSet).sort()
}

function toggleOrder(id) {
  expandedOrder.value = expandedOrder.value === id ? null : id
}

function toggleBatch() {
  batchMode.value = !batchMode.value
  selectedOrders.value = []   // 退出/进入时清空选择
  expandedOrder.value = null  // 关闭已展开的详情
}

function toggleSelectOrder(id) {
  const idx = selectedOrders.value.indexOf(id)
  if (idx === -1) {
    selectedOrders.value.push(id)
  } else {
    selectedOrders.value.splice(idx, 1)
  }
}

// 清除所有筛选条件
function clearFilters() {
  searchName.value = ''
  customerFilter.value = ''
  dateFilter.value = ''
}

async function batchDelete() {
  if (selectedOrders.value.length === 0) return
  if (!confirm(`确定要删除选中的 ${selectedOrders.value.length} 个订单吗？删除后不可恢复。`)) return
  const { error } = await supabase.from('orders').delete().in('id', selectedOrders.value)
  if (error) {
    alert('批量删除失败：' + error.message)
    return
  }
  alert(`成功删除 ${selectedOrders.value.length} 个订单！`)
  orders.value = orders.value.filter(o => !selectedOrders.value.includes(o.id))
  selectedOrders.value = []
  batchMode.value = false
}

async function deleteOrder(id) {
  if (!confirm('确定要删除这个订单吗？删除后不可恢复。')) return
  const { error } = await supabase.from('orders').delete().eq('id', id)
  if (error) {
    alert('删除失败：' + error.message + '\n\n请确认 Supabase 后台已开启 orders 表的 DELETE 权限（在 Authentication → Policies 中添加删除策略）')
    return
  }
  alert('删除成功！')
  orders.value = orders.value.filter(o => o.id !== id)
  expandedOrder.value = null
}

// ===== 浏览器通知功能 =====
async function requestNotificationPermission() {
  if (!('Notification' in window)) {
    alert('此浏览器不支持通知功能')
    return
  }
  console.log('当前通知权限状态：', Notification.permission)
  if (Notification.permission === 'granted') {
    notificationPermission.value = 'granted'
    // 立即发送一条测试通知
    new Notification('🔔 通知已开启', { body: '阿旺小厨房将在收到新订单时通知您' })
    return
  }
  if (Notification.permission === 'denied') {
    notificationPermission.value = 'denied'
    alert('通知权限被拒绝。请在浏览器地址栏左侧的锁形图标中重新开启通知权限。')
    return
  }
  // default 状态：用户点击触发，可以请求
  try {
    const result = await Notification.requestPermission()
    console.log('请求通知权限结果：', result)
    notificationPermission.value = result
    if (result === 'granted') {
      new Notification('🔔 通知已开启', { body: '阿旺小厨房将在收到新订单时通知您' })
      // 授权后立即检查一次
      checkNewOrders()
    } else {
      alert('通知权限未授予，无法接收新订单通知。')
    }
  } catch (e) {
    console.log('请求通知权限失败', e)
    alert('请求通知权限失败：' + e.message)
  }
}

// 检查新订单并发送通知
async function checkNewOrders() {
  try {
    const { data, error } = await supabase
      .from('orders')
      .select('id, customer_name, dishes, created_at')
      .order('created_at', { ascending: false })
    if (error || !data) {
      console.log('查询订单失败', error)
      return
    }
    const currentCount = data.length
    console.log(`[通知检查] 上次: ${lastOrderCount.value}, 当前: ${currentCount}`)
    if (lastOrderCount.value > 0 && currentCount > lastOrderCount.value) {
      // 有新订单！
      const newOrders = data.slice(0, currentCount - lastOrderCount.value)
      console.log(`[通知检查] 发现 ${newOrders.length} 个新订单`)
      newOrders.forEach(order => {
        if (Notification.permission === 'granted') {
          try {
            new Notification('🔔 新订单来了！', {
              body: `${order.customer_name} 点了 ${order.dishes.length} 道菜`,
              tag: order.id
            })
            console.log('已发送通知：', order.customer_name)
          } catch (e) {
            console.log('发送通知失败', e)
          }
        } else {
          console.log('通知权限未授予，跳过')
        }
      })
    }
    lastOrderCount.value = currentCount
  } catch (e) {
    console.log('检查新订单失败', e)
  }
}

onMounted(() => {
  checkAuth()
  loadOrders()
  // 初始化通知权限状态（不自动请求）
  if ('Notification' in window) {
    notificationPermission.value = Notification.permission
  }
  // 3秒后做首次检查（避开 loadOrders 加载时间）
  setTimeout(() => {
    checkNewOrders()
  }, 3000)
  // 每15秒检查一次新订单
  orderCheckTimer = setInterval(checkNewOrders, 15000)
})

onUnmounted(() => {
  if (orderCheckTimer) clearInterval(orderCheckTimer)
})

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
.header-actions { display: flex; gap: 6px; align-items: center; flex-wrap: wrap; }
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
.header-actions .btn-notify {
  padding: 4px 10px; border-radius: 6px; font-size: 12px;
  color: #fff; background: rgba(255,200,0,0.4); border: none;
  white-space: nowrap; cursor: pointer;
}
.header-actions .notify-active {
  font-size: 11px; color: rgba(255,255,255,0.8);
  background: rgba(0,0,0,0.18); padding: 2px 8px; border-radius: 10px;
  white-space: nowrap;
}
.header-actions .btn-batch {
  padding: 4px 10px; border-radius: 6px; font-size: 12px;
  color: #fff; background: rgba(255,255,255,0.2); border: none;
  white-space: nowrap;
}
.header-actions .btn-batch:hover { background: rgba(255,255,255,0.35); }

.toolbar {
  display: flex; gap: 8px; padding: 10px 16px; background: #fff;
  border-bottom: 1px solid var(--border); align-items: center; flex-wrap: wrap;
}
.search-input {
  flex: 1; min-width: 120px; padding: 6px 10px; border: 1px solid #ddd;
  border-radius: 8px; font-size: 13px;
}
.filter-select {
  padding: 6px 8px; border: 1px solid #ddd; border-radius: 8px; font-size: 13px;
  min-width: 100px;
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

.order-checkbox {
  width: 18px; height: 18px; flex-shrink: 0;
  accent-color: var(--primary);
  cursor: pointer;
  margin-right: 6px;
}

.batch-bar {
  position: fixed; bottom: 0; left: 0; right: 0;
  max-width: 480px; margin: 0 auto;
  background: #fff; border-top: 1px solid var(--border);
  padding: 10px 16px;
  display: flex; justify-content: space-between; align-items: center;
  box-shadow: 0 -2px 8px rgba(0,0,0,0.08);
  z-index: 100;
}
.batch-count { font-size: 13px; color: var(--text-secondary); }
.btn-batch-delete {
  padding: 8px 20px; border-radius: 8px;
  background: #ff4d4f; color: #fff;
  border: none; font-size: 14px; font-weight: 500;
  cursor: pointer;
}
.btn-batch-delete:hover { background: #cf1322; }
</style>
