<template>
  <div class="menu-page">
    <!-- 顶部标题栏 -->
    <header class="top-bar">
      <img v-if="settings.logo_url" :src="settings.logo_url" class="logo" @error="onLogoError" />
      <div v-else class="logo-default">🍳</div>
      <h1>{{ settings.shop_name }}</h1>
      <span class="version-in-header">{{ version }}</span>
    </header>

        <div v-if="!customerName || showSuccess" class="name-modal">
          <div class="name-box">
            <h2>🍳 {{ settings.shop_name }}</h2>
            <p class="welcome-text">欢迎光临，请输入您的姓名</p>
            <input v-model="nameInput" placeholder="请输入姓名" @keyup.enter="verifyName" />
            <div v-if="nameError" class="name-error">{{ nameError }}</div>
            <button @click="verifyName">进入菜单</button>
            <p class="version-text">v{{ version }}</p>
          </div>
        </div>

    <!-- 登录后的页签导航 + 退出登录 -->
    <nav v-if="customerName && !showSuccess" class="tab-nav">
      <div class="tab-group">
        <button
          :class="['tab-btn', { active: currentTab === 'menu' }]"
          @click="currentTab = 'menu'"
        >🍽️ 点菜</button>
        <button
          :class="['tab-btn', { active: currentTab === 'history' }]"
          @click="currentTab = 'history'"
        >📋 历史订单</button>
      </div>
      <button class="logout-btn" @click="doLogout">退出登录</button>
    </nav>

    <!-- ========== 点菜页签 ========== -->
    <div v-if="customerName && currentTab === 'menu'">
      <!-- 分类导航 -->
      <nav class="category-nav">
        <button
          v-for="cat in categories"
          :key="cat"
          :class="['cat-btn', 'cat-' + cat, { active: activeCategory === cat }]"
          @click="activeCategory = cat"
        >{{ cat }}</button>
      </nav>

      <!-- 菜品列表 -->
      <div class="dish-list">
        <div v-for="dish in filteredDishes" :key="dish.id" class="dish-card">
          <div class="dish-img" @click="showDishDetail(dish)">
            <img v-if="dish.image_url" :src="dish.image_url" />
            <div v-else class="img-placeholder">暂无图片</div>
            <span v-if="dish.category" :class="['cat-tag', 'cat-' + dish.category]">{{ dish.category }}</span>
          </div>
          <div class="dish-info">
            <h3>{{ dish.name }}</h3>
            <div class="flavor-tags">
              <span v-for="f in dish.flavor" :key="f" class="flavor-tag">{{ f }}</span>
            </div>
            <p class="cook-time">⏱ {{ dish.cook_time }}分钟</p>
            <p v-if="dish.notes" class="dish-notes">📝 {{ dish.notes }}</p>
          </div>
          <!-- 已添加：绿色对勾（点击移除）；未添加：橙色+号（点击添加） -->
          <button
            v-if="isInCart(dish.id)"
            class="add-btn checked-btn"
            @click="removeFromCart(dish.id)"
            title="点击从购物车移除"
          >✓</button>
          <button
            v-else
            class="add-btn"
            @click="addToCart(dish)"
          >+</button>
        </div>
      </div>

      <!-- 底部购物车栏 -->
      <div v-if="cartItems.length > 0" class="cart-bar" @click="showCart = true">
        <div class="cart-icon">
          🛒
          <span class="cart-count">{{ cartItems.length }}</span>
        </div>
        <div class="cart-info">
          <span>已选 {{ cartItems.length }} 道菜</span>
          <span>约 {{ getTotalTime() }} 分钟</span>
        </div>
        <button class="cart-submit" @click.stop="openCart">查看购物车</button>
      </div>
    </div>

    <!-- ========== 历史订单页签 ========== -->
    <div v-if="customerName && currentTab === 'history'" class="history-tab">
      <div class="history-header">
        <h2>我的历史订单</h2>
        <span class="history-name">{{ customerName }}</span>
      </div>
      <div v-if="orders.length === 0" class="empty-tip">
        还没有订单，去点餐吧 🍴
      </div>
      <div v-for="order in orders" :key="order.id" class="order-card" @click="toggleOrder(order.id)">
        <div class="order-header">
          <span class="order-date">{{ formatDate(order.created_at) }}</span>
          <span v-if="order.expected_time" class="expected-badge">⏰ 期望时间：{{ formatDateTime(order.expected_time) }}</span>
          <span class="order-arrow">{{ expandedOrderId === order.id ? '▲' : '▼' }}</span>
        </div>
        <div class="order-summary">
          {{ order.dishes.map(d => d.name).join('、') }}
        </div>
        <!-- 展开详情 -->
        <div v-if="expandedOrderId === order.id" class="order-detail">
          <p><strong>菜品：</strong></p>
          <div v-for="item in order.dishes" :key="item.id" class="detail-dish-item">
            <img v-if="item.image_url" :src="item.image_url" class="detail-dish-img" @error="$event.target.style.display='none'" />
            <div v-else class="detail-dish-ph">🍽️</div>
            <div class="detail-dish-info">
              <div class="detail-dish-name-row">
                <span v-if="item.category" :class="['detail-cat-tag', 'cat-' + item.category]">{{ item.category }}</span>
                <strong>{{ item.name }}</strong>
              </div>
              <span class="detail-cook-time">⏱ {{ item.cook_time }}分钟</span>
              <span v-if="item.customer_note" class="detail-note">（备注：{{ item.customer_note }}）</span>
            </div>
          </div>
          <p class="detail-total">共 {{ order.dishes.length }} 道菜，约 {{ order.total_time }} 分钟</p>
          <p v-if="order.note" class="detail-note-full">订单备注：{{ order.note }}</p>
          <h4>食材汇总</h4>
          <div v-for="(ing, idx) in getIngredients(order)" :key="'i'+idx" class="summary-row">
            <span>{{ ing.name }}</span><span>{{ ing.amount }}</span>
          </div>
          <h4>调料汇总</h4>
          <div v-for="(s, idx) in getSeasonings(order)" :key="'s'+idx" class="summary-row">
            <span>{{ s.name }}</span><span>{{ s.amount }}</span>
          </div>
        </div>
      </div>
    </div>

    <!-- 购物车弹窗 -->
    <div v-if="showCart" class="modal-mask" @click.self="showCart = false">
      <div class="modal-box cart-modal">
        <h2>我的购物车</h2>
        <div v-for="item in cartItems" :key="item.id" class="cart-item">
          <img v-if="item.image_url" :src="item.image_url" class="cart-item-img" />
          <div v-else class="cart-item-img-ph"></div>
          <div class="cart-item-info">
            <h4>
              <span v-if="item.category" :class="['detail-cat-tag', 'cat-' + item.category]">{{ item.category }}</span>
              {{ item.name }}
            </h4>
            <p class="cart-item-time">{{ item.cook_time }}分钟</p>
          </div>
          <input
            v-model="item.customer_note"
            placeholder="备注（如：不要葱姜）"
            class="cart-note-input"
          />
          <button class="remove-btn-circle" @click="removeFromCart(item.id)">−</button>
        </div>

        <!-- 期望用餐时间 -->
        <div class="expected-time-section">
          <label>期望用餐时间 <span class="required">*</span></label>
          <input type="datetime-local" v-model="expectedTime" class="time-input" required />
        </div>

        <!-- 订单整体备注 -->
        <div class="order-note-section">
          <label>订单备注（选填）</label>
          <textarea
            v-model="orderNote"
            placeholder="如：今天有老人，口味清淡些"
            class="order-note-input"
          ></textarea>
        </div>

        <!-- 食材汇总 -->
        <div v-if="allIngredients.length > 0" class="summary-section">
          <h3 @click="showIngredients = !showIngredients">
            食材汇总 {{ showIngredients ? '▲' : '▼' }}
          </h3>
          <div v-if="showIngredients" class="summary-list">
            <div v-for="(ing, idx) in allIngredients" :key="idx" class="summary-row">
              <span>{{ ing.name }}</span>
              <span>{{ ing.amount }}</span>
            </div>
          </div>
        </div>

        <!-- 调料汇总 -->
        <div v-if="allSeasonings.length > 0" class="summary-section">
          <h3 @click="showSeasonings = !showSeasonings">
            调料汇总 {{ showSeasonings ? '▲' : '▼' }}
          </h3>
          <div v-if="showSeasonings" class="summary-list">
            <div v-for="(s, idx) in allSeasonings" :key="idx" class="summary-row">
              <span>{{ s.name }}</span>
              <span>{{ s.amount }}</span>
            </div>
          </div>
        </div>

        <div class="cart-actions">
          <button class="btn-cancel" @click="showCart = false">继续点餐</button>
          <button class="btn-submit" @click="submitOrder">确认提交</button>
        </div>
      </div>
    </div>

    <!-- 下单成功详情页 -->
    <div v-if="showSuccess" class="success-page">
      <div class="success-header">
        <div class="success-icon">✅</div>
        <h2>下单成功！</h2>
        <p v-if="successOrder.expected_time">期望用餐时间：{{ formatDateTime(successOrder.expected_time) }}</p>
      </div>

      <div class="success-section">
        <h3>订单详情</h3>
        <div v-for="item in successOrder.dishes" :key="item.id" class="success-dish">
          <img v-if="item.image_url" :src="item.image_url" class="success-dish-img" />
          <div v-else class="success-dish-ph"></div>
          <div class="success-dish-info">
            <h4>{{ item.name }}</h4>
            <p>{{ item.cook_time }}分钟</p>
            <p v-if="item.customer_note" class="dish-customer-note">备注：{{ item.customer_note }}</p>
          </div>
        </div>
      </div>

      <div class="success-section">
        <h3>合计</h3>
        <p class="success-total">共 {{ successOrder.dishes.length }} 道菜，约 {{ successOrder.total_time }} 分钟</p>
      </div>

      <div v-if="successOrder.note" class="success-section">
        <h3>订单备注</h3>
        <p class="success-note">{{ successOrder.note }}</p>
      </div>

      <div class="success-section">
        <h3>食材汇总</h3>
        <div v-for="(ing, idx) in successIngredients" :key="idx" class="summary-row">
          <span>{{ ing.name }}</span>
          <span>{{ ing.amount }}</span>
        </div>
        <p v-if="successIngredients.length === 0" class="empty-tip">无食材信息</p>
      </div>

      <div class="success-section">
        <h3>调料汇总</h3>
        <div v-for="(s, idx) in successSeasonings" :key="idx" class="summary-row">
          <span>{{ s.name }}</span>
          <span>{{ s.amount }}</span>
        </div>
        <p v-if="successSeasonings.length === 0" class="empty-tip">无调料信息</p>
      </div>

      <div class="success-actions">
        <button class="btn-order-again" @click="orderAgain">再来一单</button>
      </div>
    </div>

    <!-- 菜品详情弹窗 -->
    <div v-if="showDetail" class="modal-mask" @click.self="showDetail = false">
      <div class="modal-box detail-modal">
        <img v-if="detailDish.image_url" :src="detailDish.image_url" class="detail-img" />
        <div v-else class="detail-img-ph"></div>
        <h2>{{ detailDish.name }}</h2>
        <p>分类：{{ detailDish.category }} | {{ detailDish.temperature }}</p>
        <p>耗时：{{ detailDish.cook_time }}分钟</p>
        <div class="flavor-tags">
          <span v-for="f in detailDish.flavor" :key="f" class="flavor-tag">{{ f }}</span>
        </div>
        <div v-if="detailDish.notes" class="detail-notes">
          <strong>备注：</strong>{{ detailDish.notes }}
        </div>
        <h4>食材：</h4>
        <ul><li v-for="(ing, idx) in detailDish.ingredients" :key="idx">{{ ing.name }} - {{ ing.amount }}</li></ul>
        <h4>调料：</h4>
        <ul><li v-for="(s, idx) in detailDish.seasonings" :key="idx">{{ s.name }} - {{ s.amount }}</li></ul>
        <button class="btn-close" @click="showDetail = false">关闭</button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, inject, watch } from 'vue'
import { supabase } from '../lib/supabase'
import { useCart } from '../lib/cart'

const settings = inject('shopSettings')
const version = ref('v2.0.13')

// Logo 图片加载失败时，清除 url 让默认图标显示
function onLogoError() {
  settings.value.logo_url = ''
}

// 页签状态
const currentTab = ref('menu')

const categories = ['全部', '荤菜', '素菜', '汤类', '粉面类']
const activeCategory = ref('全部')
const dishes = ref([])
const customerName = ref('')
const nameInput = ref('')
const nameError = ref('')
const showCart = ref(false)
const showDetail = ref(false)
const detailDish = ref({})
const showIngredients = ref(false)
const showSeasonings = ref(false)
const orderNote = ref('')
const expectedTime = ref('')
const showSuccess = ref(false)
const successOrder = ref({ dishes: [], total_time: 0 })
const successIngredients = ref([])
const successSeasonings = ref([])

// 历史订单相关
const orders = ref([])
const expandedOrderId = ref(null)

const { cartItems, addToCart, removeFromCart, clearCart, getTotalTime } = useCart()

onMounted(() => {
  const params = new URLSearchParams(window.location.search)
  const urlName = params.get('customer')
  const saved = localStorage.getItem('cook_customer_name')
  if (urlName) {
    customerName.value = urlName
    localStorage.setItem('cook_customer_name', urlName)
    loadDishes()
    loadHistory()
  } else if (saved) {
    customerName.value = saved
    loadDishes()
    loadHistory()
  }
  // 默认期望时间为今天 18:00
  const d = new Date()
  d.setHours(18, 0, 0, 0)
  expectedTime.value = d.toISOString().slice(0, 16)
})

async function verifyName() {
  const name = nameInput.value.trim()
  if (!name) return
  const { data, error } = await supabase
    .from('customers')
    .select('name')
    .eq('name', name)
    .single()
  if (error || !data) {
    nameError.value = '姓名不存在，请联系管理员添加'
    return
  }
  customerName.value = name
  localStorage.setItem('cook_customer_name', name)
  nameError.value = ''
  loadDishes()
  loadHistory()
}

async function loadDishes() {
  const { data, error } = await supabase
    .from('dishes')
    .select('*')
    .eq('is_active', true)
    .order('created_at', { ascending: false })
  if (!error) dishes.value = data || []
}

async function loadHistory() {
  if (!customerName.value) return
  const { data, error } = await supabase
    .from('orders')
    .select('*')
    .eq('customer_name', customerName.value)
    .order('created_at', { ascending: false })
  if (!error) {
    orders.value = await enrichOrderDishes(data || [])
  }
}

/** 从 dishes 表补全订单菜品中缺失的 image_url 和 category */
async function enrichOrderDishes(orderList) {
  // 收集所有需要补全的 dish id
  const needIds = new Set()
  orderList.forEach(order => {
    ;(order.dishes || []).forEach(d => {
      if (!d.image_url || !d.category) {
        needIds.add(d.id)
      }
    })
  })
  // 查询 dishes 表获取完整数据
  let dishMap = {}
  if (needIds.size > 0) {
    const { data: dishData } = await supabase
      .from('dishes')
      .select('id, image_url, category')
      .in('id', Array.from(needIds))
    ;(dishData || []).forEach(d => { dishMap[d.id] = d })
  }
  // 补全每个订单的菜品
  return orderList.map(order => ({
    ...order,
    dishes: (order.dishes || []).map(d => {
      const fullDish = dishMap[d.id]
      return {
        ...d,
        image_url: d.image_url || (fullDish ? fullDish.image_url : ''),
        category: d.category || (fullDish ? fullDish.category : '')
      }
    })
  }))
}

function isInCart(dishId) {
  return cartItems.value.some(item => item.id === dishId)
}

function showDishDetail(dish) {
  detailDish.value = dish
  showDetail.value = true
}

function openCart() {
  showCart.value = true
}

function toggleOrder(id) {
  expandedOrderId.value = expandedOrderId.value === id ? null : id
}

function doLogout() {
  localStorage.removeItem('cook_customer_name')
  customerName.value = ''
  currentTab.value = 'menu'
  orders.value = []
}

const filteredDishes = computed(() => {
  if (activeCategory.value === '全部') return dishes.value
  return dishes.value.filter(d => d.category === activeCategory.value)
})

const allIngredients = computed(() => {
  const map = {}
  cartItems.value.forEach(item => {
    ;(item.ingredients || []).forEach(ing => {
      if (map[ing.name]) {
        map[ing.name].amount += ' + ' + ing.amount
      } else {
        map[ing.name] = { name: ing.name, amount: ing.amount }
      }
    })
  })
  return Object.values(map)
})

const allSeasonings = computed(() => {
  const map = {}
  cartItems.value.forEach(item => {
    ;(item.seasonings || []).forEach(s => {
      if (map[s.name]) {
        map[s.name].amount += ' + ' + s.amount
      } else {
        map[s.name] = { name: s.name, amount: s.amount }
      }
    })
  })
  return Object.values(map)
})

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

async function submitOrder() {
  if (cartItems.value.length === 0) return
  if (!expectedTime.value) {
    alert('请选择期望用餐时间')
    return
  }
  const orderDishes = cartItems.value.map(item => ({
    id: item.id,
    name: item.name,
    category: item.category || '',
    cook_time: item.cook_time,
    image_url: item.image_url,
    ingredients: item.ingredients || [],
    seasonings: item.seasonings || [],
    customer_note: item.customer_note || ''
  }))
  const { data, error } = await supabase.from('orders').insert({
    customer_name: customerName.value,
    dishes: orderDishes,
    total_time: getTotalTime(),
    note: orderNote.value.trim() || null,
    expected_time: expectedTime.value
  }).select().single()
  if (error) {
    alert('提交失败：' + error.message)
    return
  }
  // 准备成功页数据
  successOrder.value = {
    dishes: orderDishes,
    total_time: getTotalTime(),
    note: orderNote.value.trim() || '',
    expected_time: expectedTime.value
  }
  const ingMap = {}
  orderDishes.forEach(item => {
    ;(item.ingredients || []).forEach(ing => {
      if (ingMap[ing.name]) {
        ingMap[ing.name].amount += ' + ' + ing.amount
      } else {
        ingMap[ing.name] = { name: ing.name, amount: ing.amount }
      }
    })
  })
  successIngredients.value = Object.values(ingMap)

  const seaMap = {}
  orderDishes.forEach(item => {
    ;(item.seasonings || []).forEach(s => {
      if (seaMap[s.name]) {
        seaMap[s.name].amount += ' + ' + s.amount
      } else {
        seaMap[s.name] = { name: s.name, amount: s.amount }
      }
    })
  })
  successSeasonings.value = Object.values(seaMap)

  clearCart()
  orderNote.value = ''
  expectedTime.value = ''
  showCart.value = false
  showSuccess.value = true
  currentTab.value = 'menu'
  window.scrollTo({ top: 0, behavior: 'smooth' })
  // 刷新历史记录
  loadHistory()
}

function formatDateTime(dt) {
  const d = new Date(dt)
  return `${d.getMonth()+1}月${d.getDate()}日 ${d.getHours()}:${String(d.getMinutes()).padStart(2,'0')}`
}

function formatDate(dateStr) {
  const d = new Date(dateStr)
  return `${d.getFullYear()}/${d.getMonth()+1}/${d.getDate()} ${String(d.getHours()).padStart(2,'0')}:${String(d.getMinutes()).padStart(2,'0')}`
}

function orderAgain() {
  showSuccess.value = false
}
</script>

<style scoped>
.menu-page { max-width: 480px; margin: 0 auto; padding-bottom: 70px; }

.top-bar {
  display: flex; align-items: center; gap: 10px;
  padding: 12px 16px; background: var(--primary); color: #fff;
}
.top-bar .logo { width: 40px; height: 40px; border-radius: 50%; object-fit: cover; border: 2px solid rgba(255,255,255,0.4); flex-shrink: 0; }
.top-bar .logo-default {
  width: 40px; height: 40px; border-radius: 50%;
  background: rgba(255,255,255,0.18);
  display: flex; align-items: center; justify-content: center;
  font-size: 22px; flex-shrink: 0;
}
.top-bar h1 { font-size: 18px; font-weight: 600; flex: 1; }
.version-in-header {
  font-size: 11px; color: rgba(255,255,255,0.75);
  background: rgba(0,0,0,0.18);
  padding: 3px 8px; border-radius: 10px;
  white-space: nowrap; flex-shrink: 0;
}

/* 页签导航 */
.tab-nav {
  display: flex; justify-content: space-between; align-items: center;
  padding: 8px 16px; background: #fff;
  border-bottom: 1px solid var(--border);
}
.tab-group { display: flex; gap: 4px; background: var(--bg); border-radius: 8px; padding: 2px; }
.tab-btn {
  padding: 6px 18px; border-radius: 6px; font-size: 13px;
  background: transparent; color: var(--text-secondary); border: none; cursor: pointer;
}
.tab-btn.active {
  background: var(--primary); color: #fff; font-weight: 500;
}
.logout-btn {
  padding: 5px 12px; border-radius: 6px; font-size: 12px;
  background: #fff0f0; color: #e55a2b; border: 1px solid #ffcccc; cursor: pointer;
}

/* 登录框 */
.name-modal {
  position: fixed; inset: 0; background: rgba(0,0,0,0.5);
  display: flex; align-items: center; justify-content: center; z-index: 100;
}
.name-box {
  background: #fff; border-radius: 12px; padding: 24px; width: 300px; text-align: center;
}
.name-box h2 { margin-bottom: 8px; }
.name-box p { color: #888; margin-bottom: 16px; font-size: 13px; }
.name-box input {
  width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 8px;
  margin-bottom: 8px;
}
.name-error {
  background: #fff2f0;
  color: #ff4d4f;
  font-size: 14px;
  font-weight: 600;
  padding: 10px 14px;
  border-radius: 8px;
  border: 1px solid #ffccc7;
  margin-bottom: 12px;
  text-align: center;
}
.name-box button {
  width: 100%; padding: 10px; background: var(--primary); color: #fff;
  border-radius: 8px; font-weight: 500; margin-top: 4px;
}

/* 分类导航 */
.category-nav {
  display: flex; gap: 8px; padding: 10px 16px; overflow-x: auto;
  background: #fff;
}
.cat-btn {
  white-space: nowrap; padding: 6px 14px; border-radius: 20px;
  background: var(--bg); color: var(--text); font-size: 13px;
  border: 1.5px solid transparent;
}
.cat-btn.cat-全部 { color: var(--primary); border-color: rgba(255,107,53,0.45); background: rgba(255,107,53,0.08); }
.cat-btn.cat-全部.active { background: var(--primary); color: #fff; border-color: var(--primary); }
.cat-btn.cat-荤菜 { color: #e53935; border-color: rgba(229,57,53,0.45); background: rgba(229,57,53,0.08); }
.cat-btn.cat-荤菜.active { background: #e53935; color: #fff; border-color: #e53935; }
.cat-btn.cat-素菜 { color: #43a047; border-color: rgba(67,160,71,0.45); background: rgba(67,160,71,0.08); }
.cat-btn.cat-素菜.active { background: #43a047; color: #fff; border-color: #43a047; }
.cat-btn.cat-汤类 { color: #1e88e5; border-color: rgba(30,136,229,0.45); background: rgba(30,136,229,0.08); }
.cat-btn.cat-汤类.active { background: #1e88e5; color: #fff; border-color: #1e88e5; }
.cat-btn.cat-粉面类 { color: #f57c00; border-color: rgba(245,124,0,0.45); background: rgba(245,124,0,0.08); }
.cat-btn.cat-粉面类.active { background: #f57c00; color: #fff; border-color: #f57c00; }

/* 菜品卡片 */
.dish-list { padding: 12px; display: grid; gap: 12px; }
.dish-card {
  display: flex; gap: 12px; background: #fff; border-radius: 12px;
  padding: 12px; align-items: center;
}
.dish-img {
  width: 80px; height: 80px; border-radius: 8px; overflow: hidden;
  flex-shrink: 0; position: relative; cursor: pointer;
}
.dish-img img { width: 100%; height: 100%; object-fit: cover; }
.img-placeholder {
  width: 100%; height: 100%; background: #f0f0f0;
  display: flex; align-items: center; justify-content: center;
  font-size: 11px; color: #aaa;
}
/* 菜品分类角标（左上角） */
.cat-tag {
  position: absolute; top: 4px; left: 4px;
  font-size: 10px; padding: 2px 6px; border-radius: 4px;
  color: #fff; font-weight: 500;
}
.cat-tag.cat-荤菜 { background: rgba(229,57,53,0.78); }
.cat-tag.cat-素菜 { background: rgba(67,160,71,0.78); }
.cat-tag.cat-汤类 { background: rgba(30,136,229,0.78); }
.cat-tag.cat-粉面类 { background: rgba(245,124,0,0.78); }
.dish-info { flex: 1; min-width: 0; }
.dish-info h3 { font-size: 15px; margin-bottom: 4px; }
.flavor-tags { display: flex; gap: 4px; flex-wrap: wrap; margin-bottom: 4px; }
.flavor-tag {
  font-size: 11px; padding: 2px 6px; border-radius: 4px;
  background: var(--primary-light); color: var(--primary);
}
.cook-time { font-size: 12px; color: var(--text-secondary); }
.dish-notes { font-size: 11px; color: #e55a2b; margin-top: 2px; }

/* 添加/已添加按钮 */
.add-btn {
  width: 32px; height: 32px; border-radius: 50%; flex-shrink: 0;
  background: var(--primary); color: #fff; font-size: 18px; font-weight: bold;
  border: none; cursor: pointer; transition: all 0.15s;
}
.checked-btn {
  background: #27ae60 !important;
  box-shadow: 0 2px 6px rgba(39,174,96,0.35);
}
.add-btn:active { transform: scale(0.9); }
.checked-btn:active { transform: scale(0.9); }

/* 底部购物车 */
.cart-bar {
  position: fixed; bottom: 0; left: 50%; transform: translateX(-50%);
  width: 100%; max-width: 480px; background: #fff;
  border-top: 1px solid var(--border); padding: 10px 16px;
  display: flex; align-items: center; gap: 12px; z-index: 50; cursor: pointer;
}
.cart-icon { position: relative; font-size: 24px; }
.cart-count {
  position: absolute; top: -6px; right: -8px; background: var(--danger);
  color: #fff; font-size: 11px; width: 18px; height: 18px;
  border-radius: 50%; display: flex; align-items: center; justify-content: center;
}
.cart-info { flex: 1; font-size: 13px; }
.cart-submit {
  background: var(--primary); color: #fff; padding: 8px 16px;
  border-radius: 8px; font-weight: 500;
}

/* 弹窗通用 */
.modal-mask {
  position: fixed; inset: 0; background: rgba(0,0,0,0.5);
  display: flex; align-items: flex-end; justify-content: center; z-index: 200;
}
.modal-box {
  background: #fff; border-radius: 16px 16px 0 0; width: 100%;
  max-width: 480px; max-height: 85vh; overflow-y: auto; padding: 20px;
}

/* 购物车弹窗 */
.cart-modal h2 { font-size: 16px; margin-bottom: 12px; }
.cart-item {
  display: flex; align-items: center; gap: 8px; padding: 10px 0;
  border-bottom: 1px solid var(--border);
}
.cart-item-img { width: 40px; height: 40px; border-radius: 8px; object-fit: cover; flex-shrink: 0; }
.cart-item-img-ph { width: 40px; height: 40px; border-radius: 8px; background: #f0f0f0; flex-shrink: 0; }
.cart-item-info { flex: 1; min-width: 0; }
.cart-item-info h4 { font-size: 13px; display: flex; align-items: center; gap: 4px; flex-wrap: wrap; }
.cart-item-time { font-size: 12px; color: var(--text-secondary); }
.cart-note-input {
  flex: 1; padding: 6px; border: 1px solid #ddd; border-radius: 6px;
  font-size: 12px;
}
.remove-btn-circle {
  width: 26px; height: 26px; border-radius: 50%;
  background: #fff; border: 2px solid #ff4d4f;
  color: #ff4d4f; font-size: 18px; font-weight: 700;
  flex-shrink: 0; cursor: pointer; display: flex;
  align-items: center; justify-content: center; line-height: 1;
}
.expected-time-section { margin-top: 12px; }
.expected-time-section label { font-size: 13px; font-weight: 500; display: block; margin-bottom: 4px; }
.required { color: #e55a2b; }
.time-input {
  width: 100%; padding: 8px 10px; border: 1px solid #ddd; border-radius: 8px;
  font-size: 14px;
}
.order-note-section { margin-top: 12px; }
.order-note-section label { font-size: 13px; font-weight: 500; display: block; margin-bottom: 4px; }
.order-note-input {
  width: 100%; padding: 8px 10px; border: 1px solid #ddd; border-radius: 8px;
  font-size: 13px; min-height: 60px; resize: vertical;
}
.summary-section { margin-top: 12px; }
.summary-section h3 {
  font-size: 14px; cursor: pointer; color: var(--primary);
  margin-bottom: 6px;
}
.summary-list { padding-left: 12px; }
.summary-row {
  display: flex; justify-content: space-between; font-size: 13px;
  padding: 4px 0; border-bottom: 1px dashed #eee;
}
.cart-actions {
  display: flex; gap: 12px; margin-top: 16px;
}
.btn-cancel {
  flex: 1; padding: 10px; border: 1px solid var(--border);
  border-radius: 8px; background: #fff;
}
.btn-submit {
  flex: 1; padding: 10px; background: var(--primary);
  color: #fff; border-radius: 8px; font-weight: 500;
}

/* 下单成功页 */
.success-page { padding-bottom: 20px; }
.success-header {
  text-align: center; padding: 30px 16px 20px;
  background: linear-gradient(180deg, #e8f5e9 0%, #f5f5f5 100%);
}
.success-icon { font-size: 48px; margin-bottom: 8px; }
.success-header h2 { font-size: 20px; color: #2e7d32; margin-bottom: 4px; }
.success-header p { font-size: 13px; color: var(--text-secondary); }
.success-section {
  background: #fff; margin: 10px 12px; border-radius: 12px; padding: 14px;
}
.success-section h3 { font-size: 14px; margin-bottom: 8px; color: var(--primary); }
.success-dish {
  display: flex; gap: 10px; align-items: center; padding: 8px 0;
  border-bottom: 1px solid var(--border);
}
.success-dish:last-child { border-bottom: none; }
.success-dish-img { width: 50px; height: 50px; border-radius: 8px; object-fit: cover; flex-shrink: 0; }
.success-dish-ph { width: 50px; height: 50px; border-radius: 8px; background: #f0f0f0; flex-shrink: 0; }
.success-dish-info { flex: 1; }
.success-dish-info h4 { font-size: 14px; }
.success-dish-info p { font-size: 12px; color: var(--text-secondary); }
.dish-customer-note { font-size: 11px; color: #e55a2b; }
.success-total { font-size: 14px; font-weight: 500; }
.success-note {
  background: #fff8e8; padding: 8px; border-radius: 6px;
  font-size: 13px; color: #e55a2b;
}
.success-actions {
  display: flex; gap: 12px; padding: 16px 12px;
}
.btn-order-again {
  flex: 1; padding: 10px; background: var(--primary);
  color: #fff; border-radius: 8px; font-weight: 500;
}
.empty-tip { font-size: 12px; color: var(--text-secondary); }

/* 历史订单页签 */
.history-tab { padding: 12px; }
.history-header {
  display: flex; justify-content: space-between; align-items: center;
  margin-bottom: 12px;
}
.history-header h2 { font-size: 16px; color: var(--text); }
.history-name { font-size: 12px; color: var(--text-secondary); }
.order-card {
  background: #fff; border-radius: 12px; padding: 12px; margin-bottom: 10px;
  cursor: pointer;
}
.order-header {
  display: flex; gap: 10px; align-items: center; font-size: 13px;
  margin-bottom: 6px;
}
.order-date { color: var(--text-secondary); }
.expected-badge {
  display: inline-block;
  font-size: 12px;
  font-weight: 500;
  color: #1b7e3e;
  background: linear-gradient(135deg, #e8f5e9, #f1f8e9);
  padding: 4px 10px;
  border-radius: 4px;
  border: 1.5px solid #a5d6a7;
  margin-left: 4px;
}
.order-arrow { margin-left: auto; color: #ccc; font-size: 10px; }
.order-summary {
  font-size: 13px; color: var(--text-secondary); line-height: 1.4;
}
.order-detail {
  margin-top: 10px; padding-top: 10px; border-top: 1px solid var(--border);
  font-size: 13px;
}
.order-detail h4 { font-size: 13px; margin: 8px 0 4px; color: var(--primary); }
.detail-dish-item { padding: 6px 0; font-size: 13px; display: flex; align-items: flex-start; gap: 10px; }
.detail-cat-tag {
  font-size: 10px; padding: 2px 7px; border-radius: 4px;
  font-weight: 500; color: #fff; flex-shrink: 0;
}
.detail-cat-tag.cat-荤菜 { background: rgba(229,57,53,0.82); }
.detail-cat-tag.cat-素菜 { background: rgba(67,160,71,0.82); }
.detail-cat-tag.cat-汤类 { background: rgba(30,136,229,0.82); }
.detail-cat-tag.cat-粉面类 { background: rgba(245,124,0,0.82); }
.detail-dish-img { width: 52px; height: 52px; border-radius: 8px; object-fit: cover; flex-shrink: 0; }
.detail-dish-ph {
  width: 52px; height: 52px; border-radius: 8px; background: linear-gradient(135deg,#f5f5f0,#e8e8e0);
  flex-shrink: 0; display: flex; align-items: center; justify-content: center;
  font-size: 22px;
}
.detail-dish-info { flex: 1; min-width: 0; }
.detail-dish-name-row { display: flex; align-items: center; gap: 5px; flex-wrap: wrap; }
.detail-cook-time { font-size: 12px; color: var(--text-secondary); margin-left: 0; }
.detail-note { font-size: 11px; color: #e55a2b; }
.detail-total { font-weight: 500; margin-top: 6px; }
.detail-note-full { font-size: 12px; color: var(--text-secondary); margin-top: 6px; background: #f9f9f9; padding: 6px; border-radius: 6px; }

/* 菜品详情弹窗 */
.detail-modal { border-radius: 16px; max-height: 85vh; overflow-y: auto; margin: 20px auto; width: 90%; max-width: 420px; }
.detail-img { width: 100%; height: 200px; object-fit: cover; border-radius: 8px; margin-bottom: 12px; }
.detail-img-ph { width: 100%; height: 200px; background: #f0f0f0; border-radius: 8px; margin-bottom: 12px; }
.detail-notes {
  background: #fff8e8; padding: 8px; border-radius: 6px;
  font-size: 13px; margin: 8px 0; color: #e55a2b;
}
.detail-modal ul { padding-left: 20px; font-size: 13px; color: var(--text-secondary); }
.detail-modal h4 { margin-top: 10px; font-size: 14px; }
.btn-close {
  width: 100%; padding: 10px; background: var(--primary); color: #fff;
  border-radius: 8px; margin-top: 16px;
}
</style>
