<template>
  <div class="p-3 sm:p-4 lg:p-6 text-left">
    <div v-if="route.path === '/cookie'" class="max-w-3xl mx-auto">
      <div class="mb-3 px-1">
        <div class="text-[10px] sm:text-xs font-bold text-ios-text/80 uppercase tracking-wider">平台 Cookie 管理列表</div>
      </div>
      <div class="bg-ios-card dark:bg-ios-card rounded-2xl border border-ios-border/20 dark:border-ios-border/30 shadow-[0_8px_30px_var(--color-ios-shadow)] divide-y divide-ios-border/60 dark:divide-ios-border/40 overflow-hidden">
        <router-link
          v-for="site in supportSites"
          :key="site.id"
          :to="'/cookie/' + site.id"
          class="flex items-center justify-between p-3.5 sm:p-4 no-underline group transition-all md:hover:scale-[1.005] hover:bg-ios-bg/60 dark:hover:bg-ios-border/10 active:scale-[0.98] active:bg-zinc-50/80 dark:active:bg-zinc-800/40"
        >
          <div class="flex items-center gap-3 sm:gap-4">
            <img v-if="site.icon" :src="site.icon" alt="" class="w-7 h-7 sm:w-8 sm:h-8 object-contain shrink-0 rounded-lg" />
            <span v-else class="w-7 h-7 sm:w-8 sm:h-8 shrink-0 rounded-lg flex items-center justify-center text-[10px] sm:text-[11px] font-black uppercase" :class="site.badgeClass">{{ site.badge }}</span>
            <span class="text-sm sm:text-[15px] font-bold text-ios-text-h dark:text-ios-text-h">{{ site.name }}</span>
          </div>
          <ChevronRightIcon class="w-4 h-4 text-ios-text/30 group-hover:text-ios-text-h transition-colors" />
        </router-link>
      </div>
    </div>
    <router-view />
  </div>
</template>

<script setup>
import { useRoute } from 'vue-router'
import { ChevronRight as ChevronRightIcon } from 'lucide-vue-next'

import bilibiliIcon from '@/assets/bilibili.png'
import huyaIcon from '@/assets/huya.png'
import douyinIcon from '@/assets/douyin.png'
import kuaishouIcon from '@/assets/kuaishou.png'
import yyIcon from '@/assets/yy.png'
import soopIcon from '@/assets/soop.png'
import twitchIcon from '@/assets/twitch.png'
const route = useRoute()

// The TV app's own platform list: douyu/cc are gone, yy/soop/twitch are in.
// The three new ones have no logo asset — a monogram badge reads cleaner than
// a broken img.
const supportSites = [
  { id: 'bilibili', name: '哔哩哔哩', icon: bilibiliIcon },
  { id: 'huya', name: '虎牙', icon: huyaIcon },
  { id: 'douyin', name: '抖音', icon: douyinIcon },
  { id: 'kuaishou', name: '快手', icon: kuaishouIcon },
  { id: 'yy', name: 'YY', icon: yyIcon },
  { id: 'soop', name: 'SOOP', icon: soopIcon },
  { id: 'twitch', name: 'Twitch', icon: twitchIcon }
]
</script>
