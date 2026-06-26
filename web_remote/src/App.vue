<template>
  <div class="min-h-screen bg-ios-bg text-ios-text transition-colors duration-200 pb-12 select-none">
    <header class="sticky top-0 z-50 flex items-center justify-between px-4 py-3 bg-ios-card border-b border-ios-border/30 backdrop-blur-xl bg-opacity-80">
      <div class="flex items-center gap-1">
        <!-- 💡 动态判断：如果是首页显示设置图标，其他子页面显示 iOS 返回剪头 -->
        <button v-if="route.path !== '/'" class="text-ios-blue flex items-center justify-center -ml-2 p-1 cursor-pointer active:opacity-50" @click="router.back()">
          <ChevronLeftIcon class="w-6 h-6 stroke-[2.5]" />
        </button>
        <div v-else class="w-5 h-5 text-ios-blue flex items-center justify-center mr-1">
          <img :src="AppIcon" alt="App Icon" class="w-5 h-5 stroke-[2.2]" />
        </div>

        <!-- 💡 标题动态绑定当前页面的元信息 -->
        <span class="text-base font-bold text-ios-text-h tracking-tight">
          {{ route.meta.title || '遥控中心' }}
        </span>
      </div>

      <button class="w-8 h-8 flex items-center justify-center text-ios-blue hover:opacity-70 active:scale-90 transition-all cursor-pointer" @click="toggleDarkMode">
        <SunIcon v-if="isDark" class="w-5 h-5 stroke-" />
        <MoonIcon v-else class="w-5 h-5 stroke-" />
      </button>
    </header>

    <main class="max-w-5xl mx-auto w-full">
      <router-view />
    </main>

    <Toast />
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router' // 引入路由状态
import { Sun as SunIcon, Moon as MoonIcon, ChevronLeft as ChevronLeftIcon } from 'lucide-vue-next'
import Toast from './components/Toast.vue'
import AppIcon from '@/assets/icon.png'
const route = useRoute()
const router = useRouter()
const isDark = ref(false)

function toggleDarkMode() {
  isDark.value = !isDark.value
  const docClass = document.documentElement.classList
  if (isDark.value) {
    docClass.add('dark')
    localStorage.setItem('theme', 'dark')
  } else {
    docClass.remove('dark')
    localStorage.setItem('theme', 'light')
  }
}

onMounted(() => {
  const localTheme = localStorage.getItem('theme')
  const systemPrefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches
  if (localTheme === 'dark' || (!localTheme && systemPrefersDark)) {
    isDark.value = true
    document.documentElement.classList.add('dark')
  } else {
    isDark.value = false
    document.documentElement.classList.remove('dark')
  }
})
</script>
