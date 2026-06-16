<template>
  <div class="admin-page">
    <header class="admin-header">
      <h1>绯荤粺璁剧疆</h1>
      <div class="header-actions">
        <button class="btn-nav" @click="$router.push('/admin/dishes')">鑿滃搧</button>
        <button class="btn-nav" @click="$router.push('/admin/customers')">瀹㈡埛</button>
        <button class="btn-nav" @click="$router.push('/admin/orders')">璁㈠崟</button>
        <button class="btn-settings active-nav" @click="$router.push('/admin/settings')">璁剧疆</button>
        <button class="btn-logout" @click="logout">閫€鍑?/button>
        <span class="version-badge">v2.0.25</span>
      </div>
    </header>

    <div class="settings-form">
      <h2>搴楅摵淇℃伅</h2>

      <label>搴楅摵鍚嶇О</label>
      <input v-model="form.shop_name" placeholder="濡傦細闃挎椇灏忓帹鎴? />

      <label>搴楅摵Logo鍥剧墖</label>
      <input type="file" accept="image/*" @change="uploadLogo" :disabled="uploading" />
      <div v-if="form.logo_url" class="logo-preview">
        <img :src="form.logo_url" />
        <button @click="form.logo_url = ''; logoChanged = true">绉婚櫎Logo</button>
      </div>
      <p v-if="uploading" class="upload-tip">涓婁紶涓?..</p>

      <button class="btn-save" @click="saveSettings" :disabled="saving">
        {{ saving ? '淇濆瓨涓?..' : '淇濆瓨璁剧疆' }}
      </button>

      <p v-if="saveMsg" class="save-msg" :style="{ color: saveOk ? 'var(--success)' : 'var(--danger)' }">
        {{ saveMsg }}
      </p>
    </div>

    <!-- 绠＄悊鍛樿处鍙风鐞嗘彁绀?-->
    <div class="settings-form" style="margin-top: 20px;">
      <h2>绠＄悊鍛樿处鍙?/h2>
      <p style="font-size: 13px; color: var(--text-secondary); margin-bottom: 12px;">
        濡傞渶鏂板绠＄悊鍛橈紝璇峰湪鐧诲綍椤电偣鍑?娉ㄥ唽"锛岀敤鏂伴偖绠辨敞鍐屽悗鑷姩鎴愪负绠＄悊鍛樸€?      </p>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, inject } from 'vue'
import { supabase } from '../lib/supabase'
import { useRouter } from 'vue-router'

const settings = inject('shopSettings')
const router = useRouter()

const form = ref({
  shop_name: '闃挎椇灏忓帹鎴?,
  logo_url: ''
})
const uploading = ref(false)
const saving = ref(false)
const saveMsg = ref('')
const saveOk = ref(true)
const logoChanged = ref(false)

onMounted(() => {
  checkAuth()
  loadSettings()
})

async function checkAuth() {
  const { data } = await supabase.auth.getSession()
  if (!data.session) router.push('/admin')
}

async function loadSettings() {
  const { data } = await supabase.from('settings').select('*').single()
  if (data) {
    form.value = {
      shop_name: data.shop_name || '闃挎椇灏忓帹鎴?,
      logo_url: data.logo_url || ''
    }
  }
}

async function uploadLogo(e) {
  const file = e.target.files[0]
  if (!file) return
  uploading.value = true
  // 鎻愬彇鍘熷鏂囦欢鎵╁睍鍚嶏紝鐢ㄦ椂闂存埑+闅忔満鏁颁綔涓烘枃浠跺悕锛堥伩鍏嶄腑鏂囩瓑闈炴硶瀛楃锛?  const ext = file.name.split('.').pop() || 'png'
  const fileName = `logo-${Date.now()}-${Math.random().toString(36).slice(2, 8)}.${ext}`
  const { data, error } = await supabase.storage.from('dish-images').upload(fileName, file, { upsert: true })
  if (!error) {
    const { data: { publicUrl } } = supabase.storage.from('dish-images').getPublicUrl(fileName)
    form.value.logo_url = publicUrl
    logoChanged.value = true
  } else {
    console.error('涓婁紶Logo澶辫触:', error)
    let msg = '涓婁紶澶辫触锛? + error.message
    if (error.message.includes('Bucket not found') || error.message.includes('bucket')) {
      msg = '瀛樺偍妗朵笉瀛樺湪锛佽鍦?Supabase SQL Editor 鎵ц supabase/init-storage.sql 鑴氭湰'
    }
    alert(msg)
  }
  uploading.value = false
}

async function saveSettings() {
  if (!form.value.shop_name.trim()) {
    saveMsg.value = '搴楅摵鍚嶇О涓嶈兘涓虹┖'
    saveOk.value = false
    return
  }
  saving.value = true
  saveMsg.value = ''

  // 鍏堝皾璇?update锛屽鏋滃け璐ユ垨褰卞搷 0 琛屽垯 upsert
  let error = null
  let updated = 0

  const { count, error: updateError } = await supabase
    .from('settings')
    .update({
      shop_name: form.value.shop_name.trim(),
      logo_url: form.value.logo_url
    })
    .eq('id', 1)
    .select('*', { count: 'exact' })

  if (updateError) {
    error = updateError
  } else if (count === 0) {
    // 娌℃湁 id=1 鐨勮褰曪紝鎵ц insert
    const { error: insertError } = await supabase
      .from('settings')
      .insert({
        id: 1,
        shop_name: form.value.shop_name.trim(),
        logo_url: form.value.logo_url
      })
    error = insertError
  }

  saving.value = false
  if (error) {
    saveMsg.value = '淇濆瓨澶辫触锛? + error.message
    saveOk.value = false
  } else {
    saveMsg.value = '淇濆瓨鎴愬姛锛?
    saveOk.value = true
    settings.value = {
      shop_name: form.value.shop_name.trim(),
      logo_url: form.value.logo_url
    }
  }
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
.header-actions .btn-settings { background: rgba(255,255,255,0.2); }
.header-actions .btn-settings.active-nav { background: rgba(255,255,255,0.4); font-weight: 600; }
.header-actions .btn-logout {
  background: rgba(255,255,255,0.15); border: 1px solid rgba(255,255,255,0.3);
}
.header-actions .version-badge {
  font-size: 11px; color: rgba(255,255,255,0.7);
  background: rgba(0,0,0,0.18); padding: 2px 8px; border-radius: 10px;
  white-space: nowrap; margin-left: 4px;
}

.settings-form { padding: 20px 16px; }
.settings-form h2 { font-size: 16px; margin-bottom: 16px; }
.settings-form label { display: block; font-size: 13px; font-weight: 500; margin: 12px 0 4px; }
.settings-form input[type="text"],
.settings-form input[type="file"] { margin-bottom: 8px; }
.settings-form input[type="text"] {
  width: 100%; padding: 8px 10px; border: 1px solid #ddd; border-radius: 8px; font-size: 14px;
}
.logo-preview { margin: 8px 0; }
.logo-preview img {
  width: 80px; height: 80px; border-radius: 50%; object-fit: cover;
  border: 2px solid var(--border);
}
.logo-preview button {
  display: block; margin-top: 6px; font-size: 12px; color: var(--danger); background: none;
}
.upload-tip { font-size: 12px; color: var(--text-secondary); }
.btn-save {
  width: 100%; padding: 10px; background: var(--primary); color: #fff;
  border-radius: 8px; font-weight: 500; margin-top: 16px;
}
.btn-save:disabled { opacity: 0.6; }
.save-msg { text-align: center; margin-top: 8px; font-size: 13px; }
</style>
