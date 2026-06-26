<template>
  <div class="p-3 sm:p-4 space-y-4 sm:space-y-5 text-left">
    <!-- ttwid 输入卡片 -->
    <div class="p-3 sm:p-4 bg-ios-card dark:bg-ios-card border border-ios-border/20 dark:border-ios-border/30 rounded-2xl shadow-[0_8px_30px_var(--color-ios-shadow)] space-y-3 sm:space-y-4">
      <div class="flex items-center justify-between px-0.5">
        <label class="text-[12px] sm:text-[13px] font-bold text-ios-text-h dark:text-ios-text-h tracking-wide opacity-80">输入 ttwid</label>
        <button v-if="ttwid.trim()" class="text-xs font-semibold text-ios-blue cursor-pointer active:opacity-60 transition-opacity" @click="ttwid = ''">一键清空</button>
      </div>
      <textarea
        v-model="ttwid"
        placeholder="在此输入 Douyin ttwid..."
        class="w-full h-20 p-3 sm:p-3.5 bg-ios-bg dark:bg-ios-bg border border-ios-border/10 dark:border-ios-border/20 rounded-xl text-sm sm:text-[15px] font-medium text-ios-text-h dark:text-ios-text-h outline-none resize-none transition-all focus:border-ios-blue focus:shadow-[0_0_0_3px_rgba(59,130,246,0.12)] placeholder:text-ios-text/40 shadow-inner"
        @input="handleTtwidInput"
      ></textarea>
      <div class="flex items-center justify-between px-0.5 text-[10px] sm:text-[11px] text-ios-gray dark:text-ios-gray font-medium">
        <div class="flex items-center gap-2">
          <span>实时同步模式</span>
          <button class="relative w-9 h-5 rounded-full transition-colors duration-200" :class="autoSync ? 'bg-ios-blue' : 'bg-ios-border/40 dark:bg-ios-border/60'" @click="autoSync = !autoSync">
            <span class="absolute top-0.5 left-0.5 w-4 h-4 rounded-full shadow transition-transform duration-200" :class="autoSync ? 'translate-x-5 bg-white' : 'translate-x-0.5 bg-ios-card dark:bg-ios-bg'"></span>
          </button>
        </div>
        <span class="font-mono">已输入 {{ ttwid.length }} 字</span>
      </div>
    </div>

    <!-- Cookie 输入卡片 -->
    <div class="p-3 sm:p-4 bg-ios-card dark:bg-ios-card border border-ios-border/20 dark:border-ios-border/30 rounded-2xl shadow-[0_8px_30px_var(--color-ios-shadow)] space-y-3 sm:space-y-4">
      <div class="flex items-center justify-between px-0.5">
        <label class="text-[12px] sm:text-[13px] font-bold text-ios-text-h dark:text-ios-text-h tracking-wide opacity-80">输入 Cookie</label>
        <button v-if="cookieData.trim()" class="text-xs font-semibold text-ios-blue cursor-pointer active:opacity-60 transition-opacity" @click="cookieData = ''">一键清空</button>
      </div>
      <textarea
        v-model="cookieData"
        placeholder="在此输入 Douyin Cookie..."
        class="w-full h-32 sm:h-36 p-3 sm:p-3.5 bg-ios-bg dark:bg-ios-bg border border-ios-border/10 dark:border-ios-border/20 rounded-xl text-sm sm:text-[15px] font-medium text-ios-text-h dark:text-ios-text-h outline-none resize-none transition-all focus:border-ios-blue focus:shadow-[0_0_0_3px_rgba(59,130,246,0.12)] placeholder:text-ios-text/40 shadow-inner"
        @input="handleCookieInput"
      ></textarea>
      <div class="flex items-center justify-between px-0.5 text-[10px] sm:text-[11px] text-ios-gray dark:text-ios-gray font-medium">
        <div class="flex items-center gap-2">
          <span>实时同步模式</span>
          <button class="relative w-9 h-5 rounded-full transition-colors duration-200" :class="autoSync ? 'bg-ios-blue' : 'bg-ios-border/40 dark:bg-ios-border/60'" @click="autoSync = !autoSync">
            <span class="absolute top-0.5 left-0.5 w-4 h-4 rounded-full shadow transition-transform duration-200" :class="autoSync ? 'translate-x-5 bg-white' : 'translate-x-0.5 bg-ios-card dark:bg-ios-bg'"></span>
          </button>
        </div>
        <span class="font-mono">已输入 {{ cookieData.length }} 字</span>
      </div>
    </div>

    <!-- 提交按钮 -->
    <div>
      <button
        :disabled="loading || (!ttwid.trim() && !cookieData.trim())"
        class="w-full py-3 sm:py-3.5 bg-ios-blue text-white font-bold rounded-2xl text-sm sm:text-[15px] transition-all md:hover:scale-[1.01] active:scale-[0.98] disabled:opacity-40 disabled:cursor-not-allowed cursor-pointer shadow-[0_8px_20px_rgba(0,122,255,0.25)] dark:shadow-[0_8px_20px_rgba(59,130,246,0.3)]"
        @click="submitCookie"
      >
        {{ loading ? '正在同步...' : '立即同步' }}
      </button>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { api } from '@/services/api.js'
import { useToastStore } from '@/store/toast.js'

const ttwid = ref('')
const cookieData = ref('')
const loading = ref(false)
const autoSync = ref(true)
const toast = useToastStore()
let ttwidTimer = null
let cookieTimer = null

onMounted(async () => {
  const data = await api.getDouyinCookie()
  if (data) {
    ttwid.value = data.ttwid || ''
    cookieData.value = data.cookie || ''
  }
})

function handleTtwidInput() {
  if (!autoSync.value) return
  if (ttwidTimer) clearTimeout(ttwidTimer)
  ttwidTimer = setTimeout(() => {
    api.updateDouyinCookie(ttwid.value.trim(), cookieData.value.trim())
  }, 400)
}

function handleCookieInput() {
  if (!autoSync.value) return
  if (cookieTimer) clearTimeout(cookieTimer)
  cookieTimer = setTimeout(() => {
    api.updateDouyinCookie(ttwid.value.trim(), cookieData.value.trim())
  }, 400)
}

async function submitCookie() {
  loading.value = true
  const tw = ttwid.value.trim()
  const ck = cookieData.value.trim()
  const res = await api.updateDouyinCookie(tw, ck)
  toast.show(res.isOk ? '抖音信息已同步至电视端' : res.msg || '同步失败，请重试', res.isOk ? 'success' : 'error')
  loading.value = false
}
</script>
