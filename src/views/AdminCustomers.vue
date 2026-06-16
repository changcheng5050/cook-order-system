<template>
  <div class="admin-customers">
    <header class="admin-top">
      <h2>客户管理</h2>
      <div class="top-nav">
        <button class="btn-nav" @click="$router.push('/admin/dishes')">菜品</button>
        <button class="btn-nav active-nav" @click="$router.push('/admin/customers')">客户</button>
        <button class="btn-nav" @click="$router.push('/admin/orders')">订单</button>
        <button class="btn-nav" @click="$router.push('/admin/settings')">设置</button>
        <button class="btn-logout" @click="logout">退出</button>
        <span class="version-badge">v2.2.0</span>
      </div>
    </header>

    <!-- 新增客户表单 -->
    <div class="add-section">
      <h3>新增客户</h3>
      <div class="add-form">
        <input v-model="newName" placeholder="客户姓名 *" class="form-input" />
        <input v-model="newPhone" placeholder="手机号（选填）" class="form-input" />
        <input v-model="newAddress" placeholder="地址（选填）" class="form-input" />
        <input v-model="newNote" placeholder="备注（选填）" class="form-input" />
        <button class="btn-add" @click="addCustomer">添加</button>
      </div>
      <p v-if="addError" class="error-msg">{{ addError }}</p>
    </div>

    <!-- 客户列表 + 搜索 -->
    <div class="list-section">
      <div class="list-header">
        <h3>客户列表（共 {{ filteredCustomers.length }} 人）</h3>
        <input v-model="searchKey" placeholder="🔍 搜索姓名/手机号..." class="search-input" />
      </div>
      <div v-if="filteredCustomers.length === 0" class="empty-tip">未找到匹配客户</div>
      <div v-for="c in filteredCustomers" :key="c.id" class="customer-card">
        <div class="customer-info">
          <h4>{{ c.name }}</h4>
          <p v-if="c.phone">📱 {{ c.phone }}</p>
          <p v-if="c.address">🏠 {{ c.address }}</p>
          <p v-if="c.note" class="customer-note">📝 {{ c.note }}</p>
        </div>
        <button class="btn-delete" @click="deleteCustomer(c)">删除</button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { supabase } from '../lib/supabase'

const customers = ref([])
const searchKey = ref('')
const newName = ref('')
const newPhone = ref('')
const newAddress = ref('')
const newNote = ref('')
const addError = ref('')

const filteredCustomers = computed(() => {
  if (!searchKey.value) return customers.value
  const key = searchKey.value.toLowerCase()
  return customers.value.filter(c =>
    c.name.toLowerCase().includes(key) ||
    (c.phone && c.phone.includes(key))
  )
})

onMounted(() => {
  loadCustomers()
})

async function loadCustomers() {
  const { data, error } = await supabase
    .from('customers')
    .select('*')
    .order('created_at', { ascending: false })
  if (!error) customers.value = data || []
}

async function addCustomer() {
  const name = newName.value.trim()
  if (!name) {
    addError.value = '客户姓名不能为空'
    return
  }
  addError.value = ''
  const { data, error } = await supabase.from('customers').insert({
    name,
    phone: newPhone.value.trim() || null,
    address: newAddress.value.trim() || null,
    note: newNote.value.trim() || null
  }).select('id')
  if (error) {
    console.error('添加客户失败:', error)
    if (error.message.includes('unique') || error.code === '23505') {
      addError.value = '该客户姓名已存在，不能重复'
    } else if (error.message.includes('row-level') || error.code === '42501') {
      addError.value = '权限不足，请在 Supabase 执行 upgrade-v2.sql'
    } else {
      addError.value = '添加失败：' + error.message
    }
    return
  }
  // 清空表单
  newName.value = ''
  newPhone.value = ''
  newAddress.value = ''
  newNote.value = ''
  loadCustomers()
}

async function deleteCustomer(c) {
  if (!confirm(`确定删除客户「${c.name}」？\n删除后该客户将无法登录，历史订单会保留。`)) return
  const { error } = await supabase.from('customers').delete().eq('id', c.id)
  if (error) {
    alert('删除失败：' + error.message)
    return
  }
  loadCustomers()
}
</script>

<style scoped>
.admin-customers { max-width: 600px; margin: 0 auto; padding-bottom: 20px; }

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

.add-section {
  background: #fff; margin: 12px; border-radius: 12px; padding: 16px;
}
.add-section h3 { font-size: 15px; margin-bottom: 12px; }
.add-form { display: grid; gap: 8px; }
.form-input {
  padding: 8px 10px; border: 1px solid #ddd; border-radius: 8px;
  font-size: 14px;
}
.btn-add {
  padding: 10px; background: var(--primary); color: #fff;
  border-radius: 8px; font-weight: 500;
}
.error-msg { color: #e55a2b; font-size: 12px; margin-top: 6px; }

.list-section {
  background: #fff; margin: 12px; border-radius: 12px; padding: 16px;
}
.list-section h3 { font-size: 15px; margin-bottom: 12px; color: var(--text-secondary); }
.list-header { display: flex; align-items: center; gap: 10px; margin-bottom: 12px; }
.list-header h3 { margin-bottom: 0; }
.search-input {
  flex: 1; min-width: 100px; padding: 6px 10px;
  border: 1px solid #ddd; border-radius: 8px; font-size: 13px;
}
.empty-tip { text-align: center; color: #aaa; padding: 20px 0; font-size: 13px; }

.customer-card {
  display: flex; justify-content: space-between; align-items: center;
  padding: 10px 0; border-bottom: 1px solid var(--border);
}
.customer-card:last-child { border-bottom: none; }
.customer-info h4 { font-size: 14px; margin-bottom: 2px; }
.customer-info p { font-size: 12px; color: var(--text-secondary); }
.customer-note { color: #e55a2b !important; }
.btn-delete {
  padding: 6px 12px; background: #fff; color: var(--danger);
  border: 1px solid var(--danger); border-radius: 6px; font-size: 12px;
}
</style>
