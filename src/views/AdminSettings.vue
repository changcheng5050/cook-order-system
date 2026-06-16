<template>
  <div class="admin-page">
    <header class="admin-header">
      <h1>系统设置</h1>
      <div class="header-actions">
        <button class="btn-nav" @click="$router.push('/admin/dishes')">菜品</button>
        <button class="btn-nav" @click="$router.push('/admin/customers')">客户</button>
        <button class="btn-nav" @click="$router.push('/admin/orders')">订单</button>
        <button class="btn-settings active-nav" @click="$router.push('/admin/settings')">设置</button>
        <button class="btn-logout" @click="logout">退出</button>
        <span class="version-badge">v2.1.3</span>
      </div>
    </header>

    <div class="settings-form">
      <h2>店铺信息</h2>

      <label>店铺名称</label>
      <input v-model="form.shop_name" placeholder="如：阿旺小厨房" />

      <label>店铺Logo图片</label>
      <input type="file" accept="image/*" @change="uploadLogo" :disabled="uploading" />
      <div v-if="form.logo_url" class="logo-preview">
        <img :src="form.logo_url" />
        <button @click="form.logo_url = ''; logoChanged = true">移除Logo</button>
      </div>
      <p v-if="uploading" class="upload-tip">上传中...</p>

      <button class="btn-save" @click="saveSettings" :disabled="saving">
        {{ saving ? '保存中...' : '保存设置' }}
      </button>

      <p v-if="saveMsg" class="save-msg" :style="{ color: saveOk ? 'var(--success)' : 'var(--danger)' }">
        {{ saveMsg }}
      </p>
    </div>

    <!-- 管理员账号管理提示 -->
    <div class="settings-form" style="margin-top: 20px;">
      <h2>管理员账号</h2>
      <p style="font-size: 13px; color: var(--text-secondary); margin-bottom: 12px;">
        如需新增管理员，请在登录页点击"注册"，用新邮箱注册后自动成为管理员。
      </p>
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
  shop_name: '阿旺小厨房',
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
      shop_name: data.shop_name || '阿旺小厨房',
      logo_url: data.logo_url || ''
    }
  }
}

async function uploadLogo(e) {
  const file = e.target.files[0]
  if (!file) return
  uploading.value = true
  // 提取原始文件扩展名，用时间戳+随机数作为文件名（避免中文等非法字符）
  const ext = file.name.split('.').pop() || 'png'
  const fileName = `logo-${Date.now()}-${Math.random().toString(36).slice(2, 8)}.${ext}`
  const { data, error } = await supabase.storage.from('dish-images').upload(fileName, file, { upsert: true })
  if (!error) {
    const { data: { publicUrl } } = supabase.storage.from('dish-images').getPublicUrl(fileName)
    form.value.logo_url = publicUrl
    logoChanged.value = true
  } else {
    console.error('上传Logo失败:', error)
    let msg = '上传失败：' + error.message
    if (error.message.includes('Bucket not found') || error.message.includes('bucket')) {
      msg = '存储桶不存在！请在 Supabase SQL Editor 执行 supabase/init-storage.sql 脚本'
    }
    alert(msg)
  }
  uploading.value = false
}

async function saveSettings() {
  if (!form.value.shop_name.trim()) {
    saveMsg.value = '店铺名称不能为空'
    saveOk.value = false
    return
  }
  saving.value = true
  saveMsg.value = ''

  // 先尝试 update，如果失败或影响 0 行则 upsert
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
    // 没有 id=1 的记录，执行 insert
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
    saveMsg.value = '保存失败：' + error.message
    saveOk.value = false
  } else {
    saveMsg.value = '保存成功！'
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
