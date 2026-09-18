<template>
  <div class="p-4 text-left max-w-3xl mx-auto space-y-4">
    <div class="bg-ios-card dark:bg-ios-card rounded-2xl border border-ios-border/20 dark:border-ios-border/40 shadow-[0_8px_30px_var(--color-ios-shadow)] p-4 sm:p-5 space-y-3">
      <div>
        <span class="text-sm sm:text-[15px] font-bold text-ios-text-h dark:text-gray-100">IPTV 直播源导入</span>
        <p class="text-[11px] sm:text-xs text-ios-gray dark:text-gray-400 mt-1">把播放列表地址推送到电视；请求头会写到该源的每个频道上</p>
      </div>

      <div>
        <label class="block text-[11px] sm:text-xs font-bold text-ios-text/80 mb-1">播放列表地址（m3u / txt）</label>
        <input
          v-model="url"
          placeholder="http://…/playlist.m3u"
          class="w-full px-3 py-2.5 bg-ios-bg dark:bg-ios-bg border border-ios-border/10 rounded-xl text-sm text-ios-text-h outline-none transition-all focus:border-ios-blue focus:shadow-[0_0_0_3px_rgba(59,130,246,0.12)] placeholder:text-ios-text/30"
        />
      </div>

      <div>
        <label class="block text-[11px] sm:text-xs font-bold text-ios-text/80 mb-1">名称</label>
        <input
          v-model="name"
          placeholder="留空则用地址命名"
          class="w-full px-3 py-2.5 bg-ios-bg dark:bg-ios-bg border border-ios-border/10 rounded-xl text-sm text-ios-text-h outline-none transition-all focus:border-ios-blue focus:shadow-[0_0_0_3px_rgba(59,130,246,0.12)] placeholder:text-ios-text/30"
        />
      </div>

      <div>
        <label class="block text-[11px] sm:text-xs font-bold text-ios-text/80 mb-1">请求头（每行一个，key: value）</label>
        <textarea
          v-model="headers"
          placeholder="user-agent: okhttp/3.12&#10;referer: http://example.com/&#10;cookie: a=b"
          class="w-full h-28 p-3 bg-ios-bg dark:bg-ios-bg border border-ios-border/10 rounded-xl text-sm font-mono text-ios-text-h outline-none resize-none transition-all focus:border-ios-blue focus:shadow-[0_0_0_3px_rgba(59,130,246,0.12)] placeholder:text-ios-text/30 shadow-inner"
        ></textarea>
      </div>

      <button
        :disabled="loading || !url.trim()"
        class="w-full py-3 bg-ios-blue text-white font-bold rounded-xl text-sm transition-all md:hover:scale-[1.01] active:scale-[0.98] disabled:opacity-40 disabled:cursor-not-allowed cursor-pointer"
        @click="submit"
      >
        {{ loading ? '电视正在导入...' : '导入到电视' }}
      </button>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { api } from '@/services/api.js'
import { useToastStore } from '@/store/toast.js'

const url = ref('')
const name = ref('')
const headers = ref('')
const loading = ref(false)
const toast = useToastStore()

async function submit() {
  const value = url.value.trim()
  if (!value) return
  loading.value = true
  const res = await api.importIptv({ url: value, name: name.value.trim(), headers: parseHeaders(headers.value) })
  toast.show(res.isOk ? '电视已开始导入直播源' : res.msg || '导入失败，请检查地址', res.isOk ? 'success' : 'error')
  loading.value = false
}

function parseHeaders(text) {
  const result = {}
  for (const line of text.split('\n')) {
    const trimmed = line.trim()
    if (!trimmed) continue
    const at = trimmed.indexOf(':')
    if (at <= 0) continue
    result[trimmed.slice(0, at).trim()] = trimmed.slice(at + 1).trim()
  }
  return result
}
</script>
