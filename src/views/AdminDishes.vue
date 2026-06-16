<template>
  <div class="admin-page">
    <header class="admin-header">
      <h1>鑿滃搧绠＄悊</h1>
      <div class="header-actions">
        <button class="btn-nav" @click="$router.push('/admin/customers')">瀹㈡埛</button>
        <button class="btn-nav" @click="$router.push('/admin/orders')">璁㈠崟</button>
        <button class="btn-settings" @click="$router.push('/admin/settings')">璁剧疆</button>
        <button class="btn-logout" @click="logout">閫€鍑?/button>
        <span class="version-badge">v2.0.25</span>
      </div>
    </header>

    <!-- 鏂板鑿滃搧鎸夐挳 + 鎼滅储 + 鎺掑簭 -->
    <div class="toolbar">
      <button class="btn-add" @click="openAddModal">+ 鏂板鑿滃搧</button>
      <input v-model="searchKey" placeholder="馃攳 鎼滅储鑿滃悕..." class="search-input" />
      <select v-model="filterCategory" class="filter-select">
        <option value="">鍏ㄩ儴鍒嗙被</option>
        <option v-for="c in categoryOptions" :key="c" :value="c">{{ c }}</option>
      </select>
      <select v-model="filterActive" class="filter-select">
        <option value="all">鍏ㄩ儴</option>
        <option value="active">涓婃灦涓?/option>
        <option value="inactive">宸蹭笅鏋?/option>
      </select>
      <button v-if="!sortMode" class="btn-sort" @click="enterSortMode">鎺掑簭</button>
      <button v-else class="btn-save-sort" @click="saveSort">淇濆瓨鎺掑簭</button>
      <button v-if="sortMode" class="btn-cancel-sort" @click="cancelSort">鍙栨秷</button>
    </div>

    <!-- 鎺掑簭妯″紡鎻愮ず -->
    <div v-if="sortMode" class="sort-tip">
      馃挕 鎺掑簭妯″紡锛氬湪杈撳叆妗嗗～鍐欏簭鍙凤紙濡?1, 2, 3...锛夛紝鎸夊洖杞︾‘璁わ紝瀹屾垚鍚庣偣"淇濆瓨鎺掑簭"
    </div>

    <!-- 鑿滃搧鍒楄〃 -->
    <div class="dish-admin-list" :class="{ 'sort-mode': sortMode }">
      <div
        v-for="(dish, idx) in filteredList"
        :key="dish.id"
        class="dish-admin-card"
        :draggable="sortMode"
        @dragstart="onDragStartCard($event, idx)"
        @dragover.prevent="onDragOverCard($event, idx)"
        @drop="onDropCard($event, idx)"
        @dragend="onDragEndCard"
        :class="{ 'drag-over': dragOverIdx === idx && dragIdx !== idx }"
        :style="dragIdx === idx ? dragCardStyle : {}"
      >
        <img v-if="dish.image_url" :src="dish.image_url" class="admin-dish-img" />
        <div v-else class="admin-img-placeholder">鏃犲浘</div>
        <div class="admin-dish-info">
          <h3>{{ dish.name }}</h3>
          <p>{{ dish.category }} | {{ dish.temperature }} | {{ dish.cook_time }}鍒嗛挓</p>
          <p class="flavor-tags">
            <span v-for="f in dish.flavor" :key="f" class="tag">{{ f }}</span>
          </p>
          <p v-if="dish.notes" class="dish-note-text">馃摑 {{ dish.notes }}</p>
        </div>
        <div class="admin-dish-actions">
          <!-- 鎺掑簭妯″紡锛氭樉绀哄簭鍙疯緭鍏ユ -->
          <template v-if="sortMode">
            <input
              type="number"
              class="sort-input"
              :value="getCurrentPosition(dish)"
              @keyup.enter="moveToPosition(dish, $event.target.value)"
              @blur="moveToPosition(dish, $event.target.value)"
              :placeholder="getCurrentPosition(dish)"
              min="1"
              :max="filteredList.length"
            />
          </template>
          <!-- 姝ｅ父妯″紡锛氭樉绀虹紪杈?涓婃灦/鍒犻櫎 -->
          <template v-else>
            <button class="btn-edit" @click="openEditModal(dish)">缂栬緫</button>
            <button :class="dish.is_active ? 'btn-unlist' : 'btn-list'" @click="toggleActive(dish)">{{ dish.is_active ? '涓嬫灦' : '涓婃灦' }}</button>
            <button class="btn-del" @click="deleteDish(dish.id)">鍒犻櫎</button>
          </template>
        </div>
      </div>
      <div v-if="filteredList.length === 0" class="empty-tip">鏆傛棤鑿滃搧</div>
    </div>

    <!-- 鏂板/缂栬緫寮圭獥 -->
    <div v-if="showModal" class="modal-mask" @click.self="closeModal">
      <div class="modal-box admin-modal">
        <h2>{{ isEdit ? '缂栬緫鑿滃搧' : '鏂板鑿滃搧' }}</h2>

        <label>鑿滃悕 *</label>
        <input v-model="form.name" placeholder="璇疯緭鍏ヨ彍鍚? />

        <label>鍒嗙被 *</label>
        <select v-model="form.category">
          <option v-for="c in categoryOptions" :key="c" :value="c">{{ c }}</option>
        </select>

        <label>娓╁害 *</label>
        <select v-model="form.temperature">
          <option value="鐑彍">鐑彍</option>
          <option value="鍑夎彍">鍑夎彍</option>
        </select>

        <label>鑰楁椂锛堝垎閽燂級*</label>
        <input v-model.number="form.cook_time" type="number" min="1" />

        <label>鍙ｅ懗鏍囩</label>
        <div class="tag-input-row">
          <input v-model="tagInput" placeholder="杈撳叆鏍囩鍚庡洖杞︽垨鐐瑰嚮娣诲姞" @keyup.enter="addTag" />
          <button type="button" class="btn-add-tag" @click="addTag">+ 娣诲姞</button>
        </div>
        <div class="tags-edit">
          <span v-for="(f, idx) in form.flavor" :key="idx" class="tag">
            {{ f }} <span @click="form.flavor.splice(idx, 1)">鉁?/span>
          </span>
        </div>

        <label>椋熸潗 *锛堝悕绉板拰鐢ㄩ噺锛屽彲鎺掑簭锛?/label>
        <div v-for="(ing, idx) in form.ingredients" :key="'ing-'+idx"
          class="kv-row reorder-row"
          draggable="true"
          @dragstart="onDragStart(idx, 'ing')"
          @dragover.prevent="onDragOver(idx, 'ing')"
          @drop="onDrop(idx, 'ing')"
        >
          <span class="drag-handle" title="鎷栨嫿鎺掑簭">鉅?/span>
          <button class="btn-move" @click="moveRow('ing', idx, -1)" :disabled="idx === 0" title="涓婄Щ">鈫?/button>
          <button class="btn-move" @click="moveRow('ing', idx, 1)" :disabled="idx === form.ingredients.length - 1" title="涓嬬Щ">鈫?/button>
          <input v-model="ing.name" placeholder="椋熸潗鍚? list="ingredient-list" />
          <input v-model="ing.amount" placeholder="鐢ㄩ噺" />
          <button @click="form.ingredients.splice(idx, 1)">鉁?/button>
        </div>
        <button class="btn-add-row" @click="form.ingredients.unshift({name:'',amount:'閫傞噺'})">+ 娣诲姞椋熸潗</button>

        <label>璋冩枡 *锛堝悕绉板拰鐢ㄩ噺锛屽彲鎺掑簭锛?/label>
        <div v-for="(s, idx) in form.seasonings" :key="'s-'+idx"
          class="kv-row reorder-row"
          draggable="true"
          @dragstart="onDragStart(idx, 'sea')"
          @dragover.prevent="onDragOver(idx, 'sea')"
          @drop="onDrop(idx, 'sea')"
        >
          <span class="drag-handle" title="鎷栨嫿鎺掑簭">鉅?/span>
          <button class="btn-move" @click="moveRow('sea', idx, -1)" :disabled="idx === 0" title="涓婄Щ">鈫?/button>
          <button class="btn-move" @click="moveRow('sea', idx, 1)" :disabled="idx === form.seasonings.length - 1" title="涓嬬Щ">鈫?/button>
          <input v-model="s.name" placeholder="璋冩枡鍚? list="seasoning-list" />
          <input v-model="s.amount" placeholder="鐢ㄩ噺" />
          <button @click="form.seasonings.splice(idx, 1)">鉁?/button>
        </div>
        <button class="btn-add-row" @click="form.seasonings.unshift({name:'',amount:'閫傞噺'})">+ 娣诲姞璋冩枡</button>

        <label>澶囨敞</label>
        <textarea v-model="form.notes" placeholder="濡傦細鍚懕濮滆挏锛屽繉鍙ｈ鎻愬墠鍛婄煡"></textarea>

        <label>鑿滃搧鍥剧墖锛堝彲閫夎鍓級</label>
        <input type="file" accept="image/*" @change="onImageSelected" :disabled="uploading" />
        <div v-if="form.image_url && !showCropper" class="preview-img-wrap">
          <img :src="form.image_url" class="preview-img" />
          <button @click="form.image_url = ''; rawImageUrl = ''">绉婚櫎鍥剧墖</button>
        </div>
        <p v-if="uploading" class="upload-tip">涓婁紶涓?..</p>

        <div class="modal-actions">
          <button @click="closeModal">鍙栨秷</button>
          <button class="btn-save" @click="saveDish">{{ isEdit ? '淇濆瓨淇敼' : '鏂板' }}</button>
        </div>
      </div>
    </div>

    <!-- 鍥剧墖瑁佸壀寮圭獥锛堝彲閫夛紝鍙烦杩囷級 -->
    <div v-if="showCropper" class="modal-mask" @click.self="cancelCrop">
      <div class="modal-box cropper-modal">
        <h3>瑁佸壀鍥剧墖锛堝彲閫夛級</h3>
        <p class="crop-hint">婊氳疆缂╂斁 路 鎷栧姩瑁佸壀妗嗙Щ鍔?路 鎷栬璋冩暣澶у皬</p>
        <div
          ref="cropContainerRef"
          class="crop-canvas-wrap"
          @mousedown="onCropMouseDown"
          @wheel.prevent="onCropWheel"
          @mousemove="onCropMouseMove"
          @mouseup="onCropMouseUp"
          @mouseleave="onCropMouseUp"
        >
          <canvas ref="cropCanvasRef" class="crop-canvas"></canvas>
          <!-- 瑁佸壀妗?-->
          <div
            class="crop-box"
            :style="{ left: cropBox.x + 'px', top: cropBox.y + 'px', width: cropBox.w + 'px', height: cropBox.h + 'px' }"
          >
            <div class="crop-handle nw" @mousedown.stop="startResize('nw', $event)"></div>
            <div class="crop-handle ne" @mousedown.stop="startResize('ne', $event)"></div>
            <div class="crop-handle sw" @mousedown.stop="startResize('sw', $event)"></div>
            <div class="crop-handle se" @mousedown.stop="startResize('se', $event)"></div>
            <div class="cross-h"></div><div class="cross-v"></div>
          </div>
        </div>
        <div class="crop-toolbar">
          <button @click="zoomCrop(0.88)">缂╁皬</button>
          <button @click="zoomCrop(1.12)">鏀惧ぇ</button>
          <span class="crop-size-info">瑁佸壀杈撳嚭锛歿{ cropOutW }} 脳 {{ cropOutH }} px锛堝師鍥惧昂瀵革級</span>
        </div>
        <div class="modal-actions">
          <button @click="cancelCrop">鍙栨秷</button>
          <button class="btn-skip-crop" @click="skipCrop">璺宠繃瑁佸壀锛岀洿鎺ヤ笂浼?/button>
          <button class="btn-save" @click="cropAndUpload">纭瑁佸壀骞朵笂浼?/button>
        </div>
      </div>
    </div>

    <!-- datalist锛氶鏉?璋冩枡鑱旀兂 -->
    <datalist id="ingredient-list">
      <option v-for="item in ingredientSuggestions" :key="item" :value="item" />
    </datalist>
    <datalist id="seasoning-list">
      <option v-for="item in seasoningSuggestions" :key="item" :value="item" />
    </datalist>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, nextTick } from 'vue'
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
const sortMode = ref(false)  // 鎺掑簭妯″紡
const dragIdx = ref(-1)  // 姝ｅ湪鎷栨嫿鐨勫崱鐗囩储寮?const dragOverIdx = ref(-1)  // 鎷栨嫿鎮仠鐨勫崱鐗囩储寮?const dragCardStyle = { opacity: '0.5' }  // 鎷栨嫿鏃跺崱鐗囧彉娣?
const categoryOptions = ['鑽よ彍', '绱犺彍', '姹ょ被', '绮夐潰绫?, '涓婚']

const form = ref({
  name: '',
  category: '鑽よ彍',
  temperature: '鐑彍',
  cook_time: 0,
  flavor: [],
  ingredients: [],
  seasonings: [],
  notes: '',
  image_url: '',
  is_active: true
})

// 椋熸潗/璋冩枡鑱旀兂
const ingredientSuggestions = ref([])
const seasoningSuggestions = ref([])

// 鍥剧墖瑁佸壀
const showCropper = ref(false)
const rawImageUrl = ref('')
const cropCanvasRef = ref(null)
const cropContainerRef = ref(null)
let cropImageObj = null
let cropImageNaturalW = 0
let cropImageNaturalH = 0

// 瑁佸壀妗嗙姸鎬?const cropBox = ref({ x: 20, y: 20, w: 200, h: 150 })
const cropOutW = ref(0)
const cropOutH = ref(0)
let cropDrag = null
let imgScale = 1
let imgOffsetX = 0
let imgOffsetY = 0
let pendingFile = null
let containerW = 400
let containerH = 320

// 鎷栨嫿鎺掑簭
let dragState = { idx: -1, type: '' }

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
  loadSuggestions()
})

async function checkAuth() {
  const { data } = await supabase.auth.getSession()
  if (!data.session) router.push('/admin')
}

async function loadDishes() {
  const { data } = await supabase.from('dishes').select('*').order('sort_order', { ascending: true }).order('created_at', { ascending: false })
  dishes.value = data || []
}

// 浠庢暟鎹簱鍔犺浇鎵€鏈夌敤杩囩殑椋熸潗/璋冩枡鍚嶇О
async function loadSuggestions() {
  const { data } = await supabase.from('dishes').select('ingredients, seasonings')
  if (!data) return
  const ingSet = new Set()
  const seaSet = new Set()
  data.forEach(d => {
    ;(d.ingredients || []).forEach(i => { if (i.name) ingSet.add(i.name) })
    ;(d.seasonings || []).forEach(s => { if (s.name) seaSet.add(s.name) })
  })
  ingredientSuggestions.value = Array.from(ingSet)
  seasoningSuggestions.value = Array.from(seaSet)
}

// ========== 涓婁笅绉诲姩鎺掑簭锛堟墜鏈?鐢佃剳閮借兘鐢級==========
function moveRow(type, idx, dir) {
  const list = type === 'ing' ? form.value.ingredients : form.value.seasonings
  const newIdx = idx + dir
  if (newIdx < 0 || newIdx >= list.length) return
  const [item] = list.splice(idx, 1)
  list.splice(newIdx, 0, item)
}

function openAddModal() {
  isEdit.value = false
  editingId.value = null
  form.value = {
    name: '', category: '鑽よ彍', temperature: '鐑彍', cook_time: 0,
    flavor: [],
    ingredients: [
      { name: '钁?, amount: '閫傞噺' },
      { name: '濮?, amount: '閫傞噺' },
      { name: '钂?, amount: '閫傞噺' },
      { name: '棣欒彍', amount: '閫傞噺' }
    ],
    seasonings: [
      { name: '鐢熸娊', amount: '閫傞噺' },
      { name: '鑰佹娊', amount: '閫傞噺' },
      { name: '閰辨补', amount: '閫傞噺' },
      { name: '绯?, amount: '閫傞噺' },
      { name: '鐩?, amount: '閫傞噺' },
      { name: '閱?, amount: '閫傞噺' }
    ],
    notes: '', image_url: '', is_active: true
  }
  rawImageUrl.value = ''
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
    ingredients: (dish.ingredients || []).length ? [...dish.ingredients] : [{ name: '', amount: '閫傞噺' }],
    seasonings: (dish.seasonings || []).length ? [...dish.seasonings] : [{ name: '', amount: '閫傞噺' }],
    notes: dish.notes || '',
    image_url: dish.image_url || '',
    is_active: dish.is_active
  }
  rawImageUrl.value = dish.image_url || ''
  showModal.value = true
}

function addTag() {
  const t = tagInput.value.trim()
  if (t && !form.value.flavor.includes(t)) form.value.flavor.push(t)
  tagInput.value = ''
}

// ========== 鎷栨嫿鎺掑簭 ==========
function onDragStart(idx, type) {
  dragState = { idx, type }
}
function onDragOver(idx, type) {
  if (dragState.type !== type) return
}
function onDrop(idx, type) {
  if (dragState.type !== type) return
  const from = dragState.idx
  const to = idx
  if (from === to) return
  const list = type === 'ing' ? form.value.ingredients : form.value.seasonings
  const [item] = list.splice(from, 1)
  list.splice(to, 0, item)
  dragState = { idx: -1, type: '' }
}

// ========== 鍥剧墖閫夋嫨 鈫?瑁佸壀锛堝彲閫夛級==========
function onImageSelected(e) {
  const file = e.target.files[0]
  if (!file) return
  pendingFile = file
  const reader = new FileReader()
  reader.onload = (ev) => {
    rawImageUrl.value = ev.target.result
    showCropper.value = true
    nextTick(() => { initCrop() })
  }
  reader.readAsDataURL(file)
  e.target.value = ''
}

function initCrop() {
  if (!rawImageUrl.value) return
  const img = new Image()
  img.onload = () => {
    cropImageObj = img
    cropImageNaturalW = img.naturalWidth || img.width
    cropImageNaturalH = img.naturalHeight || img.height
    const wrap = cropContainerRef.value
    if (!wrap) return
    containerW = wrap.clientWidth || 380
    containerH = 300

    // 鍥剧墖閫傚簲瀹瑰櫒锛堟樉绀虹敤锛?    let scale = containerW / cropImageNaturalW
    if (cropImageNaturalH * scale > containerH) scale = containerH / cropImageNaturalH
    imgScale = scale
    imgOffsetX = (containerW - cropImageNaturalW * scale) / 2
    imgOffsetY = (containerH - cropImageNaturalH * scale) / 2

    // 瑁佸壀妗嗗垵濮嬪崰鏄剧ず鍥剧墖鐨?85%
    let cw = cropImageNaturalW * scale * 0.85
    let ch = cropImageNaturalH * scale * 0.85
    if (cw > containerW - 40) cw = containerW - 40
    if (ch > containerH - 40) ch = containerH - 40
    cropBox.value = {
      x: (containerW - cw) / 2,
      y: (containerH - ch) / 2,
      w: cw,
      h: ch
    }
    updateCropOutSize()
    drawCropCanvas()
  }
  img.src = rawImageUrl.value
}

function drawCropCanvas() {
  const canvas = cropCanvasRef.value
  if (!canvas || !cropImageObj) return
  canvas.width = containerW
  canvas.height = containerH
  const ctx = canvas.getContext('2d')
  ctx.clearRect(0, 0, canvas.width, canvas.height)
  ctx.drawImage(
    cropImageObj,
    imgOffsetX, imgOffsetY,
    cropImageNaturalW * imgScale,
    cropImageNaturalH * imgScale
  )
}

function updateCropOutSize() {
  const cb = cropBox.value
  const ow = Math.round(cb.w / imgScale)
  const oh = Math.round(cb.h / imgScale)
  cropOutW.value = ow
  cropOutH.value = oh
}

// 缂╂斁
function zoomCrop(factor) {
  imgScale *= factor
  if (imgScale < 0.1) imgScale = 0.1
  if (imgScale > 10) imgScale = 10
  imgOffsetX = (containerW - cropImageNaturalW * imgScale) / 2
  imgOffsetY = (containerH - cropImageNaturalH * imgScale) / 2
  drawCropCanvas()
  updateCropOutSize()
}
function onCropWheel(e) {
  zoomCrop(e.deltaY > 0 ? 0.92 : 1.08)
}

// 鎷栧姩瑁佸壀妗?function onCropMouseDown(e) {
  const rect = cropContainerRef.value.getBoundingClientRect()
  const mx = e.clientX - rect.left
  const my = e.clientY - rect.top
  const cb = cropBox.value
  if (mx >= cb.x && mx <= cb.x + cb.w && my >= cb.y && my <= cb.y + cb.h) {
    cropDrag = { type: 'move', startX: mx, startY: my, ...cb }
  }
}
function onCropMouseMove(e) {
  if (!cropDrag) return
  const rect = cropContainerRef.value.getBoundingClientRect()
  const mx = e.clientX - rect.left
  const my = e.clientY - rect.top
  const dx = mx - cropDrag.startX
  const dy = my - cropDrag.startY
  if (cropDrag.type === 'move') {
    cropBox.value.x = clamp(cropDrag.x + dx, 0, containerW - cropBox.value.w)
    cropBox.value.y = clamp(cropDrag.y + dy, 0, containerH - cropBox.value.h)
  } else if (cropDrag.type.startsWith('resize')) {
    handleResize(dx, dy)
  }
  updateCropOutSize()
}
function onCropMouseUp() {
  cropDrag = null
}

function startResize(corner, e) {
  const rect = cropContainerRef.value.getBoundingClientRect()
  cropDrag = {
    type: 'resize-' + corner,
    startX: e.clientX - rect.left,
    startY: e.clientY - rect.top,
    ...cropBox.value
  }
}
function handleResize(dx, dy) {
  const s = cropDrag
  const minSize = 20
  if (cropDrag.type === 'resize-se') {
    cropBox.value.w = clamp(s.w + dx, minSize, containerW - s.x)
    cropBox.value.h = clamp(s.h + dy, minSize, containerH - s.y)
  } else if (cropDrag.type === 'resize-sw') {
    const newW = s.w - dx
    const newX = s.x + dx
    if (newW >= minSize && newX >= 0) { cropBox.value.w = newW; cropBox.value.x = newX }
    cropBox.value.h = clamp(s.h + dy, minSize, containerH - s.y)
  } else if (cropDrag.type === 'resize-ne') {
    cropBox.value.w = clamp(s.w + dx, minSize, containerW - s.x)
    const newH = s.h - dy
    const newY = s.y + dy
    if (newH >= minSize && newY >= 0) { cropBox.value.h = newH; cropBox.value.y = newY }
  } else if (cropDrag.type === 'resize-nw') {
    const newW = s.w - dx
    const newX = s.x + dx
    const newH = s.h - dy
    const newY = s.y + dy
    if (newW >= minSize && newX >= 0) { cropBox.value.w = newW; cropBox.value.x = newX }
    if (newH >= minSize && newY >= 0) { cropBox.value.h = newH; cropBox.value.y = newY }
  }
}

function clamp(v, lo, hi) { return Math.max(lo, Math.min(hi, v)) }

function cancelCrop() {
  showCropper.value = false
  rawImageUrl.value = form.value.image_url || ''
  pendingFile = null
  cropImageObj = null
}

// ========== 璺宠繃瑁佸壀锛岀洿鎺ュ帇缂╀笂浼犲師鍥?==========
async function skipCrop() {
  if (!pendingFile) {
    alert('鏈娴嬪埌寰呬笂浼犲浘鐗囷紝璇烽噸鏂伴€夋嫨鍥剧墖')
    showCropper.value = false
    return
  }
  uploading.value = true
  try {
    const compressedBlob = await compressImage(pendingFile)
    if (!compressedBlob) throw new Error('鍥剧墖鍘嬬缉澶辫触')
    // 杞垚 File 瀵硅薄鍐嶄笂浼狅紙鏇寸ǔ濡ワ級
    const ext = pendingFile.name.split('.').pop() || 'jpg'
    const fileName = `dish-${Date.now()}-${Math.random().toString(36).slice(2, 8)}.${ext}`
    const compressedFile = new File([compressedBlob], fileName, { type: compressedBlob.type || 'image/jpeg' })
    const { error } = await supabase.storage.from('dish-images').upload(fileName, compressedFile)
    if (!error) {
      const { data: { publicUrl } } = supabase.storage.from('dish-images').getPublicUrl(fileName)
      form.value.image_url = publicUrl
    } else {
      alert('涓婁紶澶辫触锛? + error.message)
    }
  } catch (err) {
    console.error('skipCrop 鍑洪敊锛?, err)
    alert('涓婁紶澶辫触锛? + (err.message || err))
  } finally {
    uploading.value = false
    showCropper.value = false
    cropImageObj = null
    pendingFile = null
  }
}

// ========== 纭瑁佸壀 鈫?鍘熷浘鍧愭爣瑁佸壀 鈫?涓€娆℃€у帇缂╀笂浼?==========
async function cropAndUpload() {
  if (!cropImageObj) return
  uploading.value = true
  try {
    const cb = cropBox.value
    const sx = (cb.x - imgOffsetX) / imgScale
    const sy = (cb.y - imgOffsetY) / imgScale
    const sw = cb.w / imgScale
    const sh = cb.h / imgScale
    const outW = Math.max(1, Math.round(sw))
    const outH = Math.max(1, Math.round(sh))

    const tmpCanvas = document.createElement('canvas')
    tmpCanvas.width = outW
    tmpCanvas.height = outH
    const tmpCtx = tmpCanvas.getContext('2d')
    tmpCtx.drawImage(cropImageObj, sx, sy, sw, sh, 0, 0, outW, outH)

    tmpCanvas.toBlob(async (blob) => {
      if (!blob) { alert('瑁佸壀澶辫触'); uploading.value = false; return }
      try {
        const ext = pendingFile ? (pendingFile.name.split('.').pop() || 'jpg') : 'jpg'
        const fileName = `dish-${Date.now()}-${Math.random().toString(36).slice(2, 8)}.${ext}`
        const croppedFile = new File([blob], fileName, { type: blob.type || 'image/jpeg' })
        const { error } = await supabase.storage.from('dish-images').upload(fileName, croppedFile)
        if (!error) {
          const { data: { publicUrl } } = supabase.storage.from('dish-images').getPublicUrl(fileName)
          form.value.image_url = publicUrl
        } else {
          alert('涓婁紶澶辫触锛? + error.message)
        }
      } catch (err) {
        console.error('cropAndUpload 涓婁紶鍑洪敊锛?, err)
        alert('涓婁紶澶辫触锛? + (err.message || err))
      }
      uploading.value = false
      showCropper.value = false
      cropImageObj = null
      pendingFile = null
    }, 'image/jpeg', 0.85)
  } catch (err) {
    console.error('cropAndUpload 鍑洪敊锛?, err)
    alert('瑁佸壀鍑洪敊锛? + (err.message || err))
    uploading.value = false
  }
}

// 鍘嬬缉鍘熷浘锛堣烦杩囪鍓椂浣跨敤锛屾渶澶у搴?600px锛岃川閲?.85锛?function compressImage(file) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader()
    reader.onload = (e) => {
      const img = new Image()
      img.onload = () => {
        let { width, height } = img
        const MAX_W = 1600
        if (width > MAX_W) {
          height = Math.round(height * MAX_W / width)
          width = MAX_W
        }
        const canvas = document.createElement('canvas')
        canvas.width = width
        canvas.height = height
        canvas.getContext('2d').drawImage(img, 0, 0, width, height)
        canvas.toBlob((b) => { resolve(b || file) }, 'image/jpeg', 0.85)
      }
      img.onerror = reject
      img.src = e.target.result
    }
    reader.onerror = reject
    reader.readAsDataURL(file)
  })
}

async function saveDish() {
  if (!form.value.name) return alert('璇疯緭鍏ヨ彍鍚?)
  if (!form.value.cook_time) return alert('璇疯緭鍏ヨ€楁椂')
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
    // 鏂板鑿滃搧锛歴ort_order 璁句负褰撳墠鏈€澶у€?+ 1锛堟帓鍒版渶鍚庯級
    const { data: maxData } = await supabase
      .from('dishes')
      .select('sort_order')
      .order('sort_order', { ascending: false })
      .limit(1)
    const maxSort = (maxData && maxData[0] && maxData[0].sort_order) || 0
    payload.sort_order = maxSort + 1
    ;({ error } = await supabase.from('dishes').insert(payload))
  }
  if (error) {
    alert('淇濆瓨澶辫触锛? + error.message)
  } else {
    closeModal()
    loadDishes()
    loadSuggestions()
  }
}

async function toggleActive(dish) {
  await supabase.from('dishes').update({ is_active: !dish.is_active }).eq('id', dish.id)
  loadDishes()
}

async function deleteDish(id) {
  if (!confirm('纭畾鍒犻櫎杩欓亾鑿滐紵')) return
  await supabase.from('dishes').delete().eq('id', id)
  loadDishes()
}

// ========== 鎷栨嫿鎺掑簭锛堟嫋鍔ㄦ暣涓崱鐗囷級==========
function onDragStartCard(e, idx) {
  if (!sortMode.value) return
  dragIdx.value = idx
  e.dataTransfer.effectAllowed = 'move'
  e.dataTransfer.setData('text/plain', idx)
}

function onDragOverCard(e, idx) {
  if (!sortMode.value) return
  e.preventDefault()
  dragOverIdx.value = idx
}

function onDropCard(e, idx) {
  if (!sortMode.value) return
  e.preventDefault()
  const from = dragIdx.value
  const to = idx
  if (from < 0 || from === to) return
  
  // 鍦?dishes.value 涓壘鍒拌繖涓や釜鑿滃搧锛屼氦鎹㈠畠浠殑 sort_order
  const dishA = filteredList.value[from]
  const dishB = filteredList.value[to]
  const posA = dishes.value.findIndex(d => d.id === dishA.id)
  const posB = dishes.value.findIndex(d => d.id === dishB.id)
  if (posA < 0 || posB < 0) return
    
  // 浜ゆ崲 sort_order
  const tmp = dishes.value[posA].sort_order
  dishes.value[posA].sort_order = dishes.value[posB].sort_order
  dishes.value[posB].sort_order = tmp
    
  // 閲嶆柊鎺掑簭 dishes锛堣鏄剧ず璺熺潃鍙橈級
  dishes.value.sort((a, b) => (a.sort_order || 0) - (b.sort_order || 0))
    
  dragIdx.value = -1
  dragOverIdx.value = -1
}

function onDragEndCard() {
  dragIdx.value = -1
  dragOverIdx.value = -1
}

// ========== 杈撳叆搴忓彿鎺掑簭鍔熻兘 ==========
function getCurrentPosition(dish) {
  // 鑾峰彇鑿滃搧鍦ㄥ綋鍓嶅垪琛ㄤ腑鐨勪綅缃紙浠?寮€濮嬶級
  const sortedList = [...dishes.value].sort((a, b) => (a.sort_order || 0) - (b.sort_order || 0))
  const pos = sortedList.findIndex(d => d.id === dish.id)
  return pos + 1
}

function moveToPosition(dish, newPosStr) {
  const newPos = parseInt(newPosStr)
  if (isNaN(newPos) || newPos < 1 || newPos > dishes.value.length) {
    alert('璇疯緭鍏?1 鍒?' + dishes.value.length + ' 涔嬮棿鐨勬暟瀛?)
    return
  }
  
  const currentPos = getCurrentPosition(dish)
  if (currentPos === newPos) return  // 浣嶇疆娌″彉锛屼笉鐢ㄥ姩
  
  // 浠?dishes.value 涓Щ闄よ繖閬撹彍
  const dishIndex = dishes.value.findIndex(d => d.id === dish.id)
  if (dishIndex < 0) return
  const [movedDish] = dishes.value.splice(dishIndex, 1)
  
  // 鎻掑叆鍒版柊浣嶇疆锛坣ewPos 鏄粠1寮€濮嬬殑锛屾暟缁勬槸浠?寮€濮嬬殑锛?  const insertIndex = newPos - 1
  dishes.value.splice(insertIndex, 0, movedDish)
  
  // 閲嶆柊缂栧彿 sort_order锛?, 2, 3...锛?  dishes.value.forEach((d, idx) => {
    d.sort_order = idx + 1
  })
}

// ========== 鑿滃搧鎺掑簭鍔熻兘 ==========
let originalOrder = []  // 淇濆瓨鍘熷椤哄簭锛岀敤浜庡彇娑堟仮澶?
function enterSortMode() {
  originalOrder = dishes.value.map(d => d.id)
  sortMode.value = true
}

function cancelSort() {
  // 鎭㈠鍒板師濮嬮『搴?  const map = {}
  originalOrder.forEach((id, idx) => { map[id] = idx })
  dishes.value.sort((a, b) => map[a.id] - map[b.id])
  sortMode.value = false
}

function moveDish(idx, dir) {
  const list = filteredList.value
  const newIdx = idx + dir
  if (newIdx < 0 || newIdx >= list.length) return
  // 鍦?dishes.value 閲屾壘鍒拌繖涓や釜鑿滃搧锛屼氦鎹㈠畠浠殑浣嶇疆
  const dishA = list[idx]
  const dishB = list[newIdx]
  const posA = dishes.value.findIndex(d => d.id === dishA.id)
  const posB = dishes.value.findIndex(d => d.id === dishB.id)
  if (posA < 0 || posB < 0) return
  // 浜ゆ崲 sort_order
  const tmp = dishes.value[posA].sort_order
  dishes.value[posA].sort_order = dishes.value[posB].sort_order
  dishes.value[posB].sort_order = tmp
  // 閲嶆柊鎺掑簭 dishes锛堣鏄剧ず璺熺潃鍙橈級
  dishes.value.sort((a, b) => (a.sort_order || 0) - (b.sort_order || 0))
}

async function saveSort() {
  try {
    // 鎸夊綋鍓嶆樉绀洪『搴忥紝閲嶆柊璁剧疆 sort_order锛?, 2, 3...锛?    const updates = dishes.value.map((d, idx) => ({
      id: d.id,
      sort_order: idx + 1
    }))
    // 閫愪釜鏇存柊锛圫upabase 涓嶆敮鎸佹壒閲?update 涓嶅悓 id 鐨勪笉鍚屽€硷級
    for (const u of updates) {
      const { error } = await supabase.from('dishes').update({ sort_order: u.sort_order }).eq('id', u.id)
      if (error) throw error
    }
    alert('鎺掑簭宸蹭繚瀛橈紒')
    sortMode.value = false
    loadDishes()
  } catch (err) {
    console.error('淇濆瓨鎺掑簭澶辫触锛?, err)
    alert('淇濆瓨鎺掑簭澶辫触锛? + (err.message || err))
  }
}

function closeModal() {
  showModal.value = false
  if (showCropper.value) cancelCrop()
}

async function logout() {
  await supabase.auth.signOut()
  router.push('/admin')
}
</script>

<style scoped>
.admin-page { max-width: 480px; margin:0 auto; padding-bottom: 20px; }

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

/* 寮圭獥 */
.modal-mask {
  position: fixed; inset: 0; background: rgba(0,0,0,0.5);
  display: flex; align-items: center; justify-content: center; z-index: 200;
}
.modal-box {
  background: #fff; border-radius: 16px; width: 90%; max-width: 460px;
  max-height: 90vh; overflow-y: auto; padding: 20px;
}
.admin-modal label { display: block; font-size: 13px; font-weight: 500; margin: 10px 0 4px; }
.admin-modal input, .admin-modal select, .admin-modal textarea {
  width: 100%; padding: 8px 10px; border:1px solid #ddd; border-radius: 8px;
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
.reorder-row { cursor: grab; }
.reorder-row:active { cursor: grabbing; }
.drag-handle {
  font-size: 16px; color: #bbb; cursor: grab; flex-shrink: 0;
  display: flex; align-items: center; padding: 0 2px;
  user-select: none;
}
.reorder-row:hover .drag-handle { color: #888; }

/* 涓婁笅绉诲姩鎸夐挳锛堟墜鏈?鐢佃剳閮借兘鐢級 */
.btn-move {
  width: 22px; height: 22px; border-radius: 4px;
  background: #f0f0f0; color: #666; font-size: 13px; font-weight: bold;
  flex-shrink: 0; display: flex; align-items: center; justify-content: center;
  border: 1px solid #ddd; cursor: pointer;
}
.btn-move:hover:not(:disabled) { background: #e0e0e0; color: #333; }
.btn-move:disabled { opacity: 0.3; cursor: not-allowed; }

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

/* 瑁佸壀寮圭獥 */
.cropper-modal { max-width: 480px; }
.crop-hint {
  font-size: 12px; color: #888; text-align: center; margin: -6px 0 8px;
}
.crop-canvas-wrap {
  position: relative; overflow: hidden;
  background: #222; border-radius: 8px;
  user-select: none; touch-action: none;
  cursor: move;
  min-height: 280px;
  display: flex; align-items: center; justify-content: center;
}
.crop-canvas {
  display: block; max-width: 100%; max-height: 280px;
}
.crop-box {
  position: absolute; border: 2px dashed #fff;
  box-shadow: 0 0 0 9999px rgba(0,0,0,0.45);
  z-index: 2; box-sizing: border-box;
}
.crop-handle {
  position: absolute; width: 14px; height: 14px;
  background: #1677ff; border: 2px solid #fff; border-radius: 50%;
  z-index: 3;
}
.crop-handle.nw { top: -7px; left: -7px; cursor: nw-resize; }
.crop-handle.ne { top: -7px; right: -7px; cursor: nesw-resize; }
.crop-handle.sw { bottom: -7px; left: -7px; cursor: nesw-resize; }
.crop-handle.se { bottom: -7px; right: -7px; cursor: nwse-resize; }
.cross-h {
  position: absolute; top: 50%; left: 0; right: 0;
  height: 1px; background: rgba(255,255,255,0.35);
}
.cross-v {
  position: absolute; left: 50%; top: 0; bottom: 0;
  width: 1px; background: rgba(255,255,255,0.35);
}
.crop-toolbar {
  display: flex; align-items: center; gap: 8px; margin-top: 8px;
}
.crop-toolbar button {
  padding: 4px 12px; border-radius: 6px; font-size: 12px;
  background: #f0f0f0; border: 1px solid #ddd; cursor: pointer;
}
.crop-toolbar button:hover { background: #e0e0e0; }
.crop-size-info {
  margin-left: auto; font-size: 12px; color: #888;
}
.btn-skip-crop {
  padding: 10px; border-radius: 8px; font-size: 13px;
  background: #fff7e6; color: #d46b08; border: 1px solid #ffd591;
  cursor: pointer; font-weight: 500;
}
.btn-skip-crop:hover { background: #ffe7ba; }

/* 鎺掑簭鍔熻兘鏍峰紡 */
.sort-tip {
  background: #e8f0fe; color: #1677ff; font-size: 12px;
  padding: 8px 16px; text-align: center;
}
.btn-sort {
  padding: 6px 14px; background: #e8f0fe; color: #1677ff;
  border-radius: 8px; font-size: 13px; font-weight: 500;
  border: 1px solid #91caff; white-space: nowrap;
}
.btn-sort:hover { background: #bae0ff; }
.btn-save-sort {
  padding: 6px 14px; background: #d4f7e6; color: #00a870;
  border-radius: 8px; font-size: 13px; font-weight: 500;
  border: 1px solid #87dca0; white-space: nowrap;
}
.btn-save-sort:hover { background: #a1f0c4; }
.btn-cancel-sort {
  padding: 6px 14px; background: #fff0f0; color: #e55a2b;
  border-radius: 8px; font-size: 13px; font-weight: 500;
  border: 1px solid #f5c6c0; white-space: nowrap;
}
.btn-cancel-sort:hover { background: #ffe0e0; }

/* 鎷栨嫿鎺掑簭鏍峰紡 */
.dish-admin-card[draggable="true"] {
  cursor: grab;
}
.dish-admin-card[draggable="true"]:active {
  cursor: grabbing;
}
.drag-over {
  border-top: 3px solid #1677ff !important;
}

/* 鎺掑簭妯″紡涓嬬殑搴忓彿杈撳叆妗?*/
.sort-input {
  width: 60px;
  padding: 4px 8px;
  border-radius: 6px;
  border: 1px solid #1677ff;
  font-size: 14px;
  font-weight: 600;
  text-align: center;
  color: #1677ff;
  background: #e8f0fe;
  flex-shrink: 0;
}

/* 鎺掑簭妯″紡涓嬭彍鍝佸崱鐗囨牱寮?*/
.sort-mode .dish-admin-card {
  border: 1px solid #91caff;
  box-shadow: 0 2px 8px rgba(22,119,255,0.12);
}
</style>
