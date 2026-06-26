<template>
  <div class="p-3 sm:p-4 space-y-5 sm:space-y-6 max-w-5xl mx-auto">
    <div class="p-3 sm:p-4 bg-ios-card rounded-2xl flex flex-row items-center justify-between border border-ios-border/20 shadow-[0_8px_30px_var(--color-ios-shadow)]">
      <div class="flex items-center gap-2 sm:gap-3">
        <div class="w-2.5 h-2.5 rounded-full" :class="serverOnline ? 'bg-emerald-500 shadow-[0_0_12px_#10b981] animate-pulse' : 'bg-red-500 shadow-[0_0_12px_#ef4444]'"></div>
        <span class="text-xs sm:text-sm font-bold text-ios-text-h">局域网同步服务器</span>
      </div>
      <span class="text-[10px] sm:text-[11px] font-mono font-bold px-2 py-1 rounded-md" :class="serverOnline ? 'text-ios-blue bg-ios-blue/10' : 'text-red-500 bg-red-500/10'">
        {{ serverOnline ? `连接正常，版本号：v ${remoteVersion}` : '连接异常' }}
      </span>
    </div>

    <template v-for="group in groupList" :key="group.label">
      <div class="space-y-2 sm:space-y-3">
        <div class="px-1 text-[10px] sm:text-xs font-bold text-ios-text/80 uppercase tracking-wider text-left">
          {{ group.label }}
        </div>
        <div :class="[group.gridClass, 'gap-3 sm:gap-4']">
          <router-link v-for="item in group.menuList" :key="item.path" :to="item.path" :class="[item.colClass, cardBaseClass]">
            <div class="flex items-center gap-3 sm:gap-4 text-left">
              <div class="w-8 h-8 rounded-xl flex items-center justify-center shrink-0" :class="item.iconBgClass">
                <component :is="item.icon" class="w-4 h-4 stroke-[2.5]" />
              </div>
              <div class="flex flex-col">
                <span class="text-sm sm:text-[15px] font-bold text-ios-text-h">{{ item.title }}</span>
                <span class="text-xs text-ios-text mt-0.5" :class="item.descShowClass">
                  {{ item.desc }}
                </span>
              </div>
            </div>
            <ChevronRightIcon class="w-4 h-4 text-ios-text/30 group-hover:text-ios-text-h transition-colors" />
          </router-link>
        </div>
      </div>
    </template>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { Link as LinkIcon, Search as SearchIcon, Key as KeyIcon, Cloud as CloudIcon, EyeOff as EyeOffIcon, RefreshCw as RefreshIcon, ChevronRight as ChevronRightIcon, Info as InfoIcon, FileText as FileTextIcon, Heart as HeartIcon } from 'lucide-vue-next'
import { api } from '@/services/api.js'

const serverOnline = ref(false)
const remoteVersion = ref('0.0.0')
const cardBaseClass = `
  flex items-center justify-between p-3 sm:p-4 no-underline bg-ios-card 
  border border-ios-border/20 rounded-2xl shadow-[0_8px_30px_var(--color-ios-shadow)] 
  transition-all hover:scale-[1.01] active:scale-[0.98] group
`
const checkServerStatus = async () => {
  try {
    const res = await api.getVersion()
    if (res.isOk && res.data?.version) {
      serverOnline.value = true
      remoteVersion.value = res.data.version
    } else {
      serverOnline.value = false
    }
  } catch {
    serverOnline.value = false
  }
}

onMounted(() => {
  checkServerStatus()
})
const groupList = [
  {
    label: '电视输入控制',
    gridClass: 'grid grid-cols-1 md:grid-cols-2',
    menuList: [
      {
        path: '/movie',
        title: '链接解析',
        desc: '推送视频链接',
        icon: LinkIcon,
        iconBgClass: 'bg-blue-500/10 text-blue-500',
        colClass: '',
        descShowClass: 'hidden sm:block'
      },
      {
        path: '/search',
        title: '搜索页面',
        desc: '大屏联动键盘同步打字',
        icon: SearchIcon,
        iconBgClass: 'bg-indigo-500/10 text-indigo-500',
        colClass: '',
        descShowClass: 'hidden sm:block'
      }
    ]
  },
  {
    label: '账户凭证',
    gridClass: 'grid grid-cols-1 md:grid-cols-2',
    menuList: [
      {
        path: '/cookie',
        title: '各平台 Cookie 管理',
        desc: '全独立平台 Cookie 录入与抖音 ttwid 拦截',
        icon: KeyIcon,
        iconBgClass: 'bg-purple-500/10 text-purple-500',
        colClass: 'md:col-span-2',
        descShowClass: 'hidden sm:block'
      }
    ]
  },
  {
    label: '内容过滤设置',
    gridClass: 'grid grid-cols-1 md:grid-cols-2',
    menuList: [
      {
        path: '/danmaku',
        title: '弹幕关键词过滤',
        desc: '自定义黑名单屏蔽词',
        icon: EyeOffIcon,
        iconBgClass: 'bg-zinc-500/10 text-zinc-500',
        colClass: 'md:col-span-2',
        descShowClass: 'hidden sm:block'
      }
    ]
  },
  {
    label: '数据同步与备份',
    gridClass: 'grid grid-cols-1 md:grid-cols-2',
    menuList: [
      {
        path: '/webdav_settings',
        title: 'WebDAV 配置',
        desc: '管理云端同步账户',
        icon: CloudIcon,
        iconBgClass: 'bg-orange-500/10 text-orange-500',
        colClass: '',
        descShowClass: 'hidden lg:block'
      },
      {
        path: '/sync',
        title: '数据导入与导出',
        desc: '备份与迁移',
        icon: RefreshIcon,
        iconBgClass: 'bg-rose-500/10 text-rose-500',
        colClass: '',
        descShowClass: 'hidden lg:block'
      }
    ]
  },
  {
    label: '系统信息与维护',
    gridClass: 'grid grid-cols-1 md:grid-cols-2',
    menuList: [
      {
        path: '/log',
        title: '系统日志查看与下载',
        desc: '分析日志输出',
        icon: FileTextIcon,
        iconBgClass: 'bg-amber-500/10 text-amber-500',
        colClass: '',
        descShowClass: 'hidden sm:block'
      },
      {
        path: '/about',
        title: '关于程序',
        desc: '运行版本与环境说明',
        icon: InfoIcon,
        iconBgClass: 'bg-slate-500/10 text-slate-500',
        colClass: '',
        descShowClass: 'hidden lg:block'
      }
    ]
  },
  {
    label: '支持开发者',
    gridClass: 'grid grid-cols-1 md:grid-cols-2',
    menuList: [
      {
        path: '/donate',
        title: '捐赠支持',
        desc: '项目好用可以赞助开发者',
        icon: HeartIcon,
        iconBgClass: 'bg-pink-500/10 text-pink-500',
        colClass: 'md:col-span-2',
        descShowClass: 'hidden sm:block'
      }
    ]
  }
]
</script>
