<template>
  <div class="menu-page">
    <!-- 顶部标题栏 -->
    <header class="top-bar">
      <img v-if="settings.logo_url" :src="settings.logo_url" class="logo" />
      <h1>{{ settings.shop_name }}</h1>
    </header>

    <!-- 客户姓名输入 -->
    <div v-if="!customerName" class="name-modal">
      <div class="name-box">
        <h2>欢迎光临</h2>
        <p>请输入您的姓名，开始点餐</p>
        <input v-model="nameInput" placeholder="请输入姓名" @keyup.enter="saveName" />
        <button @click="saveName">进入菜单</button>
      </div>
    </div>

    <!-- 分类导航 -->
    <nav class="category-nav" v-if="customerName">
      <button
        v-for="cat in categories"
        :key="cat"
        :class="['cat-btn', { active: activeCategory === cat }]"
        @click="activeCategory = cat"
      >{{ cat }}</button>
    </nav>

    <!-- 菜品列表 -->
    <div class="dish-list" v-if="customerName">
      <div v-for="dish in filteredDishes" :key="dish.id" class="dish-card">
        <div class="dish-img" @click="showDishDetail(dish)">
          <img v-if="dish.image_url" :src="dish.image_url" />
          <div v-else class="img-placeholder">暂无图片</div>
          <span class="temp-tag">{{ dish.temperature }}</span>
        </div>
        <div class="dish-info">
          <h3>{{ dish.name }}</h3>
          <div class="flavor-tags">
            <span v-for="f in dish.flavor" :key="f" class="flavor-tag">{{ f }}</span>
          </div>
          <p class="cook-time">⏱ {{ dish.cook_time }}分钟</p>
          <p v-if="dish.notes" class="dish-notes">📝 {{ dish.notes }}</p>
        </div>
        <button
          :class="['add-btn', { added: isInCart(dish.id) }]"
          @click="addToCart(dish)"
        >{{ isInCart(dish.id) ? '已添加' : '+' }}</button>
      </div>
    </div>

    <!-- 底部购物车栏 -->
    <div v-if="cartItems.length > 0 && !showSuccess" class="cart-bar" @click="showCart = true">
      <div class="cart-icon">
        🛒
        <span class="cart-count">{{ cartItems.length }}</span>
      </div>
      <div class="cart-info">
        <span>已选 {{ cartItems.length }} 道菜</span>
        <span>约 {{ getTotalTime() }} 分钟</span>
      </div>
      <button class="cart-submit" @click.stop="submitOrder">提交订单</button>
    </div>

    <!-- 购物车弹窗 -->
    <div v-if="showCart" class="modal-mask" @click.self="showCart = false">
      <div class="modal-box cart-modal">
        <h2>我的购物车</h2>
        <div v-for="item in cartItems" :key="item.id" class="cart-item">
          <div class="cart-item-info">
            <h4>{{ item.name }}</h4>
            <p class="cart-item-time">{{ item.cook_time }}分钟</p>
          </div>
          <input
            v-model="item.customer_note"
            placeholder="备注（如：不要葱姜）"
            class="cart-note-input"
          />
          <button class="remove-btn" @click="removeFromCart(item.id)">✕</button>
        </div>

        <!-- 订单整体备注 -->
        <div class="order-note-section">
          <label>订单备注（选填）</label>
          <textarea
            v-model="orderNote"
            placeholder="如：今天有老人，口味清淡些；请在6点前做完"
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
        <p>厨师会尽快确认您的订单</p>
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
        <button class="btn-history" @click="goHistory">查看历史订单</button>
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
import { ref, computed, onMounted, inject } from 'vue'
import { supabase } from '../lib/supabase'
import { useCart } from '../lib/cart'

const settings = inject('shopSettings')

const categories = ['全部', '荤菜', '素菜', '汤类', '粉面类', '主食']
const activeCategory = ref('全部')
const dishes = ref([])
const customerName = ref('')
const nameInput = ref('')
const showCart = ref(false)
const showDetail = ref(false)
const detailDish = ref({})
const showIngredients = ref(false)
const showSeasonings = ref(false)
const orderNote = ref('')
const showSuccess = ref(false)
const successOrder = ref({ dishes: [], total_time: 0 })
const successIngredients = ref([])
const successSeasonings = ref([])

const { cartItems, addToCart, removeFromCart, clearCart, getTotalTime } = useCart()

onMounted(() => {
  const saved = localStorage.getItem('cook_customer_name')
  if (saved) customerName.value = saved
  loadDishes()
})

async function loadDishes() {
  const { data, error } = await supabase
    .from('dishes')
    .select('*')
    .eq('is_active', true)
    .order('created_at', { ascending: false })
  if (!error) dishes.value = data || []
}

function saveName() {
  if (!nameInput.value.trim()) return
  customerName.value = nameInput.value.trim()
  localStorage.setItem('cook_customer_name', customerName.value)
}

function isInCart(dishId) {
  return cartItems.value.some(item => item.id === dishId)
}

function showDishDetail(dish) {
  detailDish.value = dish
  showDetail.value = true
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

async function submitOrder() {
  if (cartItems.value.length === 0) return
  const orderDishes = cartItems.value.map(item => ({
    id: item.id,
    name: item.name,
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
    note: orderNote.value.trim() || null
  }).select().single()
  if (error) {
    alert('提交失败：' + error.message)
    return
  }
  // 准备成功页数据
  successOrder.value = {
    dishes: orderDishes,
    total_time: getTotalTime(),
    note: orderNote.value.trim() || ''
  }
  // 从数据库查回完整菜品信息（含食材调料）用于展示
  const dishIds = orderDishes.map(d => d.id)
  const { data: fullDishes } = await supabase
    .from('dishes')
    .select('id, ingredients, seasonings')
    .in('id', dishIds)
  const dishMap = {}
  ;(fullDishes || []).forEach(d => { dishMap[d.id] = d })

  // 汇总食材
  const ingMap = {}
  orderDishes.forEach(item => {
    const fd = dishMap[item.id]
    ;(fd?.ingredients || []).forEach(ing => {
      if (ingMap[ing.name]) {
        ingMap[ing.name].amount += ' + ' + ing.amount
      } else {
        ingMap[ing.name] = { name: ing.name, amount: ing.amount }
      }
    })
  })
  successIngredients.value = Object.values(ingMap)

  // 汇总调料
  const seaMap = {}
  orderDishes.forEach(item => {
    const fd = dishMap[item.id]
    ;(fd?.seasonings || []).forEach(s => {
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
  showCart.value = false
  showSuccess.value = true
  window.scrollTo({ top: 0, behavior: 'smooth' })
}

function goHistory() {
  window.location.href = '/history?customer=' + encodeURIComponent(customerName.value)
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
.top-bar .logo { width: 36px; height: 36px; border-radius: 50%; object-fit: cover; }
.top-bar h1 { font-size: 18px; font-weight: 600; }

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
  margin-bottom: 12px;
}
.name-box button {
  width: 100%; padding: 10px; background: var(--primary); color: #fff;
  border-radius: 8px; font-weight: 500;
}

.category-nav {
  display: flex; gap: 8px; padding: 10px 16px; overflow-x: auto;
  background: #fff; border-bottom: 1px solid var(--border);
}
.cat-btn {
  white-space: nowrap; padding: 6px 14px; border-radius: 20px;
  background: var(--bg); color: var(--text); font-size: 13px;
}
.cat-btn.active { background: var(--primary); color: #fff; }

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
.temp-tag {
  position: absolute; top: 4px; left: 4px;
  background: rgba(0,0,0,0.5); color: #fff;
  font-size: 10px; padding: 2px 6px; border-radius: 4px;
}
.dish-info { flex: 1; min-width: 0; }
.dish-info h3 { font-size: 15px; margin-bottom: 4px; }
.flavor-tags { display: flex; gap: 4px; flex-wrap: wrap; margin-bottom: 4px; }
.flavor-tag {
  font-size: 11px; padding: 2px 6px; border-radius: 4px;
  background: var(--primary-light); color: var(--primary);
}
.cook-time { font-size: 12px; color: var(--text-secondary); }
.dish-notes { font-size: 11px; color: #e55a2b; margin-top: 2px; }
.add-btn {
  width: 32px; height: 32px; border-radius: 50%; flex-shrink: 0;
  background: var(--primary); color: #fff; font-size: 18px; font-weight: bold;
}
.add-btn.added { background: #ccc; }

.cart-bar {
  position: fixed; bottom: 0; left: 50%; transform: translateX(-50%);
  width: 100%; max-width: 480px; background: #fff;
  border-top: 1px solid var(--border); padding: 10px 16px;
  display: flex; align-items: center; gap: 12px; z-index: 50;
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

.modal-mask {
  position: fixed; inset: 0; background: rgba(0,0,0,0.5);
  display: flex; align-items: flex-end; justify-content: center; z-index: 200;
}
.modal-box {
  background: #fff; border-radius: 16px 16px 0 0; width: 100%;
  max-width: 480px; max-height: 85vh; overflow-y: auto; padding: 20px;
}
.cart-modal h2 { font-size: 16px; margin-bottom: 12px; }
.cart-item {
  display: flex; align-items: center; gap: 8px; padding: 10px 0;
  border-bottom: 1px solid var(--border);
}
.cart-item-info { flex: 1; }
.cart-item-info h4 { font-size: 14px; }
.cart-item-time { font-size: 12px; color: var(--text-secondary); }
.cart-note-input {
  flex: 1; padding: 6px; border: 1px solid #ddd; border-radius: 6px;
  font-size: 12px;
}
.remove-btn {
  width: 24px; height: 24px; border-radius: 50%; background: #f0f0f0;
  color: #999; font-size: 12px; flex-shrink: 0;
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
.btn-history {
  flex: 1; padding: 10px; border: 1px solid var(--primary);
  color: var(--primary); border-radius: 8px; font-weight: 500;
  background: #fff;
}
.btn-order-again {
  flex: 1; padding: 10px; background: var(--primary);
  color: #fff; border-radius: 8px; font-weight: 500;
}
.empty-tip { font-size: 12px; color: var(--text-secondary); }

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
