<template>
  <div class="login-page">
    <div class="login-box">
      <img v-if="settings.logo_url" :src="settings.logo_url" class="login-logo" />
      <h1>{{ settings.shop_name }}</h1>
      <p class="login-subtitle">管理员登录</p>

      <div v-if="!isSignup" class="form-group">
        <input v-model="email" type="email" placeholder="邮箱" />
        <input v-model="password" type="password" placeholder="密码" @keyup.enter="login" />
        <button @click="login" :disabled="loading">{{ loading ? '登录中...' : '登录' }}</button>
        <p class="switch-link" @click="isSignup = true">还没有账号？点击注册</p>
      </div>

      <div v-else class="form-group">
        <input v-model="email" type="email" placeholder="邮箱" />
        <input v-model="password" type="password" placeholder="密码（至少6位）" @keyup.enter="signup" />
        <button @click="signup" :disabled="loading">{{ loading ? '注册中...' : '注册' }}</button>
        <p class="switch-link" @click="isSignup = false">已有账号？返回登录</p>
      </div>

      <p v-if="errorMsg" class="error-msg">{{ errorMsg }}</p>
      <p class="version-text">v2.0.0</p>
    </div>
  </div>
</template>

<script setup>
import { ref, inject } from 'vue'
import { supabase } from '../lib/supabase'
import { useRouter } from 'vue-router'

const settings = inject('shopSettings')
const router = useRouter()

const email = ref('')
const password = ref('')
const loading = ref(false)
const errorMsg = ref('')
const isSignup = ref(false)

async function login() {
  if (!email.value || !password.value) {
    errorMsg.value = '请输入邮箱和密码'
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
    router.push('/admin/dishes')
  }
}

async function signup() {
  if (!email.value || !password.value) {
    errorMsg.value = '请输入邮箱和密码'
    return
  }
  if (password.value.length < 6) {
    errorMsg.value = '密码至少6位'
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
    errorMsg.value = '注册成功！请查收邮箱验证邮件后登录。'
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
  background: #fff; border-radius: 16px; padding: 32px 24px; width: 320px;
  text-align: center; box-shadow: 0 2px 12px rgba(0,0,0,0.08);
}
.login-logo { width: 64px; height: 64px; border-radius: 50%; margin-bottom: 12px; object-fit: cover; }
.login-box h1 { font-size: 20px; margin-bottom: 4px; }
.login-subtitle { color: var(--text-secondary); font-size: 13px; margin-bottom: 20px; }
.form-group { display: flex; flex-direction: column; gap: 10px; }
.form-group input {
  padding: 10px 12px; border: 1px solid #ddd; border-radius: 8px; font-size: 14px;
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
