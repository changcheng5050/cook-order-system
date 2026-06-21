<template>
  <div class="admin-logs">
    <header class="admin-top">
      <div class="top-nav">
        <button class="btn-nav" @click="$router.push('/admin/dishes')">菜品</button>
        <button class="btn-nav" @click="$router.push('/admin/customers')">客户</button>
        <button class="btn-nav" @click="$router.push('/admin/orders')">订单</button>
        <button class="btn-nav" @click="$router.push('/admin/messages')">纸条</button>
        <button class="btn-nav active-nav" @click="$router.push('/admin/logs')">日志</button>
        <button class="btn-nav" @click="$router.push('/admin/settings')">设置</button>
        <button class="btn-logout" @click="logout">退出</button>
      </div>
    </header>

    <div class="log-controls">
      <input v-model="searchName" placeholder="🔍 搜索客户名..." class="search-input" />
      <button class="btn-refresh" @click="loadLogs">🔄 刷新</button>
      <button class="btn-batch-del" :class="{ active: batchMode }" @click="toggleBatch">
        {{ batchMode ? '取消' : '批量删除' }}
      </button>
    </div>

    <div v-if="batchMode" class="batch-bar">
      <label class="batch-check-all">
        <input type="checkbox" :checked="allSelected" @change="toggleSelectAll" />
        全选
      </label>
      <span class="batch-count">已选 {{ selectedIds.length }} 条</span>
      <button class="btn-exec-del" @click="batchDelete" :disabled="selectedIds.length === 0">
        🗑️ 删除选中
      </button>
    </div>

    <div class="log-stats">
      共 <strong>{{ totalCount }}</strong> 条记录，每页30条
      <span v-if="filteredLogs.length > 0">
        · 最近访问：<strong>{{ filteredLogs[0].customer_name }}</strong> 于 {{ formatTime(filteredLogs[0].created_at) }}
      </span>
    </div>

    <div class="log-list">
      <div v-if="pagedLogs.length === 0" class="empty-tip">暂无访问记录</div>
      <div v-for="log in pagedLogs" :key="log.id" class="log-card">
        <input v-if="batchMode" type="checkbox" :checked="selectedIds.includes(log.id)" @change="toggleSelect(log.id)" class="log-checkbox" />
        <div class="log-avatar">{{ log.customer_name.charAt(0).toUpperCase() }}</div>
        <div class="log-info">
          <div class="log-name">{{ log.customer_name }}</div>
          <div class="log-time">{{ formatTime(log.created_at) }}</div>
        </div>
      </div>
    </div>

    <!-- 分页 -->
    <div v-if="totalPages > 1" class="pagination">
      <button :disabled="currentPage <= 1" @click="goPage(currentPage - 1)">‹</button>
      <template v-for="p in visiblePages" :key="p">
        <span v-if="p === '...'" class="page-dots">…</span>
        <button v-else :class="['page-btn', { active: p === currentPage }]" @click="goPage(p)">{{ p }}</button>
      </template>
      <button :disabled="currentPage >= totalPages" @click="goPage(currentPage + 1)">›</button>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { supabase } from '../lib/supabase'

const logs = ref([])
const searchName = ref('')
const currentPage = ref(1)
const pageSize = 30
const batchMode = ref(false)
const selectedIds = ref([])

const filteredLogs = computed(() => {
  if (!searchName.value) return logs.value
  const key = searchName.value.toLowerCase()
  return logs.value.filter(l => l.customer_name.toLowerCase().includes(key))
})

const totalCount = computed(() => filteredLogs.value.length)

const totalPages = computed(() => Math.ceil(totalCount.value / pageSize) || 1)

const pagedLogs = computed(() => {
  const start = (currentPage.value - 1) * pageSize
  return filteredLogs.value.slice(start, start + pageSize)
})

const visiblePages = computed(() => {
  const tp = totalPages.value
  const cp = currentPage.value
  if (tp <= 7) return Array.from({ length: tp }, (_, i) => i + 1)
  const pages = []
  if (cp <= 4) {
    pages.push(1, 2, 3, 4, 5, '...', tp)
  } else if (cp >= tp - 3) {
    pages.push(1, '...', tp - 4, tp - 3, tp - 2, tp - 1, tp)
  } else {
    pages.push(1, '...', cp - 1, cp, cp + 1, '...', tp)
  }
  return pages
})

const allSelected = computed(() =>
  batchMode.value && pagedLogs.value.length > 0 &&
  pagedLogs.value.every(l => selectedIds.value.includes(l.id))
)

onMounted(() => {
  loadLogs()
  setInterval(loadLogs, 30000)
})

function goPage(p) {
  if (p < 1 || p > totalPages.value) return
  currentPage.value = p
  window.scrollTo({ top: 0, behavior: 'smooth' })
}

function toggleBatch() {
  batchMode.value = !batchMode.value
  if (!batchMode.value) selectedIds.value = []
}

function toggleSelect(id) {
  const idx = selectedIds.value.indexOf(id)
  if (idx >= 0) {
    selectedIds.value.splice(idx, 1)
  } else {
    selectedIds.value.push(id)
  }
}

function toggleSelectAll() {
  if (allSelected.value) {
    selectedIds.value = []
  } else {
    selectedIds.value = pagedLogs.value.map(l => l.id)
  }
}

async function batchDelete() {
  if (selectedIds.value.length === 0) return
  if (!confirm(`确定删除选中的 ${selectedIds.value.length} 条访问记录？`)) return
  const { error } = await supabase
    .from('access_logs')
    .delete()
    .in('id', selectedIds.value)
  if (error) {
    alert('删除失败：' + error.message)
    return
  }
  selectedIds.value = []
  await loadLogs()
}

async function loadLogs() {
  const { data, error } = await supabase
    .from('access_logs')
    .select('*')
    .order('created_at', { ascending: false })
    .limit(500)
  if (!error) {
    logs.value = data || []
    // 清理已不存在的选中项
    selectedIds.value = selectedIds.value.filter(id => logs.value.some(l => l.id === id))
    // 如果当前页超出总页数，翻到最后一页
    if (currentPage.value > totalPages.value) {
      currentPage.value = totalPages.value
    }
  }
}

function formatTime(dt) {
  if (!dt) return ''
  const d = new Date(dt)
  const now = new Date()
  const isToday = d.toDateString() === now.toDateString()
  const time = `${String(d.getHours()).padStart(2,'0')}:${String(d.getMinutes()).padStart(2,'0')}`
  if (isToday) return `今天 ${time}`
  const yesterday = new Date(now)
  yesterday.setDate(yesterday.getDate() - 1)
  if (d.toDateString() === yesterday.toDateString()) return `昨天 ${time}`
  return `${d.getMonth()+1}月${d.getDate()}日 ${time}`
}

async function logout() {
  await supabase.auth.signOut()
  window.location.href = '/admin'
}
</script>

<style scoped>
.admin-logs { max-width: 600px; margin: 0 auto; padding-bottom: 20px; }

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

.log-controls {
  display: flex; gap: 8px; padding: 12px;
}
.search-input {
  flex: 1; padding: 8px 12px; border: 1px solid #ddd;
  border-radius: 8px; font-size: 13px;
}
.btn-refresh {
  padding: 8px 16px; background: var(--primary); color: #fff;
  border-radius: 8px; font-size: 13px; white-space: nowrap;
}
.btn-batch-del {
  padding: 8px 12px; border: 1.5px solid var(--danger); color: var(--danger);
  background: #fff; border-radius: 8px; font-size: 12px; white-space: nowrap;
}
.btn-batch-del.active { background: #fff2f0; }

.batch-bar {
  display: flex; align-items: center; gap: 8px;
  padding: 8px 12px; background: #fff2f0; margin: 0 12px 8px;
  border-radius: 8px; font-size: 13px;
}
.batch-check-all { display: flex; align-items: center; gap: 4px; cursor: pointer; }
.batch-count { flex: 1; color: var(--text-secondary); font-size: 12px; }
.btn-exec-del {
  padding: 6px 12px; background: var(--danger); color: #fff;
  border-radius: 6px; font-size: 12px;
}
.btn-exec-del:disabled { opacity: 0.5; }

.log-stats {
  font-size: 12px; color: var(--text-secondary); padding: 0 12px 8px;
}

.log-list { padding: 0 12px; }
.empty-tip { text-align: center; color: #aaa; padding: 40px 0; font-size: 14px; }
.log-card {
  display: flex; gap: 12px; align-items: center;
  background: #fff; border-radius: 10px; padding: 12px;
  margin-bottom: 8px;
}
.log-checkbox { width: 18px; height: 18px; cursor: pointer; flex-shrink: 0; }
.log-avatar {
  width: 36px; height: 36px; border-radius: 50%;
  background: var(--primary-gradient); color: #fff;
  display: flex; align-items: center; justify-content: center;
  font-size: 16px; font-weight: 600; flex-shrink: 0;
}
.log-info { flex: 1; }
.log-name { font-size: 14px; font-weight: 600; }
.log-time { font-size: 12px; color: var(--text-secondary); margin-top: 2px; }

/* 分页 */
.pagination {
  display: flex; justify-content: center; align-items: center;
  gap: 4px; padding: 16px 12px 24px;
}
.pagination button {
  min-width: 36px; height: 36px; border-radius: 8px;
  border: 1px solid #ddd; background: #fff; font-size: 14px;
  cursor: pointer; display: flex; align-items: center; justify-content: center;
}
.pagination button:disabled { opacity: 0.4; cursor: default; }
.pagination button.active {
  background: var(--primary); color: #fff; border-color: var(--primary);
  font-weight: 600;
}
.page-dots { padding: 0 4px; color: #999; font-size: 14px; }
</style>
