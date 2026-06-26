<template>
  <div class="p-3 sm:p-4 space-y-4 sm:space-y-5 text-left">
    <div class="flex rounded-xl overflow-hidden bg-ios-card dark:bg-ios-card border border-ios-border/20 dark:border-ios-border/30">
      <button :class="[activeTab === 'streamer' ? 'bg-ios-blue text-white' : 'text-ios-text-h dark:text-ios-text-h']" class="flex-1 py-3 text-sm font-bold transition-colors" @click="activeTab = 'streamer'">主播名称</button>
      <button :class="[activeTab === 'room' ? 'bg-ios-blue text-white' : 'text-ios-text-h dark:text-ios-text-h']" class="flex-1 py-3 text-sm font-bold transition-colors" @click="activeTab = 'room'">直播间名称</button>
    </div>

    <div v-if="activeTab === 'streamer'" class="p-3 sm:p-4 bg-ios-card dark:bg-ios-card border border-ios-border/20 dark:border-ios-border/30 rounded-2xl shadow-[0_8px_30px_var(--color-ios-shadow)] space-y-3">
      <div class="flex items-center justify-between px-0.5">
        <label class="text-[12px] sm:text-[13px] font-bold text-ios-text-h dark:text-ios-text-h tracking-wide opacity-80">搜索主播名</label>
        <button v-if="streamerText.trim()" class="text-xs font-semibold text-ios-blue cursor-pointer active:opacity-60 transition-opacity" @click="clearStreamer">一键清空</button>
      </div>
      <textarea
        v-model="streamerText"
        placeholder="输入主播昵称检索"
        class="w-full h-32 sm:h-36 p-3 sm:p-3.5 bg-ios-bg dark:bg-ios-bg border border-ios-border/10 dark:border-ios-border/20 rounded-xl text-sm sm:text-[15px] font-medium text-ios-text-h dark:text-ios-text-h outline-none resize-none transition-all focus:border-ios-blue focus:shadow-[0_0_0_3px_rgba(59,130,246,0.12)] placeholder:text-ios-text/40 shadow-inner"
        @input="handleStreamerInput"
      ></textarea>
      <div class="flex items-center justify-between px-0.5 text-[10px] sm:text-[11px] text-ios-gray dark:text-ios-gray font-medium">
        <div class="flex items-center gap-2">
          <span>实时同步模式</span>
          <button :class="[autoSync ? 'bg-ios-blue' : 'bg-ios-border/40 dark:bg-ios-border/50']" class="relative w-9 h-5 rounded-full transition-colors duration-200" @click="autoSync = !autoSync">
            <span :class="[autoSync ? 'translate-x-5' : 'translate-x-0.5']" class="absolute top-0.5 left-0.5 w-4 h-4 bg-white rounded-full shadow transition-transform duration-200"></span>
          </button>
        </div>
        <span class="font-mono">已输入 {{ streamerText.length }} 字</span>
      </div>
    </div>

    <div v-if="activeTab === 'room'" class="p-3 sm:p-4 bg-ios-card dark:bg-ios-card border border-ios-border/20 dark:border-ios-border/30 rounded-2xl shadow-[0_8px_30px_var(--color-ios-shadow)] space-y-3">
      <div class="flex items-center justify-between px-0.5">
        <label class="text-[12px] sm:text-[13px] font-bold text-ios-text-h dark:text-ios-text-h tracking-wide opacity-80">搜索房间号</label>
        <button v-if="roomText.trim()" class="text-xs font-semibold text-ios-blue cursor-pointer active:opacity-60 transition-opacity" @click="clearRoom">一键清空</button>
      </div>
      <textarea
        v-model="roomText"
        placeholder="输入直播间名称"
        class="w-full h-32 sm:h-36 p-3 sm:p-3.5 bg-ios-bg dark:bg-ios-bg border border-ios-border/10 dark:border-ios-border/20 rounded-xl text-sm sm:text-[15px] font-medium text-ios-text-h dark:text-ios-text-h outline-none resize-none transition-all focus:border-ios-blue focus:shadow-[0_0_0_3px_rgba(59,130,246,0.12)] placeholder:text-ios-text/40 shadow-inner"
        @input="handleRoomInput"
      ></textarea>
      <div class="flex items-center justify-between px-0.5 text-[10px] sm:text-[11px] text-ios-gray dark:text-ios-gray font-medium">
        <div class="flex items-center gap-2">
          <span>实时同步模式</span>
          <button :class="[autoSync ? 'bg-ios-blue' : 'bg-ios-border/40 dark:bg-ios-border/50']" class="relative w-9 h-5 rounded-full transition-colors duration-200" @click="autoSync = !autoSync">
            <span :class="[autoSync ? 'translate-x-5' : 'translate-x-0.5']" class="absolute top-0.5 left-0.5 w-4 h-4 bg-white rounded-full shadow transition-transform duration-200"></span>
          </button>
        </div>
        <span class="font-mono">已输入 {{ roomText.length }} 字</span>
      </div>
    </div>

    <div>
      <button
        v-if="activeTab === 'streamer'"
        :disabled="loadingStreamer || !streamerText.trim()"
        class="w-full py-3 sm:py-3.5 bg-ios-blue text-white font-bold rounded-2xl text-sm sm:text-[15px] transition-all md:hover:scale-[1.01] active:scale-[0.98] disabled:opacity-40 disabled:cursor-not-allowed cursor-pointer shadow-[0_8px_20px_rgba(0,122,255,0.25)] dark:shadow-[0_8px_20px_rgba(59,130,246,0.3)]"
        @click="triggerSearchStreamer"
      >
        {{ loadingStreamer ? '正在执行检索...' : '立即同步搜索主播' }}
      </button>
      <button
        v-if="activeTab === 'room'"
        :disabled="loadingRoom || !roomText.trim()"
        class="w-full py-3 sm:py-3.5 bg-ios-blue text-white font-bold rounded-2xl text-sm sm:text-[15px] transition-all md:hover:scale-[1.01] active:scale-[0.98] disabled:opacity-40 disabled:cursor-not-allowed cursor-pointer shadow-[0_8px_20px_rgba(0,122,255,0.25)] dark:shadow-[0_8px_20px_rgba(59,130,246,0.3)]"
        @click="triggerSearchRoom"
      >
        {{ loadingRoom ? '正在执行检索...' : '立即同步搜索房间' }}
      </button>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { api } from '@/services/api.js'
import { useToastStore } from '@/store/toast.js'

const activeTab = ref('streamer')
const streamerText = ref('')
const roomText = ref('')
const loadingStreamer = ref(false)
const loadingRoom = ref(false)
const autoSync = ref(true)
const toast = useToastStore()
let streamerTimer = null
let roomTimer = null

function handleStreamerInput() {
  if (!autoSync.value) return
  if (streamerTimer) clearTimeout(streamerTimer)
  streamerTimer = setTimeout(() => {
    const val = streamerText.value.trim()
    if (val) api.sendStreamer(val)
  }, 400)
}

function handleRoomInput() {
  if (!autoSync.value) return
  if (roomTimer) clearTimeout(roomTimer)
  roomTimer = setTimeout(() => {
    const val = roomText.value.trim()
    if (val) api.sendRoom(val)
  }, 400)
}

async function triggerSearchStreamer() {
  const val = streamerText.value.trim()
  if (!val) return
  loadingStreamer.value = true
  const res = await api.sendStreamer(val)
  toast.show(res.isOk ? '主播搜索已同步' : res.msg || '同步失败', res.isOk ? 'success' : 'error')
  loadingStreamer.value = false
}

async function triggerSearchRoom() {
  const val = roomText.value.trim()
  if (!val) return
  loadingRoom.value = true
  const res = await api.sendRoom(val)
  toast.show(res.isOk ? '房间搜索已同步' : res.msg || '同步失败', res.isOk ? 'success' : 'error')
  loadingRoom.value = false
}

function clearStreamer() {
  streamerText.value = ''
   api.sendStreamer('')
  if (streamerTimer) clearTimeout(streamerTimer)
}

function clearRoom() {
  roomText.value = ''
  api.sendRoom('')
  if (roomTimer) clearTimeout(roomTimer)
}
</script>
