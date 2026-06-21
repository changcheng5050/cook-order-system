<template>
  <div class="admin-customers">
    <header class="admin-top">
      <h2>客户管理</h2>
      <div class="top-nav">
        <button class="btn-nav" @click="$router.push('/admin/dishes')">菜品</button>
        <button class="btn-nav active-nav" @click="$router.push('/admin/customers')">客户</button>
        <button class="btn-nav" @click="$router.push('/admin/orders')">订单</button>
        <button class="btn-nav" @click="$router.push('/admin/messages')">纸条</button>
        <button class="btn-nav" @click="$router.push('/admin/logs')">日志</button>
        <button class="btn-nav" @click="$router.push('/admin/settings')">设置</button>
        <button class="btn-logout" @click="logout">退出</button>
        <span class="version-badge">v2.3.0</span>
      </div>
    </header>

    <!-- 待审核列表 -->
    <div class="pending-section" v-if="pendingCustomers.length > 0">
      <div class="section-title">
        <h3>📋 待审核（{{ pendingCustomers.length }}）</h3>
      </div>
      <div v-for="c in pendingCustomers" :key="c.id" class="pending-card">
        <div class="pending-info">
          <h4>{{ c.name }}</h4>
          <p v-if="c.applied_at" class="pending-time">申请时间：{{ formatTime(c.applied_at) }}</p>
        </div>
        <div class="pending-actions">
          <button class="btn-approve" @click="approveCustomer(c)">✅ 通过</button>
          <button class="btn-reject" @click="rejectCustomer(c)">❌ 拒绝</button>
        </div>
      </div>
    </div>

    <div class="pending-section" v-else>
      <div class="section-title">
        <h3>📋 待审核</h3>
      </div>
      <p class="empty-tip">暂无待审核的客户申请</p>
    </div>

    <!-- 新增客户表单 -->
    <div class="add-section">
      <h3>📝 新增客户</h3>
      <div class="add-form">
        <input v-model="newName" placeholder="客户姓名 *" class="form-input" />
        <input v-model="newPhone" placeholder="手机号（选填）" class="form-input" />
        <input v-model="newAddress" placeholder="地址（选填）" class="form-input" />
        <input v-model="newNote" placeholder="备注（选填）" class="form-input" />
        <button class="btn-add" @click="addCustomer">添加</button>
      </div>
      <p v-if="addError" class="error-msg">{{ addError }}</p>
    </div>

    <!-- 已通过客户列表 + 搜索 -->
    <div class="list-section">
      <div class="list-header">
        <h3>已通过（共 {{ approvedCustomers.length }} 人）</h3>
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
        <div class="customer-actions">
          <button class="btn-edit" @click="openEdit(c)">✏️ 编辑</button>
          <button class="btn-delete" @click="deleteCustomer(c)">删除</button>
        </div>
      </div>
    </div>

    <!-- 编辑客户弹窗 -->
    <div v-if="editCustomer" class="modal-mask" @click.self="editCustomer = null">
      <div class="modal-box edit-modal">
        <h3>✏️ 编辑客户 - {{ editCustomer.name }}</h3>
        <div class="edit-form">
          <label>手机号</label>
          <input v-model="editForm.phone" placeholder="手机号" class="form-input" />
          <label>地址</label>
          <input v-model="editForm.address" placeholder="地址" class="form-input" />
          <label>备注</label>
          <input v-model="editForm.note" placeholder="备注" class="form-input" />
        </div>
        <div class="edit-actions">
          <button class="btn-cancel" @click="editCustomer = null">取消</button>
          <button class="btn-save-edit" @click="saveEdit" :disabled="savingEdit">保存修改</button>
        </div>
        <p v-if="editMsg" class="edit-msg">{{ editMsg }}</p>
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

// 编辑客户
const editCustomer = ref(null)
const editForm = ref({ phone: '', address: '', note: '' })
const savingEdit = ref(false)
const editMsg = ref('')

// 待审核用户
const pendingCustomers = computed(() =>
  customers.value.filter(c => c.status === 'pending')
)

// 已通过用户
const approvedCustomers = computed(() =>
  customers.value.filter(c => c.status !== 'pending')
)

const filteredCustomers = computed(() => {
  if (!searchKey.value) return approvedCustomers.value
  const key = searchKey.value.toLowerCase()
  return approvedCustomers.value.filter(c =>
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
  if (!error) {
    customers.value = data || []
    // 保险：兼容 status 列不存在的情况，默认视为 approved
    customers.value.forEach(c => {
      if (!c.status) c.status = 'approved'
    })
  }
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
    note: newNote.value.trim() || null,
    status: 'approved'
  }).select('id')
  if (error) {
    console.error('添加客户失败:', error)
    if (error.message.includes('unique') || error.code === '23505') {
      addError.value = '该客户姓名已存在'
    } else {
      addError.value = '添加失败：' + error.message
    }
    return
  }
  newName.value = ''
  newPhone.value = ''
  newAddress.value = ''
  newNote.value = ''
  loadCustomers()
}

// 审核通过
async function approveCustomer(c) {
  const { error } = await supabase
    .from('customers')
    .update({ status: 'approved' })
    .eq('id', c.id)
  if (error) {
    alert('操作失败：' + error.message)
    return
  }
  loadCustomers()
}

// 编辑客户
function openEdit(c) {
  editCustomer.value = c
  editForm.value = { phone: c.phone || '', address: c.address || '', note: c.note || '' }
  editMsg.value = ''
}

async function saveEdit() {
  if (!editCustomer.value) return
  savingEdit.value = true
  editMsg.value = ''
  const { error } = await supabase
    .from('customers')
    .update({
      phone: editForm.value.phone.trim() || null,
      address: editForm.value.address.trim() || null,
      note: editForm.value.note.trim() || null
    })
    .eq('id', editCustomer.value.id)
  savingEdit.value = false
  if (error) {
    editMsg.value = '保存失败：' + error.message
    return
  }
  editMsg.value = '✅ 保存成功！'
  editCustomer.value = null
  loadCustomers()
}
async function rejectCustomer(c) {
  if (!confirm(`拒绝「${c.name}」的申请？该记录将被删除。`)) return
  const { error } = await supabase.from('customers').delete().eq('id', c.id)
  if (error) {
    alert('操作失败：' + error.message)
    return
  }
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

function formatTime(dt) {
  if (!dt) return ''
  const d = new Date(dt)
  return `${d.getMonth()+1}月${d.getDate()}日 ${String(d.getHours()).padStart(2,'0')}:${String(d.getMinutes()).padStart(2,'0')}`
}

async function logout() {
  await supabase.auth.signOut()
  window.location.href = '/admin'
}
</script>

<style scoped>
.admin-customers { max-width: 600px; margin: 0 auto; padding-bottom: 80px; }

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

/* 待审核区域 */
.pending-section {
  background: #fff7e6; margin: 12px; border-radius: 12px; padding: 16px;
  border: 1.5px solid #ffd591;
}
.section-title h3 { font-size: 15px; margin-bottom: 12px; }
.pending-card {
  display: flex; justify-content: space-between; align-items: center;
  padding: 10px 14px; background: #fff; border-radius: 10px;
  margin-bottom: 8px; border: 1px solid #ffe7ba;
}
.pending-card:last-child { margin-bottom: 0; }
.pending-info h4 { font-size: 15px; color: #d46b08; }
.pending-time { font-size: 11px; color: #999; margin-top: 2px; }
.pending-actions { display: flex; gap: 8px; flex-shrink: 0; }
.btn-approve {
  padding: 6px 14px; background: #52c41a; color: #fff;
  border-radius: 6px; font-size: 13px; font-weight: 500;
}
.btn-reject {
  padding: 6px 14px; background: #fff; color: #ff4d4f;
  border: 1px solid #ff4d4f; border-radius: 6px; font-size: 13px;
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
.list-header { display: flex; align-items: center; gap: 10px; margin-bottom: 12px; }
.list-header h3 {
  font-size: 15px; color: var(--text-secondary); margin-bottom: 0; white-space: nowrap;
}
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
.customer-actions { display: flex; gap: 6px; flex-shrink: 0; }
.btn-chat {
  padding: 6px 10px; background: #e6f7ff; color: #1890ff;
  border: 1px solid #91d5ff; border-radius: 6px; font-size: 12px;
}
.btn-delete {
  padding: 6px 12px; background: #fff; color: var(--danger);
  border: 1px solid var(--danger); border-radius: 6px; font-size: 12px;
}
.btn-edit {
  padding: 6px 10px; background: #e6f7ff; color: #1890ff;
  border: 1px solid #91d5ff; border-radius: 6px; font-size: 12px;
}

/* 编辑弹窗 */
.modal-mask {
  position: fixed; inset: 0; background: rgba(0,0,0,0.5);
  display: flex; align-items: center; justify-content: center; z-index: 300;
}
.modal-box {
  background: #fff; border-radius: 16px; width: 90%;
  max-width: 400px; padding: 24px;
}
.edit-modal h3 { font-size: 16px; margin-bottom: 16px; }
.edit-form label { font-size: 13px; font-weight: 500; display: block; margin: 10px 0 4px; }
.edit-form .form-input { width: 100%; padding: 8px 10px; border: 1px solid #ddd; border-radius: 8px; font-size: 14px; box-sizing: border-box; }
.edit-actions { display: flex; gap: 12px; margin-top: 20px; }
.btn-cancel {
  flex: 1; padding: 10px; border: 1.5px solid #ddd;
  border-radius: 8px; background: #fff; font-size: 14px;
}
.btn-save-edit {
  flex: 1; padding: 10px; background: var(--primary); color: #fff;
  border-radius: 8px; font-size: 14px;
}
.btn-save-edit:disabled { opacity: 0.6; }
.edit-msg { text-align: center; margin-top: 10px; font-size: 13px; color: #389e0d; }
</style>
