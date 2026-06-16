<template>
  <div class="login-page">
    <div class="login-box">
      <img v-if="settings.logo_url" :src="settings.logo_url" class="login-logo" />
      <h1>{{ settings.shop_name }}</h1>
      <p class="login-subtitle">绠＄悊鍛樼櫥褰?/p>

      <div v-if="!isSignup" class="form-group">
        <input v-model="email" type="email" placeholder="閭" />
        <input v-model="password" type="password" placeholder="瀵嗙爜" @keyup.enter="login" />
        <label class="remember-row">
          <input type="checkbox" v-model="rememberMe" />
          <span>璁颁綇鐧诲綍淇℃伅锛堜笅娆¤嚜鍔ㄥ～鍏咃級</span>
        </label>
        <button @click="login" :disabled="loading">{{ loading ? '鐧诲綍涓?..' : '鐧诲綍' }}</button>
        <p class="switch-link" @click="isSignup = true">杩樻病鏈夎处鍙凤紵鐐瑰嚮娉ㄥ唽</p>
      </div>

      <div v-else class="form-group">
        <input v-model="email" type="email" placeholder="閭" />
        <input v-model="password" type="password" placeholder="瀵嗙爜锛堣嚦灏?浣嶏級" @keyup.enter="signup" />
        <button @click="signup" :disabled="loading">{{ loading ? '娉ㄥ唽涓?..' : '娉ㄥ唽' }}</button>
        <p class="switch-link" @click="isSignup = false">宸叉湁璐﹀彿锛熻繑鍥炵櫥褰?/p>
      </div>

      <p v-if="errorMsg" class="error-msg">{{ errorMsg }}</p>
      <p class="version-text">v2.0.25</p>
    </div>
  </div>
</template>

<script setup>
import { ref, inject, onMounted } from 'vue'
import { supabase } from '../lib/supabase'
import { useRouter } from 'vue-router'

const settings = inject('shopSettings')
const router = useRouter()

const email = ref('')
const password = ref('')
const loading = ref(false)
const errorMsg = ref('')
const isSignup = ref(false)
const rememberMe = ref(false)

onMounted(() => {
  // 灏濊瘯璇诲彇淇濆瓨鐨勭櫥褰曚俊鎭?  const savedEmail = localStorage.getItem('admin_remember_email')
  const savedPwd = localStorage.getItem('admin_remember_password')
  if (savedEmail) {
    email.value = savedEmail
    password.value = savedPwd || ''
    rememberMe.value = true
  }
})

async function login() {
  if (!email.value || !password.value) {
    errorMsg.value = '璇疯緭鍏ラ偖绠卞拰瀵嗙爜'
    return
  }
  loading.value = true
  errorMsg.value = ''
  const { error } = await supabase.auth.signInWithPassword({
    email: email.value,
    password: password.value
  })
  loading.value = false
  if (error) {
    errorMsg.value = error.message
  } else {
    // 鏍规嵁閫夋嫨鏄惁璁颁綇瀵嗙爜
    if (rememberMe.value) {
      localStorage.setItem('admin_remember_email', email.value)
      localStorage.setItem('admin_remember_password', password.value)
    } else {
      localStorage.removeItem('admin_remember_email')
      localStorage.removeItem('admin_remember_password')
    }
    router.push('/admin/dishes')
  }
}

async function signup() {
  if (!email.value || !password.value) {
    errorMsg.value = '璇疯緭鍏ラ偖绠卞拰瀵嗙爜'
    return
  }
  if (password.value.length < 6) {
    errorMsg.value = '瀵嗙爜鑷冲皯6浣?
    return
  }
  loading.value = true
  errorMsg.value = ''
  const { error } = await supabase.auth.signUp({
    email: email.value,
    password: password.value
  })
  loading.value = false
  if (error) {
    errorMsg.value = error.message
  } else {
    errorMsg.value = '娉ㄥ唽鎴愬姛锛佽鏌ユ敹閭楠岃瘉閭欢鍚庣櫥褰曘€?
    isSignup.value = false
  }
}
</script>

<style scoped>
.login-page {
  min-height: 100vh; display: flex; align-items: center; justify-content: center;
  background: var(--bg);
}
.login-box {
  background: #fff; border-radius: 16px; padding: 32px 24px; width: 340px;
  text-align: center; box-shadow: 0 2px 12px rgba(0,0,0,0.08);
}
.login-logo { width: 64px; height: 64px; border-radius: 50%; margin-bottom: 12px; object-fit: cover; }
.login-box h1 { font-size: 20px; margin-bottom: 4px; }
.login-subtitle { color: var(--text-secondary); font-size: 13px; margin-bottom: 20px; }
.form-group { display: flex; flex-direction: column; gap: 10px; }
.form-group input {
  padding: 10px 12px; border: 1px solid #ddd; border-radius: 8px; font-size: 14px;
}
.remember-row {
  display: flex; align-items: center; gap: 6px;
  font-size: 12px; color: var(--text-secondary);
  cursor: pointer; justify-content: flex-start;
}
.remember-row input[type="checkbox"] {
  width: 16px; height: 16px; accent-color: var(--primary); cursor: pointer;
  padding: 0;
}
.form-group button {
  padding: 10px; background: var(--primary); color: #fff; border-radius: 8px;
  font-weight: 500; font-size: 15px;
}
.form-group button:disabled { opacity: 0.6; }
.switch-link { font-size: 12px; color: var(--primary); cursor: pointer; margin-top: 4px; }
.error-msg { color: var(--danger); font-size: 12px; margin-top: 8px; }
.version-text { text-align: center; font-size: 11px; color: #bbb; margin-top: 16px; }
</style>
