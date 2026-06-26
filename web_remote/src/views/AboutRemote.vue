<template>
  <div class="p-4 sm:p-6 max-w-2xl mx-auto space-y-6 text-left">
    <div class="p-6 bg-ios-card dark:bg-neutral-900 rounded-2xl border border-ios-border/20 dark:border-white/10 shadow-[0_8px_30px_var(--color-ios-shadow)] dark:shadow-[0_20px_50px_rgba(0,0,0,0.4)] flex flex-col items-center text-center space-y-4">
      <div class="w-16 h-16 rounded-2xl bg-ios-bg dark:bg-black p-2 flex items-center justify-center border border-ios-border/10 dark:border-white/5 shadow-inner">
        <img :src="AppIcon" alt="App Icon" class="w-full h-full object-contain shrink-0 rounded-xl" />
      </div>
      <div>
        <h3 class="text-xl font-bold text-ios-text-h dark:text-white">PureLive TV</h3>
        <p class="text-xs text-ios-gray dark:text-gray-400 font-mono mt-1">Version {{ remoteVersion }} (Build 202606)</p>
      </div>
      <a href="https://github.com/liuchuancong/pure_live_TV" target="_blank" class="flex items-center gap-2 px-4 py-2.5 bg-zinc-100 dark:bg-white/5 border border-transparent dark:border-white/5 rounded-xl transition-all hover:bg-zinc-200 dark:hover:bg-white/10 active:scale-[0.98] cursor-pointer">
        <GithubIcon class="w-4 h-4 text-ios-text-h dark:text-gray-200" />
        <span class="text-sm font-semibold text-ios-text-h dark:text-gray-200">GitHub 开源仓库</span>
      </a>
    </div>

    <div class="bg-ios-card dark:bg-neutral-900 rounded-2xl border border-ios-border/20 dark:border-white/10 shadow-[0_8px_30px_var(--color-ios-shadow)] dark:shadow-[0_20px_50px_rgba(0,0,0,0.4)] divide-y divide-ios-border/40 dark:divide-white/5 overflow-hidden text-sm">
      <div class="p-4 flex items-center justify-between gap-4 hover:bg-zinc-50/50 dark:hover:bg-white/[0.02] transition-colors">
        <div class="flex items-center gap-3">
          <div class="w-7 h-7 rounded-lg bg-ios-blue/10 dark:bg-ios-blue/20 flex items-center justify-center flex-shrink-0">
            <HomeIcon class="w-4 h-4 text-ios-blue" />
          </div>
          <span class="font-medium text-ios-text-h dark:text-gray-200">程序主页</span>
        </div>
        <a href="https://github.com/liuchuancong/pure_live_TV" target="_blank" class="text-ios-gray dark:text-gray-400 font-mono text-right">PureLive TV</a>
      </div>
      <div class="p-4 flex items-center justify-between gap-4 hover:bg-zinc-50/50 dark:hover:bg-white/[0.02] transition-colors">
        <div class="flex items-center gap-3">
          <div class="w-7 h-7 rounded-lg bg-ios-blue/10 dark:bg-ios-blue/20 flex items-center justify-center flex-shrink-0">
            <ServerIcon class="w-4 h-4 text-ios-blue" />
          </div>
          <span class="font-medium text-ios-text-h dark:text-gray-200">运行环境</span>
        </div>
        <span class="text-ios-gray dark:text-gray-400 font-mono text-right">Embedded Shelf Server</span>
      </div>
      <div class="p-4 flex items-center justify-between gap-4 hover:bg-zinc-50/50 dark:hover:bg-white/[0.02] transition-colors">
        <div class="flex items-center gap-3">
          <div class="w-7 h-7 rounded-lg bg-ios-blue/10 dark:bg-ios-blue/20 flex items-center justify-center flex-shrink-0">
            <CodeIcon class="w-4 h-4 text-ios-blue" />
          </div>
          <span class="font-medium text-ios-text-h dark:text-gray-200">编译框架</span>
        </div>
        <span class="text-ios-gray dark:text-gray-400 font-mono text-right">Vue 3 / Vite</span>
      </div>
      <div class="p-4 flex items-center justify-between gap-4 hover:bg-zinc-50/50 dark:hover:bg-white/[0.02] transition-colors">
        <div class="flex items-center gap-3">
          <div class="w-7 h-7 rounded-lg bg-ios-blue/10 dark:bg-ios-blue/20 flex items-center justify-center flex-shrink-0">
            <PaletteIcon class="w-4 h-4 text-ios-blue" />
          </div>
          <span class="font-medium text-ios-text-h dark:text-gray-200">核心样式</span>
        </div>
        <span class="text-ios-gray dark:text-gray-400 font-mono text-right">Tailwind CSS v4</span>
      </div>
    </div>

    <div class="text-center text-[11px] text-ios-gray dark:text-gray-500 font-mono tracking-wider pt-2">&copy; 2026 PureLive. All Rights Reserved.</div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { api } from '@/services/api.js'
import AppIcon from '@/assets/icon.png'
import { Github as GithubIcon, Home as HomeIcon, Server as ServerIcon, Code as CodeIcon, Palette as PaletteIcon } from 'lucide-vue-next'

const remoteVersion = ref('0.0.0')

const getVersionInfo = async () => {
  const res = await api.getVersion()
  if (res.isOk && res.data?.version) {
    remoteVersion.value = res.data.version
  }
}

onMounted(() => {
  getVersionInfo()
})
</script>
