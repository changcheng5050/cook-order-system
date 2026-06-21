<template>
  <div class="admin-msgs">
    <header class="admin-top">
      <h2>📬 小纸条</h2>
      <div class="top-nav">
        <button class="btn-nav" @click="$router.push('/admin/dishes')">菜品</button>
        <button class="btn-nav" @click="$router.push('/admin/customers')">客户</button>
        <button class="btn-nav" @click="$router.push('/admin/orders')">订单</button>
        <button class="btn-nav active-nav" @click="$router.push('/admin/messages')">纸条</button>
        <button class="btn-nav" @click="$router.push('/admin/logs')">日志</button>
        <button class="btn-nav" @click="$router.push('/admin/settings')">设置</button>
        <button class="btn-logout" @click="logout">退出</button>
        <span class="version-badge">v2.3.0</span>
      </div>
    </header>

    <!-- 纸条会话列表 -->
    <div class="conversation-list">
      <div v-if="conversations.length === 0" class="empty-tip">暂无小纸条 📭</div>
      <div v-for="conv in conversations" :key="conv.customer_name"
        :class="['conv-card', { active: activeCustomer === conv.customer_name }]"
        @click="openConversation(conv.customer_name)">
        <div class="conv-avatar">{{ conv.customer_name.charAt(0).toUpperCase() }}</div>
        <div class="conv-info">
          <div class="conv-header">
            <span class="conv-name">{{ conv.customer_name }}</span>
            <span v-if="conv.unread > 0" class="conv-unread">{{ conv.unread > 99 ? '99+' : conv.unread }}</span>
          </div>
          <div class="conv-last-msg">{{ conv.last_content }}</div>
          <div class="conv-time">{{ formatTime(conv.last_time) }}</div>
        </div>
        <button class="conv-del-btn" @click.stop="deleteConversation(conv.customer_name)" title="删除所有消息">🗑️</button>
      </div>
    </div>

    <!-- 对话弹窗 -->
    <div v-if="activeCustomer" class="modal-mask" @click.self="activeCustomer = null">
      <div class="modal-box chat-modal-box">
        <div class="chat-header">
          <h3>💬 {{ activeCustomer }}</h3>
          <button class="chat-close-btn" @click="activeCustomer = null">✕</button>
        </div>
        <div class="chat-messages" ref="chatRef">
          <div v-if="chatMessages.length === 0" class="chat-empty">暂无消息</div>
          <div v-for="(msg, idx) in chatMessages" :key="idx"
            :class="['chat-msg', msg.sender === 'admin' ? 'admin' : 'customer']"
            @mouseenter="hoverMsgIdx = idx"
            @mouseleave="hoverMsgIdx = null">
            <div class="chat-content">{{ msg.content }}</div>
            <div class="chat-time">
              {{ formatChatTime(msg.created_at) }}
              <span v-if="hoverMsgIdx === idx" class="chat-del-btn" @click="deleteMessage(msg.id)">删除</span>
            </div>
          </div>
        </div>
        <div class="chat-input">
          <input v-model="chatInput" placeholder="回复..." @keyup.enter="sendReply" maxlength="500" />
          <button @click="sendReply" :disabled="!chatInput.trim()">发送</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted, nextTick } from 'vue'
import { supabase } from '../lib/supabase'

const messages = ref([])
const activeCustomer = ref(null)
const chatMessages = ref([])
const chatInput = ref('')
const chatRef = ref(null)
const hoverMsgIdx = ref(null)
let pollTimer = null

// 按客户分组，显示最新消息和未读数
const conversations = computed(() => {
  const map = {}
  messages.value.forEach(msg => {
    const name = msg.customer_name
    if (!map[name]) {
      map[name] = { customer_name: name, unread: 0, last_content: '', last_time: msg.created_at }
    }
    map[name].last_content = msg.content
    if (msg.created_at > map[name].last_time) {
      map[name].last_time = msg.created_at
    }
    // 只有客户发的且未读的才算未读
    if (msg.sender === 'customer' && !msg.is_read) {
      map[name].unread++
    }
  })
  return Object.values(map).sort((a, b) => new Date(b.last_time) - new Date(a.last_time))
})

onMounted(() => {
  loadMessages()
  startPolling()
})

onUnmounted(() => {
  stopPolling()
})

function startPolling() {
  stopPolling()
  pollTimer = setInterval(loadMessages, 3000)
}

function stopPolling() {
  if (pollTimer) {
    clearInterval(pollTimer)
    pollTimer = null
  }
}

async function loadMessages() {
  const { data, error } = await supabase
    .from('messages')
    .select('*')
    .order('created_at', { ascending: false })
    .limit(200)
  if (!error) {
    messages.value = data || []
    // 如果当前有打开的对话，刷新聊天消息
    if (activeCustomer.value) {
      refreshChatMessages()
    }
  }
}

function refreshChatMessages() {
  if (!activeCustomer.value) return
  chatMessages.value = messages.value
    .filter(m => m.customer_name === activeCustomer.value)
    .reverse()
  scrollToBottom()
}

async function openConversation(name) {
  activeCustomer.value = name
  refreshChatMessages()
  // 标记该客户的所有消息为已读
  await supabase
    .from('messages')
    .update({ is_read: true })
    .eq('customer_name', name)
    .eq('sender', 'customer')
    .eq('is_read', false)
  loadMessages()
}

async function sendReply() {
  const content = chatInput.value.trim()
  if (!content || !activeCustomer.value) return
  chatInput.value = ''

  const { error } = await supabase.from('messages').insert({
    customer_name: activeCustomer.value,
    sender: 'admin',
    content,
    is_read: false
  })
  if (error) {
    alert('发送失败：' + error.message)
    return
  }
  await   loadMessages()
}

async function deleteConversation(customerName) {
  if (!confirm(`确定删除「${customerName}」的所有纸条消息？\n删除后不可恢复。`)) return
  const { error } = await supabase
    .from('messages')
    .delete()
    .eq('customer_name', customerName)
  if (error) {
    alert('删除失败：' + error.message)
    return
  }
  // 如果当前打开的就是这个对话，关闭它
  if (activeCustomer.value === customerName) {
    activeCustomer.value = null
  }
  await loadMessages()
}

async function deleteMessage(msgId) {
  if (!confirm('确定删除这条消息？')) return
  const { error } = await supabase.from('messages').delete().eq('id', msgId)
  if (error) {
    alert('删除失败：' + error.message)
    return
  }
  await loadMessages()
}

function scrollToBottom() {
  nextTick(() => {
    if (chatRef.value) {
      chatRef.value.scrollTop = chatRef.value.scrollHeight
    }
  })
}

function formatTime(dt) {
  if (!dt) return ''
  const d = new Date(dt)
  const now = new Date()
  const diff = now - d
  if (diff < 60000) return '刚刚'
  if (diff < 3600000) return Math.floor(diff / 60000) + '分钟前'
  if (diff < 86400000) return Math.floor(diff / 3600000) + '小时前'
  const isThisYear = d.getFullYear() === now.getFullYear()
  if (isThisYear) return `${d.getMonth()+1}/${d.getDate()}`
  return `${d.getFullYear()}/${d.getMonth()+1}/${d.getDate()}`
}

function formatChatTime(dt) {
  if (!dt) return ''
  const d = new Date(dt)
  const now = new Date()
  const isToday = d.toDateString() === now.toDateString()
  const time = `${String(d.getHours()).padStart(2,'0')}:${String(d.getMinutes()).padStart(2,'0')}`
  if (isToday) return time
  return `${d.getMonth()+1}/${d.getDate()} ${time}`
}

async function logout() {
  await supabase.auth.signOut()
  window.location.href = '/admin'
}
</script>

<style scoped>
.admin-msgs { max-width: 600px; margin: 0 auto; padding-bottom: 20px; }

.admin-top {
  display: flex; align-items: center; justify-content: space-between;
  padding: 10px 16px; background: var(--primary); color: #fff;
}
.admin-top h2 { font-size: 16px; }
.top-nav { display: flex; gap: 5px; align-items: center; }
.top-nav .btn-nav {
  padding: 4px 9px; border-radius: 6px; font-size: 12px;
  color: #fff; background: rgba(255,255,255,0.18); border: none;
}
.top-nav .btn-nav.active-nav {
  background: rgba(255,255,255,0.4); font-weight: 600;
}
.top-nav .btn-logout {
  padding: 4px 9px; border-radius: 6px; font-size: 12px;
  color: #fff; background: rgba(255,255,255,0.15);
  border: 1px solid rgba(255,255,255,0.3);
}
.top-nav .version-badge {
  font-size: 11px; color: rgba(255,255,255,0.7);
  background: rgba(0,0,0,0.18); padding: 2px 8px; border-radius: 10px;
  white-space: nowrap; margin-left: 4px;
}

/* 会话列表 */
.conversation-list { padding: 12px; }
.conv-del-btn {
  background: none; border: none; font-size: 16px; cursor: pointer;
  padding: 4px 6px; border-radius: 6px; flex-shrink: 0;
  opacity: 0; transition: opacity 0.15s;
}
.conv-card:hover .conv-del-btn { opacity: 0.6; }
.conv-card .conv-del-btn:hover { opacity: 1; background: rgba(255,77,79,0.1); }
.empty-tip { text-align: center; color: #aaa; padding: 40px 0; font-size: 14px; }
.conv-card {
  display: flex; gap: 12px; align-items: center;
  background: #fff; border-radius: 12px; padding: 14px;
  margin-bottom: 10px; cursor: pointer;
  border: 1.5px solid transparent;
}
.conv-card.active { border-color: var(--primary); background: var(--primary-light); }
.conv-avatar {
  width: 44px; height: 44px; border-radius: 50%;
  background: var(--primary-gradient); color: #fff;
  display: flex; align-items: center; justify-content: center;
  font-size: 18px; font-weight: 600; flex-shrink: 0;
}
.conv-info { flex: 1; min-width: 0; }
.conv-header { display: flex; align-items: center; gap: 8px; margin-bottom: 4px; }
.conv-name { font-size: 15px; font-weight: 600; }
.conv-unread {
  background: #ff4d4f; color: #fff; font-size: 11px;
  min-width: 20px; height: 20px; border-radius: 10px;
  display: flex; align-items: center; justify-content: center;
  padding: 0 6px; font-weight: 600;
}
.conv-last-msg {
  font-size: 13px; color: var(--text-secondary);
  white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
}
.conv-time { font-size: 11px; color: #bbb; margin-top: 2px; }

/* 聊天弹窗 */
.modal-mask {
  position: fixed; inset: 0; background: rgba(0,0,0,0.5);
  display: flex; align-items: flex-end; justify-content: center; z-index: 300;
}
.modal-box {
  background: #fff; border-radius: 16px 16px 0 0; width: 100%;
  max-width: 480px; max-height: 85vh; overflow: hidden;
}
.chat-modal-box { display: flex; flex-direction: column; max-height: 80vh; }
.chat-header {
  display: flex; justify-content: space-between; align-items: center;
  padding: 16px; border-bottom: 1px solid var(--border);
}
.chat-header h3 { font-size: 16px; }
.chat-close-btn {
  width: 32px; height: 32px; border-radius: 50%; border: none;
  background: rgba(0,0,0,0.1); color: #666; font-size: 16px;
  cursor: pointer; display: flex; align-items: center; justify-content: center;
}
.chat-messages {
  flex: 1; overflow-y: auto; padding: 16px;
  display: flex; flex-direction: column; gap: 10px;
  min-height: 300px; max-height: 400px;
}
.chat-msg { max-width: 80%; padding: 10px 14px; border-radius: 12px; font-size: 14px; }
.chat-msg.customer {
  align-self: flex-start; background: #f0f0f0; color: var(--text);
  border-bottom-left-radius: 4px;
}
.chat-msg.admin {
  align-self: flex-end; background: var(--primary); color: #fff;
  border-bottom-right-radius: 4px;
}
.chat-content { word-break: break-word; line-height: 1.5; }
.chat-time {
  font-size: 11px; margin-top: 4px; text-align: right;
}
.chat-msg.customer .chat-time { color: #aaa; }
.chat-msg.admin .chat-time { color: rgba(255,255,255,0.6); }
.chat-empty { text-align: center; color: #aaa; font-size: 13px; padding: 40px 0; }
.chat-input {
  display: flex; gap: 8px; padding: 12px 16px;
  border-top: 1px solid var(--border);
}
.chat-input input {
  flex: 1; padding: 10px 14px; border: 1px solid #ddd;
  border-radius: 24px; font-size: 14px;
}
.chat-input button {
  padding: 10px 20px; background: var(--primary); color: #fff;
  border-radius: 24px; font-size: 14px;
}
.chat-input button:disabled { opacity: 0.5; }
.chat-del-btn {
  color: #ff4d4f; font-size: 11px; cursor: pointer; margin-left: 8px;
  padding: 1px 6px; border-radius: 4px;
}
.chat-del-btn:hover { background: rgba(255,77,79,0.1); }
</style>
