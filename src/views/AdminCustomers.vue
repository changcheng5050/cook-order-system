<template>
  <div class="admin-customers">
    <header class="admin-top">
      <h2>瀹㈡埛绠＄悊</h2>
      <div class="top-nav">
        <button class="btn-nav" @click="$router.push('/admin/dishes')">鑿滃搧</button>
        <button class="btn-nav active-nav" @click="$router.push('/admin/customers')">瀹㈡埛</button>
        <button class="btn-nav" @click="$router.push('/admin/orders')">璁㈠崟</button>
        <button class="btn-nav" @click="$router.push('/admin/settings')">璁剧疆</button>
        <button class="btn-logout" @click="logout">閫€鍑?/button>
        <span class="version-badge">v2.0.25</span>
      </div>
    </header>

    <!-- 鏂板瀹㈡埛琛ㄥ崟 -->
    <div class="add-section">
      <h3>鏂板瀹㈡埛</h3>
      <div class="add-form">
        <input v-model="newName" placeholder="瀹㈡埛濮撳悕 *" class="form-input" />
        <input v-model="newPhone" placeholder="鎵嬫満鍙凤紙閫夊～锛? class="form-input" />
        <input v-model="newAddress" placeholder="鍦板潃锛堥€夊～锛? class="form-input" />
        <input v-model="newNote" placeholder="澶囨敞锛堥€夊～锛? class="form-input" />
        <button class="btn-add" @click="addCustomer">娣诲姞</button>
      </div>
      <p v-if="addError" class="error-msg">{{ addError }}</p>
    </div>

    <!-- 瀹㈡埛鍒楄〃 + 鎼滅储 -->
    <div class="list-section">
      <div class="list-header">
        <h3>瀹㈡埛鍒楄〃锛堝叡 {{ filteredCustomers.length }} 浜猴級</h3>
        <input v-model="searchKey" placeholder="馃攳 鎼滅储濮撳悕/鎵嬫満鍙?.." class="search-input" />
      </div>
      <div v-if="filteredCustomers.length === 0" class="empty-tip">鏈壘鍒板尮閰嶅鎴?/div>
      <div v-for="c in filteredCustomers" :key="c.id" class="customer-card">
        <div class="customer-info">
          <h4>{{ c.name }}</h4>
          <p v-if="c.phone">馃摫 {{ c.phone }}</p>
          <p v-if="c.address">馃彔 {{ c.address }}</p>
          <p v-if="c.note" class="customer-note">馃摑 {{ c.note }}</p>
        </div>
        <button class="btn-delete" @click="deleteCustomer(c)">鍒犻櫎</button>
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
    addError.value = '瀹㈡埛濮撳悕涓嶈兘涓虹┖'
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
    console.error('娣诲姞瀹㈡埛澶辫触:', error)
    if (error.message.includes('unique') || error.code === '23505') {
      addError.value = '璇ュ鎴峰鍚嶅凡瀛樺湪锛屼笉鑳介噸澶?
    } else if (error.message.includes('row-level') || error.code === '42501') {
      addError.value = '鏉冮檺涓嶈冻锛岃鍦?Supabase 鎵ц upgrade-v2.sql'
    } else {
      addError.value = '娣诲姞澶辫触锛? + error.message
    }
    return
  }
  // 娓呯┖琛ㄥ崟
  newName.value = ''
  newPhone.value = ''
  newAddress.value = ''
  newNote.value = ''
  loadCustomers()
}

async function deleteCustomer(c) {
  if (!confirm(`纭畾鍒犻櫎瀹㈡埛銆?{c.name}銆嶏紵\n鍒犻櫎鍚庤瀹㈡埛灏嗘棤娉曠櫥褰曪紝鍘嗗彶璁㈠崟浼氫繚鐣欍€俙)) return
  const { error } = await supabase.from('customers').delete().eq('id', c.id)
  if (error) {
    alert('鍒犻櫎澶辫触锛? + error.message)
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
