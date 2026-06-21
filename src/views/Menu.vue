<template>
  <div class="menu-page">
    <!-- 顶部标题栏 -->
    <header class="top-bar">
      <img v-if="settings.logo_url" :src="settings.logo_url" class="logo" @error="onLogoError" @dblclick="showVersionPopup = true" />
      <div v-else class="logo-default" @dblclick="showVersionPopup = true">🍳</div>
      <h1>{{ settings.shop_name }}</h1>
      <div class="header-right">
        <span v-if="customerName" class="customer-badge">💎 {{ customerName }}</span>
      </div>
    </header>

    <!-- 公告栏（滚动显示） -->
    <div v-if="settings.announcement_enabled && settings.announcement" class="announcement-bar">
      <div class="announcement-scroll-wrap">
        <div class="announcement-scroll">
          <span class="announcement-text">📢 {{ settings.announcement }}</span>
        </div>
      </div>
    </div>

        <div v-if="!customerName" class="name-modal">
          <div class="name-box">
            <h2>🍳 {{ settings.shop_name }}</h2>
            <p class="welcome-text">欢迎光临，请输入您的用户名</p>
            <input v-model="nameInput" placeholder="请输入用户名" @keyup.enter="verifyName" />
            <div v-if="nameError && !showApplyBtn" class="name-error">{{ nameError }}</div>
            <div v-if="nameError && showApplyBtn" class="name-error name-error-apply">{{ nameError }}</div>
            <button @click="verifyName" v-if="!showApplyBtn">进入菜单</button>
            <button v-if="showApplyBtn" class="btn-apply" @click="applyJoin">📋 申请加入</button>
            <button v-if="showApplyBtn || appliedMsg" class="btn-back-login" @click="resetLogin">已有账号？点此登录</button>
            <div v-if="appliedMsg" class="applied-msg">{{ appliedMsg }}</div>
            <p class="version-text">v{{ version }}</p>
          </div>
        </div>

    <!-- 登录后的页签导航 + 退出登录 -->
    <nav v-if="customerName" class="tab-nav">
      <div class="tab-group">
        <button
          :class="['tab-btn', { active: currentTab === 'menu' }]"
          @click="currentTab = 'menu'"
        >🥢 点菜</button>
        <button
          :class="['tab-btn', { active: currentTab === 'history' }]"
          @click="currentTab = 'history'"
        >⏰ 历史</button>
        <button
          :class="['tab-btn', { active: currentTab === 'note' }]"
          @click="switchToChat"
        >💬 递个纸条
          <span v-if="noteUnread > 0" class="tab-unread">{{ noteUnread }}</span>
        </button>
      </div>
      <button class="logout-btn" @click="doLogout">退出</button>
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
        <div v-for="dish in filteredDishes" :key="dish.id" class="dish-card" @click="showDishDetail(dish)">
          <div class="dish-img">
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
            @click.stop="removeFromCart(dish.id)"
            title="点击从餐桌移除"
          >✓</button>
          <button
            v-else
            class="add-btn"
            @click.stop="addToCart(dish)"
          >+</button>
        </div>
      </div>

      <!-- 底部提示 -->
      <div v-if="filteredDishes.length > 0" class="end-hint">
        已经到底了！
      </div>

      <!-- 回到顶部按钮 -->
      <button v-if="showBackToTop && settings.show_back_to_top !== false" class="back-to-top" @click="scrollToTop">
        ↑
      </button>

      <!-- 底部购物车栏 -->
      <div v-if="cartItems.length > 0" class="cart-bar" @click="showCart = true">
        <div class="cart-icon">
          🍽️
          <span class="cart-count">{{ cartItems.length }}</span>
        </div>
        <div class="cart-info">
          <span>已选 {{ cartItems.length }} 道菜</span>
          <span>约 {{ getTotalTime() }} 分钟</span>
        </div>
        <button class="cart-submit" @click.stop="openCart">查看餐桌</button>
      </div>
    </div>

    <!-- ========== 历史订单页签 ========== -->
    <div v-if="customerName && currentTab === 'history'" class="history-tab">
      <div class="history-header">
        <h2>我的历史点菜</h2>
        <span class="history-name">{{ customerName }}</span>
      </div>
      <div v-if="orders.length === 0" class="empty-tip">
        还没点过菜哦～去选几道吧 🍴
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
          <p v-if="order.note" class="detail-note-full">备注：{{ order.note }}</p>
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
        <h2>我的餐桌</h2>
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
          <label>备注（选填）</label>
          <textarea
            v-model="orderNote"
            placeholder="如：不吃香菜"
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
          <button class="btn-submit" @click="submitOrder" :disabled="submitting">
            {{ submitting ? '提交中...' : '选择好了' }}
          </button>
        </div>
      </div>
    </div>

    <!-- 下单成功弹窗 -->
    <div v-if="showSuccess" class="modal-mask success-mask" @click.self="closeSuccess">
      <div class="modal-box success-modal">
        <div class="success-header">
          <div class="success-icon">✅</div>
          <h2>选择好了！</h2>
          <p v-if="successOrder.expected_time">期望用餐时间：{{ formatDateTime(successOrder.expected_time) }}</p>
          <p class="success-tip-text">快去通知大厨做饭吧！🍳</p>
        </div>

        <div class="success-section">
          <h3>点菜详情</h3>
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
          <h3>备注</h3>
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
          <button class="btn-confirm" @click="closeSuccess">确定</button>
        </div>
      </div>
    </div>

    <!-- 菜品详情弹窗 -->
    <div v-if="showDetail" class="modal-mask" @click.self="showDetail = false">
      <div class="modal-box detail-modal">
        <button class="detail-close-x" @click="showDetail = false">✕</button>
        <div class="detail-body">
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
        <div class="detail-actions">
          <button class="btn-close" @click="showDetail = false">关闭</button>
          <button v-if="!isInCart(detailDish.id)" class="btn-add-from-detail" @click="addToCartAndClose(detailDish)">加入餐桌</button>
          <button v-else class="btn-added-from-detail" @click="removeFromCart(detailDish.id); showDetail = false">已加入 ✓ 移除</button>
        </div>
        </div>
      </div>
    </div>

    <!-- ========== 递个纸条页签 ========== -->
    <div v-if="customerName && currentTab === 'note'" class="note-tab">
      <div class="note-chat-history" ref="noteHistoryRef">
        <div v-if="noteMessages.length === 0" class="chat-empty-tip">
          📝 给大厨写句话吧～
        </div>
        <div v-for="(msg, idx) in noteMessages" :key="idx"
          :class="['note-bubble', msg.sender === 'customer' ? 'mine' : 'theirs']">
          <div class="bubble-text">{{ msg.content }}</div>
          <div class="bubble-time">{{ formatChatTime(msg.created_at) }}</div>
        </div>
      </div>
      <div class="note-input-area">
        <div class="note-input-row">
          <button class="emoji-btn" @click="showEmojiPicker = !showEmojiPicker" title="表情">😊</button>
          <input v-model="noteContent" placeholder="给阿旺递个小纸条..." @keyup.enter="sendNote" maxlength="500" class="note-input" />
          <button @click="sendNote" :disabled="sendingNote || !noteContent.trim()" class="note-send-btn">发送</button>
        </div>
        <div v-if="showEmojiPicker" class="emoji-picker">
          <span v-for="e in emojiList" :key="e" class="emoji-item" @click="insertEmoji(e)">{{ e }}</span>
        </div>
      </div>
    </div>

    <!-- ========== 客户已被删除提示 ========== -->
    <div v-if="kickedOut" class="modal-mask kicked-out-mask" @click.self="kickedOut = false">
      <div class="modal-box kicked-out-box">
        <div class="kicked-out-icon">🚫</div>
        <h2>您的账号已被移除</h2>
        <p>请联系管理员重新添加您到用户名单</p>
        <button class="btn-confirm" @click="kickedOut = false">我知道了</button>
      </div>
    </div>

    <!-- 版本号弹窗（双击logo触发） -->
    <div v-if="showVersionPopup" class="modal-mask" @click.self="showVersionPopup = false">
      <div class="modal-box version-popup" @click="showVersionPopup = false">
        <div class="vp-logo">🍳</div>
        <div class="vp-name">{{ settings.shop_name }}</div>
        <div class="vp-version">{{ version }}</div>
        <div class="vp-hint">点击任意位置关闭</div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted, inject, watch, nextTick } from 'vue'
import { supabase } from '../lib/supabase'
import { useCart } from '../lib/cart'

const settings = inject('shopSettings')
const version = ref('v2.3.0')  // v2.3.0: 客户界面文案优化（订单→点菜）

// Logo 图片加载失败时，清除 url 让默认图标显示
function onLogoError() {
  settings.value.logo_url = ''
}

// 页签状态
const currentTab = ref('menu')

const categories = ['全部', '荤', '素', '汤', '粉面', '主食']
const activeCategory = ref('全部')
// 分类名映射（兼容旧数据：数据库里可能还是"荤菜"等旧名）
const categoryNameMap = {
  '荤': ['荤', '荤菜'],
  '素': ['素', '素菜'],
  '汤': ['汤', '汤类'],
  '粉面': ['粉面', '粉面类'],
  '主食': ['主食']
}
const dishes = ref([])
const customerName = ref('')
const nameInput = ref('')
const nameError = ref('')
const showApplyBtn = ref(false)
const appliedMsg = ref('')
const showCart = ref(false)
const showDetail = ref(false)
const detailDish = ref({})
const showIngredients = ref(false)
const showSeasonings = ref(false)
const orderNote = ref('')
const expectedTime = ref('')
const showSuccess = ref(false)
const submitting = ref(false)  // 防止重复提交
const kickedOut = ref(false)   // 客户已被删除提示
const showBackToTop = ref(false)
const successOrder = ref({ dishes: [], total_time: 0 })
const successIngredients = ref([])
const successSeasonings = ref([])

// 递纸条（对话界面）
const noteMessages = ref([])
const noteContent = ref('')
const sendingNote = ref(false)
const noteUnread = ref(0)
const noteHistoryRef = ref(null)
const showVersionPopup = ref(false)

// 表情选择器
const showEmojiPicker = ref(false)
const emojiList = ['😊','😂','😘','🥰','😋','😆','🥺','🤤','😎','🥳','👍','👎','👏','🙏','💪','✌️','🎉','❤️','🔥','✅','👌','🤗','🥹','🫶','😜','🤩']
let notePollTimer = null
let unreadPollTimer = null

// 历史订单相关
const orders = ref([])
const expandedOrderId = ref(null)

const { cartItems, addToCart, removeFromCart, clearCart, getTotalTime } = useCart()

// 验证客户是否还在系统里（已通过审核）
async function checkCustomerExists(name) {
  if (!name) return false
  // 先尝试带 status 过滤的查询（v2.3.0 新方式）
  const { data: approvedData, error: approvedError } = await supabase
    .from('customers')
    .select('name')
    .eq('name', name)
    .eq('status', 'approved')
    .single()
  if (!approvedError && approvedData) return true
  // 如果 status 列不存在（还没执行 SQL 迁移），回退到旧方式：只查名字
  if (approvedError && approvedError.message && approvedError.message.includes('status')) {
    const { data, error } = await supabase
      .from('customers')
      .select('name')
      .eq('name', name)
      .single()
    return !error && !!data
  }
  return false
}

// 客户被删除时：清空本地缓存 + 显示提示
function handleCustomerKickedOut() {
  customerName.value = ''
  localStorage.removeItem('cook_customer_name')
  kickedOut.value = true
  // 同时关闭所有可能打开的弹窗
  showCart.value = false
  showDetail.value = false
  showSuccess.value = false
}

onMounted(async () => {
  const params = new URLSearchParams(window.location.search)
  const urlName = params.get('customer')
  const saved = localStorage.getItem('cook_customer_name')
  const name = urlName || saved
  if (name) {
    // ✅ 关键：先验证客户是否还在系统里
    const exists = await checkCustomerExists(name)
    if (exists) {
      customerName.value = name
      if (urlName) {
        localStorage.setItem('cook_customer_name', name)
      }
      loadDishes()
      loadHistory()
      // 记录访问日志（异步，不影响登录）
      logAccess(name)
      startUnreadPolling()
    } else {
      // 客户已被删除
      handleCustomerKickedOut()
    }
  }
  // 默认期望时间为今天 18:00
  const d = new Date()
  d.setHours(18, 0, 0, 0)
  expectedTime.value = d.toISOString().slice(0, 16)

  // 监听滚动，显示/隐藏回到顶部按钮
  window.addEventListener('scroll', onScroll)
})

onUnmounted(() => {
  window.removeEventListener('scroll', onScroll)
  stopNotePolling()
  stopUnreadPolling()
})

function onScroll() {
  showBackToTop.value = window.scrollY > 400
}
function scrollToTop() {
  window.scrollTo({ top: 0, behavior: 'smooth' })
}

async function verifyName() {
  const name = nameInput.value.trim()
  if (!name) return
  showApplyBtn.value = false
  appliedMsg.value = ''
  nameError.value = ''

  // 先用旧方式查客户是否存在（兼容任何数据库状态）
  let data, error
  ;({ data, error } = await supabase
    .from('customers')
    .select('name')
    .eq('name', name)
    .single())

  // 如果查到客户，直接登录（不管有没有 status 字段）
  if (!error && data) {
    customerName.value = name
    localStorage.setItem('cook_customer_name', name)
    nameError.value = ''
    loadDishes()
    loadHistory()
    logAccess(name)
    startUnreadPolling()
    return
  }

  // 查不到 → 如果是 RLS 权限问题（列不存在or策略阻挡），显示友好提示
  if (error && (error.message.includes('row-level') || error.message.includes('policy') || error.message.includes('permission'))) {
    nameError.value = '系统需要更新数据库后才能使用，请联系管理员 🙏'
    return
  }

  // 确实不存在 → 显示申请按钮
  showApplyBtn.value = true
  nameError.value = `"${name}" 还未加入，点击下方按钮申请`
}

// 客户自助申请加入
async function applyJoin() {
  const name = nameInput.value.trim()
  if (!name) return
  appliedMsg.value = '正在提交申请...'

  // 先查一下这个名字是否已存在
  const { data: existingName } = await supabase
    .from('customers')
    .select('name')
    .eq('name', name)
    .single()

  if (existingName) {
    appliedMsg.value = `"${name}" 已经存在，直接输入用户名登录！如果无法登录，试试清除输入框重新输入 🔙`
    return
  }

  // 尝试带 status/applied_at 的完整插入（v2.3.0新方式）
  const { error } = await supabase.from('customers').insert({
    name,
    status: 'pending',
    applied_at: new Date().toISOString()
  })
  if (error) {
    // RLS 权限错误：引导用户执行迁移脚本
    if (error.message && (error.message.includes('row-level') || error.message.includes('policy'))) {
      appliedMsg.value = '系统需要先执行数据库迁移才能使用申请功能。请在 Supabase SQL Editor 中运行 supabase/migration-v2.3.0.sql 🙏'
      return
    }
    // 如果报错是因为列不存在（数据库没迁移），尝试用旧方式只插入name
    if (error.message && (error.message.includes('status') || error.message.includes('applied_at'))) {
      // 只插入name（兼容旧数据库结构）
      const { error: e2 } = await supabase.from('customers').insert({ name })
      if (e2) {
        if (e2.message.includes('unique') || e2.code === '23505') {
          appliedMsg.value = `"${name}" 已经存在，直接输入用户名登录即可！😄`
        } else if (e2.message.includes('row-level') || e2.message.includes('policy')) {
          appliedMsg.value = '系统需要更新才能使用申请功能，请在 Supabase SQL Editor 中执行迁移脚本（查看 supabase/migration-v2.3.0.sql）🙏'
        } else {
          appliedMsg.value = '申请失败：' + e2.message
        }
        return
      }
      appliedMsg.value = '申请已提交，请等待管理员通过！快去通知管理员吧 📢'
      return
    }
    appliedMsg.value = '申请失败：' + error.message
    return
  }
  appliedMsg.value = '申请已提交！等管理员通过后，输入用户名就可以点菜啦 🎉'
}

// 重置登录界面（从申请页面回到登录状态）
function resetLogin() {
  showApplyBtn.value = false
  appliedMsg.value = ''
  nameError.value = ''
  nameInput.value = ''
}

// ========== 访问日志 ==========
async function logAccess(name) {
  try {
    await supabase.from('access_logs').insert({
      customer_name: name,
      action: 'login',
      user_agent: navigator.userAgent || ''
    })
  } catch (e) {
    // 表不存在时静默忽略
  }
}

// ========== 递纸条（对话界面） ==========
function switchToChat() {
  currentTab.value = 'note'
  loadNoteMessages()
  clearUnreadCount()
  startNotePolling()
}

function startUnreadPolling() {
  stopUnreadPolling()
  checkUnreadNotes()
  unreadPollTimer = setInterval(checkUnreadNotes, 5000)
}

function stopUnreadPolling() {
  if (unreadPollTimer) {
    clearInterval(unreadPollTimer)
    unreadPollTimer = null
  }
}

async function checkUnreadNotes() {
  if (!customerName.value) return
  // 从已加载的消息中统计未读条数（管理员发来的、自己没看过的）
  const { data } = await supabase
    .from('messages')
    .select('id')
    .eq('customer_name', customerName.value)
    .eq('sender', 'admin')
    .eq('is_read', false)
  if (data) {
    noteUnread.value = data.length
  }
}

function clearUnreadCount() {
  noteUnread.value = 0
  // 将来打开对话时标记已读
  if (customerName.value) {
    supabase
      .from('messages')
      .update({ is_read: true })
      .eq('customer_name', customerName.value)
      .eq('sender', 'admin')
      .eq('is_read', false)
      .then(() => {})
  }
}

function startNotePolling() {
  stopNotePolling()
  notePollTimer = setInterval(loadNoteMessages, 3000)
}

function stopNotePolling() {
  if (notePollTimer) {
    clearInterval(notePollTimer)
    notePollTimer = null
  }
}

async function loadNoteMessages() {
  if (!customerName.value) return
  const { data, error } = await supabase
    .from('messages')
    .select('*')
    .eq('customer_name', customerName.value)
    .order('created_at', { ascending: true })
    .limit(100)
  if (!error && data) {
    noteMessages.value = data
    scrollNoteToBottom()
  }
}

async function sendNote() {
  const content = noteContent.value.trim()
  if (!content || !customerName.value) return
  sendingNote.value = true
  const { error } = await supabase.from('messages').insert({
    customer_name: customerName.value,
    sender: 'customer',
    content,
    is_read: false
  })
  sendingNote.value = false
  if (error) {
    if (error.message && (error.message.includes('does not exist') || error.message.includes('relation'))) {
      alert('纸条功能暂不可用，需要在 Supabase 中执行数据库迁移脚本。')
    } else {
      alert('发送失败：' + error.message)
    }
    return
  }
  noteContent.value = ''
  showEmojiPicker.value = false
  await loadNoteMessages()
}

function insertEmoji(e) {
  noteContent.value += e
  showEmojiPicker.value = false
}

function scrollNoteToBottom() {
  nextTick(() => {
    if (noteHistoryRef.value) {
      noteHistoryRef.value.scrollTop = noteHistoryRef.value.scrollHeight
    }
  })
}

function formatChatTime(dt) {
  if (!dt) return ''
  const d = new Date(dt)
  const now = new Date()
  const isToday = d.toDateString() === now.toDateString()
  const sameYear = d.getFullYear() === now.getFullYear()
  const time = `${String(d.getHours()).padStart(2,'0')}:${String(d.getMinutes()).padStart(2,'0')}`
  if (isToday) return time
  if (sameYear) return `${d.getMonth()+1}/${d.getDate()} ${time}`
  return `${d.getFullYear()}/${d.getMonth()+1}/${d.getDate()} ${time}`
}

async function loadDishes() {
  const { data, error } = await supabase
    .from('dishes')
    .select('*')
    .eq('is_active', true)
    .order('sort_order', { ascending: true })
    .order('created_at', { ascending: false })
  if (!error) dishes.value = data || []
}

// 从详情页加入餐桌后关闭弹窗
function addToCartAndClose(dish) {
  addToCart(dish)
  showDetail.value = false
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
  // 兼容新旧分类名
  const names = categoryNameMap[activeCategory.value] || [activeCategory.value]
  return dishes.value.filter(d => names.includes(d.category))
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
  if (submitting.value) return  // 正在提交中，直接返回
  if (cartItems.value.length === 0) return
  if (!expectedTime.value) {
    alert('请选择期望用餐时间')
    return
  }
  // ✅ 关键：提交前再次验证客户是否还在系统里
  const exists = await checkCustomerExists(customerName.value)
  if (!exists) {
    handleCustomerKickedOut()
    return
  }
  submitting.value = true  // 加锁
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
    submitting.value = false  // 失败释放锁，允许重试
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
  submitting.value = false  // 释放提交锁，允许下次提交
  // 刷新历史记录
  loadHistory()
}

function closeSuccess() {
  showSuccess.value = false
  submitting.value = false  // 关闭弹窗时也确保释放锁
}

function formatDateTime(dt) {
  const d = new Date(dt)
  return `${d.getMonth()+1}月${d.getDate()}日 ${d.getHours()}:${String(d.getMinutes()).padStart(2,'0')}`
}

function formatDate(dateStr) {
  const d = new Date(dateStr)
  return `${d.getFullYear()}/${d.getMonth()+1}/${d.getDate()} ${String(d.getHours()).padStart(2,'0')}:${String(d.getMinutes()).padStart(2,'0')}`
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
.header-right { display: flex; align-items: center; gap: 6px; flex-shrink: 0; margin-left: auto; margin-right: -10px; }
.customer-badge {
  font-size: 12px; color: rgba(255,255,255,0.9);
  background: rgba(255,255,255,0.15);
  padding: 2px 10px; border-radius: 12px; white-space: nowrap;
  margin-right: 8px;
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
.name-error-apply { color: #e55a2b; border-color: #ffd591; background: #fff7e6; }
.btn-apply {
  width: 100%; padding: 10px; background: var(--primary); color: #fff;
  border-radius: 8px; font-weight: 500; margin-top: 4px;
}
.applied-msg {
  margin-top: 10px; padding: 10px; border-radius: 8px;
  background: #f0faf4; border: 1px solid #b7eb8f;
  color: #389e0d; font-size: 13px; text-align: center;
}
.btn-back-login {
  width: 100%; padding: 8px; margin-top: 6px;
  background: transparent; color: var(--primary);
  border: 1px solid var(--primary); border-radius: 8px;
  font-size: 13px;
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
.cat-btn.cat-荤 { color: #e53935; border-color: rgba(229,57,53,0.45); background: rgba(229,57,53,0.08); }
.cat-btn.cat-荤.active { background: #e53935; color: #fff; border-color: #e53935; }
.cat-btn.cat-素 { color: #43a047; border-color: rgba(67,160,71,0.45); background: rgba(67,160,71,0.08); }
.cat-btn.cat-素.active { background: #43a047; color: #fff; border-color: #43a047; }
.cat-btn.cat-汤 { color: #1e88e5; border-color: rgba(30,136,229,0.45); background: rgba(30,136,229,0.08); }
.cat-btn.cat-汤.active { background: #1e88e5; color: #fff; border-color: #1e88e5; }
.cat-btn.cat-粉面 { color: #f57c00; border-color: rgba(245,124,0,0.45); background: rgba(245,124,0,0.08); }
.cat-btn.cat-粉面.active { background: #f57c00; color: #fff; border-color: #f57c00; }
.cat-btn.cat-主食 { color: #333; border-color: rgba(0,0,0,0.25); background: rgba(0,0,0,0.05); }
.cat-btn.cat-主食.active { background: #333; color: #fff; border-color: #333; }

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
.cat-tag.cat-荤 { background: rgba(229,57,53,0.78); }
.cat-tag.cat-素 { background: rgba(67,160,71,0.78); }
.cat-tag.cat-汤 { background: rgba(30,136,229,0.78); }
.cat-tag.cat-粉面 { background: rgba(245,124,0,0.78); }
.cat-tag.cat-主食 { background: rgba(0,0,0,0.55); }
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

/* 成功弹窗 - 居中显示 */
.success-mask {
  align-items: center;
}
.success-modal {
  border-radius: 16px !important;
  max-height: 80vh !important;
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
.expected-time-section {
  margin-top: 12px;
  padding: 10px 12px;
  background: #f0faf4;
  border: 1.5px solid #00a870;
  border-radius: 8px;
  overflow: hidden;
}
.expected-time-section label { font-size: 13px; font-weight: 500; display: block; margin-bottom: 6px; color: #00a870; }
.required { color: #e55a2b; }
.time-input {
  width: 100%; padding: 8px 10px; border: 1px solid #00a870; border-radius: 8px;
  font-size: 14px; box-sizing: border-box; max-width: 100%; min-width: 0;
}
@media (max-width: 480px) {
  .time-input { max-width: 220px; }
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


/* 下单成功弹窗样式 */
.success-header {
  text-align: center; padding: 20px 16px;
  border-bottom: 1px solid var(--border);
}
.success-icon { font-size: 48px; margin-bottom: 8px; }
.success-header h2 { font-size: 20px; color: #2e7d32; margin-bottom: 4px; }
.success-header p { font-size: 13px; color: var(--text-secondary); }
.success-tip-text {
  font-size: 14px; color: #27ae60;
  margin-top: 10px; padding: 8px 16px;
  background: rgba(39,174,96,0.1);
  border-radius: 20px;
  display: inline-block;
  font-weight: 500;
}
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
  display: flex; gap: 12px; padding: 16px 0;
}
.btn-confirm {
  flex: 1; padding: 12px; background: var(--primary);
  color: #fff; border-radius: 8px; font-weight: 500; font-size: 15px;
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
.detail-cat-tag.cat-荤 { background: rgba(229,57,53,0.82); }
.detail-cat-tag.cat-素 { background: rgba(67,160,71,0.82); }
.detail-cat-tag.cat-汤 { background: rgba(30,136,229,0.82); }
.detail-cat-tag.cat-粉面 { background: rgba(245,124,0,0.82); }
.detail-cat-tag.cat-主食 { background: rgba(0,0,0,0.65); }
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
.detail-modal { border-radius: 16px; overflow: hidden; margin: 20px auto; width: 90%; max-width: 420px; position: relative; }
.detail-body { max-height: 85vh; overflow-y: auto; padding: 16px; padding-top: 45px; }
/* 正方形 + 等比例完整显示 */
.detail-img {
  width: 100%;
  max-width: 320px;
  aspect-ratio: 1 / 1;
  object-fit: contain;
  background: #f5f5f5;
  border-radius: 8px;
  display: block;
  margin: 0 auto 12px;
}
.detail-img-ph {
  width: 100%;
  max-width: 320px;
  aspect-ratio: 1 / 1;
  background: linear-gradient(135deg, #f5f5f0, #e8e8e0);
  border-radius: 8px;
  margin: 0 auto 12px;
  display: flex; align-items: center; justify-content: center;
  color: #aaa; font-size: 14px;
}
.detail-notes {
  background: #fff8e8; padding: 8px; border-radius: 6px;
  font-size: 13px; margin: 8px 0; color: #e55a2b;
}
.detail-modal ul { padding-left: 20px; font-size: 13px; color: var(--text-secondary); }
.detail-modal h4 { margin-top: 10px; font-size: 14px; }

/* 详情页底部按钮区 */
.detail-actions {
  display: flex; gap: 10px; margin-top: 16px;
}
.detail-close-x {
  position: absolute; top: 10px; right: 10px;
  width: 32px; height: 32px; border: none;
  background: rgba(0,0,0,0.35); color: #fff;
  font-size: 16px; border-radius: 50%; cursor: pointer;
  display: flex; align-items: center; justify-content: center;
  z-index: 10;
}
.detail-actions button {
  flex: 1; padding: 10px; border-radius: 8px;
  font-size: 14px; font-weight: 500;
}
.btn-close { background: transparent; color: #666; border: 1.5px solid #ccc; }
.btn-add-from-detail { background: var(--primary); color: #fff; }
.btn-added-from-detail { background: #e6f7ee; color: #00a870; }

/* 客户被删除提示弹窗 */
.kicked-out-mask { align-items: center; }
.kicked-out-box { text-align: center; max-width: 360px; }
.kicked-out-icon { font-size: 48px; margin-bottom: 12px; }
.kicked-out-box h2 { font-size: 18px; color: #e55a2b; margin-bottom: 8px; }
.kicked-out-box p { font-size: 14px; color: var(--text-secondary); margin-bottom: 16px; }
.kicked-out-box .btn-confirm {
  width: 100%; padding: 12px; border-radius: 8px;
  background: var(--primary); color: #fff; font-weight: 500;
}
/* 底部提示 */
.end-hint {
  text-align: center; padding: 24px 16px;
  color: #999; font-size: 13px;
}
/* 版本号弹窗 */
.version-popup {
  text-align: center; padding: 32px 24px !important;
}
.vp-logo { font-size: 48px; margin-bottom: 8px; }
.vp-name { font-size: 16px; font-weight: 500; margin-bottom: 4px; }
.vp-version {
  font-size: 14px; color: var(--text-secondary);
  background: var(--border); display: inline-block;
  padding: 2px 14px; border-radius: 10px; margin: 8px auto;
}
.vp-hint { font-size: 12px; color: #bbb; margin-top: 4px; }

/* 回到顶部按钮 */
.back-to-top {
  position: fixed; bottom: 80px; right: 20px;
  width: 44px; height: 44px; border-radius: 50%;
  background: var(--primary); color: #fff;
  font-size: 20px; font-weight: bold;
  border: none; cursor: pointer;
  box-shadow: 0 2px 8px rgba(0,0,0,0.2);
  z-index: 100; display: flex;
  align-items: center; justify-content: center;
}

/* 公告栏 */
.announcement-bar {
  display: flex; align-items: center; gap: 6px;
  padding: 6px 12px; background: #fff8e8;
  border-bottom: 1px solid #f0e0c0;
  overflow: hidden;
}
.announcement-scroll-wrap {
  flex: 1; overflow: hidden; white-space: nowrap;
}
.announcement-scroll {
  display: inline-block;
  animation: marquee 15s linear infinite;
}
@keyframes marquee {
  0% { transform: translateX(100%); }
  100% { transform: translateX(-100%); }
}
.announcement-text {
  font-size: 12px; color: #b8860b;
}

/* 页签未读数 */
.tab-unread {
  display: inline-flex; align-items: center; justify-content: center;
  background: #ff4d4f; color: #fff; font-size: 10px;
  min-width: 16px; height: 16px; border-radius: 8px;
  padding: 0 4px; margin-left: 3px; vertical-align: top;
  font-weight: 600;
}

/* ========== 递个纸条页签 ========== */
.note-tab {
  position: relative;
  padding-bottom: 60px;
  min-height: calc(100vh - 200px);
}
.note-chat-history {
  overflow-y: auto; padding: 12px 16px 80px;
  display: flex; flex-direction: column; gap: 10px;
  max-height: calc(100vh - 180px);
}
.chat-empty-tip {
  text-align: center; color: #aaa; font-size: 14px;
  padding: 40px 0; margin-top: 40px;
}
.note-bubble { max-width: 80%; }
.note-bubble.mine { align-self: flex-end; }
.note-bubble.theirs { align-self: flex-start; }
.bubble-text {
  padding: 10px 14px; border-radius: 14px; font-size: 14px; line-height: 1.5;
  word-break: break-word;
}
.note-bubble.mine .bubble-text {
  background: var(--primary); color: #fff;
  border-bottom-right-radius: 4px;
}
.note-bubble.theirs .bubble-text {
  background: #f0f0f0; color: var(--text);
  border-bottom-left-radius: 4px;
}
.bubble-time {
  font-size: 11px; color: #aaa; margin-top: 4px; padding: 0 4px;
}
.note-bubble.mine .bubble-time { text-align: right; }
.note-input-area {
  position: fixed; left: 0; right: 0; bottom: 0;
  padding: 8px 12px;
  padding-bottom: calc(8px + env(safe-area-inset-bottom, 0px));
  border-top: 1px solid var(--border); background: #fff;
  z-index: 20; max-width: 480px; margin: 0 auto;
}
.note-input-row {
  display: flex; gap: 8px;
}
.emoji-btn {
  width: 38px; height: 38px; border-radius: 50%;
  background: var(--bg); border: none; font-size: 20px;
  cursor: pointer; flex-shrink: 0; display: flex;
  align-items: center; justify-content: center;
}
.emoji-btn:hover { background: #f0f0f0; }
.note-input {
  flex: 1; padding: 10px 14px; border: 1.5px solid #ddd;
  border-radius: 24px; font-size: 14px;
}
.note-send-btn {
  padding: 10px 20px; background: var(--primary); color: #fff;
  border-radius: 24px; font-size: 14px; white-space: nowrap;
}
.note-send-btn:disabled { opacity: 0.5; }
.emoji-picker {
  display: flex; flex-wrap: wrap; gap: 4px;
  padding: 8px 4px 2px; max-height: 120px; overflow-y: auto;
}
.emoji-item {
  width: 34px; height: 34px; display: flex; align-items: center;
  justify-content: center; font-size: 18px; border-radius: 6px;
  cursor: pointer;
}
.emoji-item:hover { background: #f0f0f0; }
</style>
