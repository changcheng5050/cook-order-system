<template>
  <div class="admin-page">
    <header class="admin-header">
      <h1>菜品管理</h1>
      <div class="header-actions">
        <button class="btn-nav" @click="$router.push('/admin/customers')">客户</button>
        <button class="btn-nav" @click="$router.push('/admin/orders')">订单</button>
        <button class="btn-settings" @click="$router.push('/admin/settings')">设置</button>
        <button class="btn-logout" @click="logout">退出</button>
        <span class="version-badge">v2.0.11</span>
      </div>
    </header>

    <!-- 新增菜品按钮 + 搜索 -->
    <div class="toolbar">
      <button class="btn-add" @click="openAddModal">+ 新增菜品</button>
      <input v-model="searchKey" placeholder="🔍 搜索菜名..." class="search-input" />
      <select v-model="filterCategory" class="filter-select">
        <option value="">全部分类</option>
        <option v-for="c in categoryOptions" :key="c" :value="c">{{ c }}</option>
      </select>
      <select v-model="filterActive" class="filter-select">
        <option value="all">全部</option>
        <option value="active">上架中</option>
        <option value="inactive">已下架</option>
      </select>
    </div>

    <!-- 菜品列表 -->
    <div class="dish-admin-list">
      <div v-for="dish in filteredList" :key="dish.id" class="dish-admin-card">
        <img v-if="dish.image_url" :src="dish.image_url" class="admin-dish-img" />
        <div v-else class="admin-img-placeholder">无图</div>
        <div class="admin-dish-info">
          <h3>{{ dish.name }}</h3>
          <p>{{ dish.category }} | {{ dish.temperature }} | {{ dish.cook_time }}分钟</p>
          <p class="flavor-tags">
            <span v-for="f in dish.flavor" :key="f" class="tag">{{ f }}</span>
          </p>
          <p v-if="dish.notes" class="dish-note-text">📝 {{ dish.notes }}</p>
        </div>
        <div class="admin-dish-actions">
          <button class="btn-edit" @click="openEditModal(dish)">编辑</button>
          <button :class="dish.is_active ? 'btn-unlist' : 'btn-list'" @click="toggleActive(dish)">{{ dish.is_active ? '下架' : '上架' }}</button>
          <button class="btn-del" @click="deleteDish(dish.id)">删除</button>
        </div>
      </div>
      <div v-if="filteredList.length === 0" class="empty-tip">暂无菜品</div>
    </div>

    <!-- 新增/编辑弹窗 -->
    <div v-if="showModal" class="modal-mask" @click.self="closeModal">
      <div class="modal-box admin-modal">
        <h2>{{ isEdit ? '编辑菜品' : '新增菜品' }}</h2>

        <label>菜名 *</label>
        <input v-model="form.name" placeholder="请输入菜名" />

        <label>分类 *</label>
        <select v-model="form.category">
          <option v-for="c in categoryOptions" :key="c" :value="c">{{ c }}</option>
        </select>

        <label>温度 *</label>
        <select v-model="form.temperature">
          <option value="热菜">热菜</option>
          <option value="凉菜">凉菜</option>
        </select>

        <label>耗时（分钟）*</label>
        <input v-model.number="form.cook_time" type="number" min="1" />

        <label>口味标签</label>
        <div class="tag-input-row">
          <input v-model="tagInput" placeholder="输入标签后回车或点击添加" @keyup.enter="addTag" />
          <button type="button" class="btn-add-tag" @click="addTag">+ 添加</button>
        </div>
        <div class="tags-edit">
          <span v-for="(f, idx) in form.flavor" :key="idx" class="tag">
            {{ f }} <span @click="form.flavor.splice(idx, 1)">✕</span>
          </span>
        </div>

        <label>食材 *（名称和用量）</label>
        <div v-for="(ing, idx) in form.ingredients" :key="idx" class="kv-row">
          <input v-model="ing.name" placeholder="食材名" />
          <input v-model="ing.amount" placeholder="用量" />
          <button @click="form.ingredients.splice(idx, 1)">✕</button>
        </div>
        <button class="btn-add-row" @click="form.ingredients.push({name:'',amount:''})">+ 添加食材</button>

        <label>调料 *（名称和用量）</label>
        <div v-for="(s, idx) in form.seasonings" :key="idx" class="kv-row">
          <input v-model="s.name" placeholder="调料名" />
          <input v-model="s.amount" placeholder="用量" />
          <button @click="form.seasonings.splice(idx, 1)">✕</button>
        </div>
        <button class="btn-add-row" @click="form.seasonings.push({name:'',amount:''})">+ 添加调料</button>

        <label>备注</label>
        <textarea v-model="form.notes" placeholder="如：含葱姜蒜，忌口请提前告知"></textarea>

        <label>菜品图片</label>
        <input type="file" accept="image/*" @change="uploadImage" :disabled="uploading" />
        <div v-if="form.image_url" class="preview-img-wrap">
          <img :src="form.image_url" class="preview-img" />
          <button @click="form.image_url = ''">移除图片</button>
        </div>
        <p v-if="uploading" class="upload-tip">上传中...</p>

        <div class="modal-actions">
          <button @click="closeModal">取消</button>
          <button class="btn-save" @click="saveDish">{{ isEdit ? '保存修改' : '新增' }}</button>
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
const dishes = ref([])
const showModal = ref(false)
const isEdit = ref(false)
const editingId = ref(null)
const filterCategory = ref('')
const filterActive = ref('all')
const searchKey = ref('')
const tagInput = ref('')
const uploading = ref(false)

const categoryOptions = ['荤菜', '素菜', '汤类', '粉面类', '主食']

const form = ref({
  name: '',
  category: '荤菜',
  temperature: '热菜',
  cook_time: 0,
  flavor: [],
  ingredients: [],
  seasonings: [],
  notes: '',
  image_url: '',
  is_active: true
})

const filteredList = computed(() => {
  let list = dishes.value
  if (searchKey.value) {
    const key = searchKey.value.toLowerCase()
    list = list.filter(d => d.name.toLowerCase().includes(key))
  }
  if (filterCategory.value) list = list.filter(d => d.category === filterCategory.value)
  if (filterActive.value === 'active') list = list.filter(d => d.is_active)
  if (filterActive.value === 'inactive') list = list.filter(d => !d.is_active)
  return list
})

onMounted(() => {
  checkAuth()
  loadDishes()
})

async function checkAuth() {
  const { data } = await supabase.auth.getSession()
  if (!data.session) router.push('/admin')
}

async function loadDishes() {
  const { data } = await supabase.from('dishes').select('*').order('created_at', { ascending: false })
  dishes.value = data || []
}

function openAddModal() {
  isEdit.value = false
  editingId.value = null
  form.value = {
    name: '', category: '荤菜', temperature: '热菜', cook_time: 0,
    flavor: [], ingredients: [{name:'',amount:'适量'}], seasonings: [{name:'',amount:'适量'}],
    notes: '', image_url: '', is_active: true
  }
  showModal.value = true
}

function openEditModal(dish) {
  isEdit.value = true
  editingId.value = dish.id
  form.value = {
    name: dish.name,
    category: dish.category,
    temperature: dish.temperature,
    cook_time: dish.cook_time,
    flavor: [...(dish.flavor || [])],
    ingredients: (dish.ingredients || []).length ? [...dish.ingredients] : [{name:'',amount:''}],
    seasonings: (dish.seasonings || []).length ? [...dish.seasonings] : [{name:'',amount:''}],
    notes: dish.notes || '',
    image_url: dish.image_url || '',
    is_active: dish.is_active
  }
  showModal.value = true
}

function addTag() {
  const t = tagInput.value.trim()
  if (t && !form.value.flavor.includes(t)) form.value.flavor.push(t)
  tagInput.value = ''
}

/**
 * 压缩图片
 * @param {File} file - 原始图片文件
 * @returns {Promise<Blob>} - 压缩后的图片 Blob
 */
function compressImage(file) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader()
    reader.onload = (e) => {
      const img = new Image()
      img.onload = () => {
        // 计算压缩后的尺寸（最大宽度 800px）
        let { width, height } = img
        const MAX_WIDTH = 800
        if (width > MAX_WIDTH) {
          height = Math.round(height * MAX_WIDTH / width)
          width = MAX_WIDTH
        }

        // 用 Canvas 压缩
        const canvas = document.createElement('canvas')
        canvas.width = width
        canvas.height = height
        const ctx = canvas.getContext('2d')
        ctx.drawImage(img, 0, 0, width, height)

        // 转成 Blob（质量 0.7 = 70%）
        canvas.toBlob(
          (blob) => {
            if (blob) resolve(blob)
            else reject(new Error('压缩失败'))
          },
          'image/jpeg',
          0.7
        )
      }
      img.onerror = reject
      img.src = e.target.result
    }
    reader.onerror = reject
    reader.readAsDataURL(file)
  })
}

async function uploadImage(e) {
  const file = e.target.files[0]
  if (!file) return
  uploading.value = true

  // 压缩图片
  let fileToUpload = file
  try {
    const compressedBlob = await compressImage(file)
    fileToUpload = new File([compressedBlob], file.name, { type: 'image/jpeg' })
    console.log(`图片压缩完成：${(file.size/1024).toFixed(1)}KB → ${(fileToUpload.size/1024).toFixed(1)}KB`)
  } catch (err) {
    console.warn('图片压缩失败，使用原图:', err)
    fileToUpload = file
  }

  const ext = file.name.split('.').pop() || 'jpg'
  const fileName = `dish-${Date.now()}-${Math.random().toString(36).slice(2, 8)}.${ext}`
  const { data, error } = await supabase.storage.from('dish-images').upload(fileName, fileToUpload)
  if (!error) {
    const { data: { publicUrl } } = supabase.storage.from('dish-images').getPublicUrl(fileName)
    form.value.image_url = publicUrl
  } else {
    console.error('上传图片失败:', error)
    let msg = '上传失败：' + error.message
    if (error.message.includes('Bucket not found') || error.message.includes('bucket')) {
      msg = '存储桶不存在！请在 Supabase SQL Editor 执行 supabase/init-storage.sql 脚本'
    }
    alert(msg)
  }
  uploading.value = false
}

async function saveDish() {
  if (!form.value.name) return alert('请输入菜名')
  if (!form.value.cook_time) return alert('请输入耗时')
  const payload = {
    name: form.value.name,
    category: form.value.category,
    temperature: form.value.temperature,
    cook_time: form.value.cook_time,
    flavor: form.value.flavor,
    ingredients: form.value.ingredients.filter(i => i.name),
    seasonings: form.value.seasonings.filter(s => s.name),
    notes: form.value.notes,
    image_url: form.value.image_url
  }
  let error
  if (isEdit.value) {
    ;({ error } = await supabase.from('dishes').update(payload).eq('id', editingId.value))
  } else {
    ;({ error } = await supabase.from('dishes').insert(payload))
  }
  if (error) {
    alert('保存失败：' + error.message)
  } else {
    closeModal()
    loadDishes()
  }
}

async function toggleActive(dish) {
  await supabase.from('dishes').update({ is_active: !dish.is_active }).eq('id', dish.id)
  loadDishes()
}

async function deleteDish(id) {
  if (!confirm('确定删除这道菜？')) return
  await supabase.from('dishes').delete().eq('id', id)
  loadDishes()
}

function closeModal() {
  showModal.value = false
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
  border-bottom: 1px solid var(--border); flex-wrap: wrap;
}
.btn-add {
  padding: 6px 14px; background: var(--primary); color: #fff;
  border-radius: 8px; font-size: 13px; white-space: nowrap;
}
.filter-select {
  padding: 6px 8px; border: 1px solid #ddd; border-radius: 8px; font-size: 13px;
}
.search-input {
  flex: 1; min-width: 100px; padding: 6px 10px;
  border: 1px solid #ddd; border-radius: 8px; font-size: 13px;
}

.dish-admin-list { padding: 12px; }
.dish-admin-card {
  display: flex; gap: 10px; background: #fff; border-radius: 12px;
  padding: 12px; margin-bottom: 10px; align-items: flex-start;
}
.admin-dish-img { width: 60px; height: 60px; border-radius: 8px; object-fit: cover; flex-shrink: 0; }
.admin-img-placeholder {
  width: 60px; height: 60px; border-radius: 8px; background: #f0f0f0;
  display: flex; align-items: center; justify-content: center;
  font-size: 11px; color: #aaa; flex-shrink: 0;
}
.admin-dish-info { flex: 1; min-width: 0; }
.admin-dish-info h3 { font-size: 14px; margin-bottom: 2px; }
.admin-dish-info p { font-size: 12px; color: var(--text-secondary); }
.flavor-tags { display: flex; gap: 4px; flex-wrap: wrap; margin-top: 2px; }
.tag {
  font-size: 11px; padding: 1px 6px; border-radius: 4px;
  background: var(--primary-light); color: var(--primary);
}
.dish-note-text { color: #e55a2b !important; font-size: 11px !important; }
.admin-dish-actions { display: flex; flex-direction: column; gap: 4px; flex-shrink: 0; }
.admin-dish-actions button {
  padding: 4px 12px; border-radius: 6px; font-size: 11px;
  background: #f0f0f0; color: var(--text);
}
.btn-edit { background: #e8f0fe !important; color: #1677ff !important; }
.btn-list { background: #e6f7ee !important; color: #00a870 !important; }
.btn-unlist { background: #fff7e6 !important; color: #fa8c16 !important; }
.btn-del { background: #fff0f0 !important; color: var(--danger) !important; }
.empty-tip { text-align: center; color: var(--text-secondary); padding: 40px 0; font-size: 13px; }

/* 弹窗 */
.modal-mask {
  position: fixed; inset: 0; background: rgba(0,0,0,0.5);
  display: flex; align-items: center; justify-content: center; z-index: 200;
}
.modal-box {
  background: #fff; border-radius: 16px; width: 90%; max-width: 420px;
  max-height: 85vh; overflow-y: auto; padding: 20px;
}
.admin-modal label { display: block; font-size: 13px; font-weight: 500; margin: 10px 0 4px; }
.admin-modal input, .admin-modal select, .admin-modal textarea {
  width: 100%; padding: 8px 10px; border: 1px solid #ddd; border-radius: 8px;
  font-size: 13px; margin-bottom: 4px;
}
.admin-modal textarea { min-height: 60px; resize: vertical; }
.tag-input-row { display: flex; gap: 6px; margin-bottom: 4px; }
.tag-input-row input { flex: 1; }
.btn-add-tag {
  padding: 7px 14px; border-radius: 8px; font-size: 13px;
  background: var(--primary); color: #fff; border: none; cursor: pointer;
  white-space: nowrap; font-weight: 500; flex-shrink: 0;
}
.btn-add-tag:hover { opacity: 0.85; }
.tags-edit { display: flex; gap: 4px; flex-wrap: wrap; margin-bottom: 8px; }
.tags-edit .tag span { cursor: pointer; margin-left: 2px; }
.kv-row { display: flex; gap: 6px; margin-bottom: 4px; align-items: center; }
.kv-row input { flex: 1; }
.kv-row button {
  width: 24px; height: 24px; border-radius: 50%; background: #f0f0f0;
  color: #999; font-size: 12px; flex-shrink: 0;
}
.btn-add-row {
  font-size: 12px; color: var(--primary); background: none; margin-bottom: 8px;
}
.preview-img-wrap { margin: 8px 0; }
.preview-img { width: 100%; max-height: 150px; object-fit: cover; border-radius: 8px; }
.upload-tip { font-size: 12px; color: var(--text-secondary); }
.modal-actions { display: flex; gap: 12px; margin-top: 16px; }
.modal-actions button { flex: 1; padding: 10px; border-radius: 8px; }
.modal-actions .btn-save { background: var(--primary); color: #fff; font-weight: 500; }
</style>
