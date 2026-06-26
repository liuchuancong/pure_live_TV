<template>
  <div class="p-3 sm:p-4 space-y-4 sm:space-y-5 text-left">
    <div class="p-3 sm:p-4 bg-ios-card dark:bg-ios-card border border-ios-border/20 dark:border-ios-border/30 rounded-2xl shadow-[0_8px_30px_var(--color-ios-shadow)] space-y-3">
      <div class="flex items-center justify-between px-0.5">
        <label class="text-[12px] sm:text-[13px] font-bold text-ios-text-h dark:text-ios-text-h tracking-wide opacity-80">放映链接 / 房间号</label>
        <button v-if="urlText.trim()" class="text-xs font-semibold text-ios-blue cursor-pointer active:opacity-60 transition-opacity" @click="clearMovieUrl">一键清空</button>
      </div>
      <textarea
        v-model="urlText"
        placeholder="粘贴视频直链、放映房间地址、播放链接到此处..."
        class="w-full h-32 sm:h-36 p-3 sm:p-3.5 bg-ios-bg dark:bg-ios-bg rounded-xl text-sm sm:text-[15px] text-ios-text-h dark:text-ios-text-h outline-none resize-none border border-ios-border/10 dark:border-ios-border/20 transition-all focus:border-ios-blue focus:shadow-[0_0_0_3px_rgba(59,130,246,0.12)] placeholder:text-ios-text/40 shadow-inner"
        @input="syncOnInput"
      ></textarea>
      <div class="flex items-center justify-between px-0.5 text-[10px] sm:text-[11px] text-ios-gray dark:text-ios-gray font-medium">
        <div class="flex items-center gap-2">
          <span>实时同步模式</span>
          <button :class="[autoSync ? 'bg-ios-blue' : 'bg-ios-border/40 dark:bg-ios-border/50']" class="relative w-9 h-5 rounded-full transition-colors duration-200" @click="autoSync = !autoSync">
            <span :class="[autoSync ? 'translate-x-5' : 'translate-x-0.5']" class="absolute top-0.5 left-0.5 w-4 h-4 bg-white rounded-full shadow transition-transform duration-200"></span>
          </button>
        </div>
        <span class="font-mono">已输入 {{ urlText.length }} 字</span>
      </div>
    </div>
    <div>
      <button
        :disabled="loading || !urlText.trim()"
        class="w-full py-3 sm:py-3.5 bg-ios-blue text-white font-bold rounded-2xl text-sm sm:text-[15px] transition-all md:hover:scale-[1.01] active:scale-[0.98] disabled:opacity-40 disabled:cursor-not-allowed cursor-pointer shadow-[0_8px_20px_rgba(0,122,255,0.25)] dark:shadow-[0_8px_20px_rgba(59,130,246,0.3)]"
        @click="triggerSend"
      >
        {{ loading ? '发送中...' : '立即发送' }}
      </button>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { api } from '@/services/api.js'
import { useToastStore } from '@/store/toast.js'

const urlText = ref('')
const loading = ref(false)
const autoSync = ref(true)
const toast = useToastStore()
let debounceTimer = null

function syncOnInput() {
  if (!autoSync.value) return
  if (debounceTimer) clearTimeout(debounceTimer)
  debounceTimer = setTimeout(() => {
    const val = urlText.value.trim()
    if (val) api.sendMovie(val)
  }, 400)
}

async function triggerSend() {
  const val = urlText.value.trim()
  if (!val) return
  loading.value = true
  const res = await api.sendMovie(val)
  toast.show(res.isOk ? '地址已推送到电视' : res.msg || '推送失败', res.isOk ? 'success' : 'error')
  loading.value = false
}

function clearMovieUrl() {
  urlText.value = ''
  if (debounceTimer) clearTimeout(debounceTimer)
}
</script>
