<template>
  <div class="p-4 text-left max-w-3xl mx-auto space-y-4">
    <!-- 播放列表导入：网络地址 或 本地文件上传 -->
    <div class="bg-ios-card dark:bg-ios-card rounded-2xl border border-ios-border/20 dark:border-ios-border/40 shadow-[0_8px_30px_var(--color-ios-shadow)] p-4 sm:p-5 space-y-3">
      <div>
        <span class="text-sm sm:text-[15px] font-bold text-ios-text-h dark:text-gray-100">IPTV 直播源导入</span>
        <p class="text-[11px] sm:text-xs text-ios-gray dark:text-gray-400 mt-1">填写网络地址或上传 m3u/txt 文件，推送到电视</p>
      </div>

      <div class="flex rounded-xl bg-ios-bg dark:bg-ios-bg p-1 text-xs font-bold">
        <button
          class="flex-1 py-2 rounded-lg transition-all cursor-pointer"
          :class="mode === 'url' ? 'bg-ios-blue text-white shadow' : 'text-ios-gray'"
          @click="mode = 'url'"
        >网络地址导入</button>
        <button
          class="flex-1 py-2 rounded-lg transition-all cursor-pointer"
          :class="mode === 'file' ? 'bg-ios-blue text-white shadow' : 'text-ios-gray'"
          @click="mode = 'file'"
        >上传文件导入</button>
      </div>

      <div v-if="mode === 'url'">
        <label class="block text-[11px] sm:text-xs font-bold text-ios-text/80 mb-1">播放列表地址（m3u / txt）</label>
        <input
          v-model="url"
          placeholder="http://…/playlist.m3u"
          class="w-full px-3 py-2.5 bg-ios-bg dark:bg-ios-bg border border-ios-border/10 rounded-xl text-sm text-ios-text-h outline-none transition-all focus:border-ios-blue focus:shadow-[0_0_0_3px_rgba(59,130,246,0.12)] placeholder:text-ios-text/30"
        />
      </div>

      <div v-else>
        <label class="block text-[11px] sm:text-xs font-bold text-ios-text/80 mb-1">播放列表文件（m3u / m3u8 / txt）</label>
        <input
          ref="fileRef"
          type="file"
          accept=".m3u,.m3u8,.txt"
          class="w-full px-3 py-2.5 bg-ios-bg dark:bg-ios-bg border border-ios-border/10 rounded-xl text-sm text-ios-text-h file:mr-3 file:px-3 file:py-1.5 file:rounded-lg file:border-0 file:bg-ios-blue file:text-white file:text-xs file:cursor-pointer"
          @change="onFileChange"
        />
        <p v-if="fileName" class="text-[11px] text-ios-gray mt-1">已选择：{{ fileName }}</p>
      </div>

      <div>
        <label class="block text-[11px] sm:text-xs font-bold text-ios-text/80 mb-1">名称</label>
        <input
          v-model="name"
          placeholder="留空则用地址/文件名命名"
          class="w-full px-3 py-2.5 bg-ios-bg dark:bg-ios-bg border border-ios-border/10 rounded-xl text-sm text-ios-text-h outline-none transition-all focus:border-ios-blue focus:shadow-[0_0_0_3px_rgba(59,130,246,0.12)] placeholder:text-ios-text/30"
        />
      </div>

      <button
        :disabled="loading || (mode === 'url' ? !url.trim() : !fileContent)"
        class="w-full py-3 bg-ios-blue text-white font-bold rounded-xl text-sm transition-all md:hover:scale-[1.01] active:scale-[0.98] disabled:opacity-40 disabled:cursor-not-allowed cursor-pointer"
        @click="submit"
      >
        {{ loading ? '电视正在导入...' : '导入到电视' }}
      </button>
    </div>

    <!-- 请求头：分开的三个字段，可只保存不导入 -->
    <div class="bg-ios-card dark:bg-ios-card rounded-2xl border border-ios-border/20 dark:border-ios-border/40 shadow-[0_8px_30px_var(--color-ios-shadow)] p-4 sm:p-5 space-y-3">
      <div>
        <span class="text-sm sm:text-[15px] font-bold text-ios-text-h dark:text-gray-100">直播源请求头</span>
        <p class="text-[11px] sm:text-xs text-ios-gray dark:text-gray-400 mt-1">导入时写入该源每个频道；单独保存则作为电视上所有直播源的全局请求头</p>
      </div>

      <div>
        <label class="block text-[11px] sm:text-xs font-bold text-ios-text/80 mb-1">User-Agent</label>
        <input
          v-model="userAgent"
          placeholder="okhttp/3.12 或 Mozilla/5.0…"
          class="w-full px-3 py-2.5 bg-ios-bg dark:bg-ios-bg border border-ios-border/10 rounded-xl text-sm font-mono text-ios-text-h outline-none transition-all focus:border-ios-blue focus:shadow-[0_0_0_3px_rgba(59,130,246,0.12)] placeholder:text-ios-text/30"
        />
      </div>

      <div>
        <label class="block text-[11px] sm:text-xs font-bold text-ios-text/80 mb-1">Referer</label>
        <input
          v-model="referer"
          placeholder="http://example.com/"
          class="w-full px-3 py-2.5 bg-ios-bg dark:bg-ios-bg border border-ios-border/10 rounded-xl text-sm font-mono text-ios-text-h outline-none transition-all focus:border-ios-blue focus:shadow-[0_0_0_3px_rgba(59,130,246,0.12)] placeholder:text-ios-text/30"
        />
      </div>

      <div>
        <label class="block text-[11px] sm:text-xs font-bold text-ios-text/80 mb-1">Cookie</label>
        <input
          v-model="cookie"
          placeholder="a=b; c=d"
          class="w-full px-3 py-2.5 bg-ios-bg dark:bg-ios-bg border border-ios-border/10 rounded-xl text-sm font-mono text-ios-text-h outline-none transition-all focus:border-ios-blue focus:shadow-[0_0_0_3px_rgba(59,130,246,0.12)] placeholder:text-ios-text/30"
        />
      </div>

      <button
        :disabled="savingHeaders"
        class="w-full py-3 bg-ios-bg dark:bg-ios-bg border border-ios-border/20 text-ios-text-h dark:text-gray-100 font-bold rounded-xl text-sm transition-all md:hover:scale-[1.01] active:scale-[0.98] disabled:opacity-40 disabled:cursor-not-allowed cursor-pointer"
        @click="saveHeaders"
      >
        {{ savingHeaders ? '正在保存...' : '仅保存请求头到电视' }}
      </button>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { api } from '@/services/api.js'
import { useToastStore } from '@/store/toast.js'

const mode = ref('url')
const url = ref('')
const name = ref('')
const fileContent = ref('')
const fileName = ref('')
const userAgent = ref('')
const referer = ref('')
const cookie = ref('')
const loading = ref(false)
const savingHeaders = ref(false)
const toast = useToastStore()

onMounted(async () => {
  const data = await api.getIptvHeaders()
  if (data) {
    userAgent.value = data.userAgent || ''
    referer.value = data.referer || ''
    cookie.value = data.cookie || ''
  }
})

function onFileChange(e) {
  const file = e.target.files[0]
  if (!file) {
    fileContent.value = ''
    fileName.value = ''
    return
  }
  fileName.value = file.name
  const reader = new FileReader()
  reader.onload = ev => {
    fileContent.value = typeof ev.target.result === 'string' ? ev.target.result : ''
  }
  reader.readAsText(file)
}

function headerPayload() {
  const result = {}
  if (userAgent.value.trim()) result['user-agent'] = userAgent.value.trim()
  if (referer.value.trim()) result['referer'] = referer.value.trim()
  if (cookie.value.trim()) result['cookie'] = cookie.value.trim()
  return result
}

async function submit() {
  loading.value = true
  const payload = { name: name.value.trim(), headers: headerPayload() }
  if (mode.value === 'url') {
    payload.url = url.value.trim()
  } else {
    payload.content = fileContent.value
    if (!payload.name && fileName.value) payload.name = fileName.value.replace(/\.(m3u8?|txt)$/i, '')
  }
  const res = await api.importIptv(payload)
  toast.show(res.isOk ? '电视已开始导入直播源' : res.msg || '导入失败，请检查地址或文件', res.isOk ? 'success' : 'error')
  loading.value = false
}

async function saveHeaders() {
  savingHeaders.value = true
  const res = await api.saveIptvHeaders({
    userAgent: userAgent.value.trim(),
    referer: referer.value.trim(),
    cookie: cookie.value.trim()
  })
  toast.show(res.isOk ? '请求头已保存到电视' : res.msg || '保存失败', res.isOk ? 'success' : 'error')
  savingHeaders.value = false
}
</script>
