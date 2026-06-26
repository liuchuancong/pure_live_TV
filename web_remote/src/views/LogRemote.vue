<template>
  <div class="p-3 sm:p-4 lg:p-6 text-left max-w-3xl mx-auto space-y-4">
    <div class="mb-3 px-1 flex items-center justify-between">
      <div class="flex items-center space-x-2 text-[10px] sm:text-xs font-bold text-ios-text/80 uppercase tracking-wider">
        <TerminalIcon class="w-3.5 h-3.5 text-ios-blue animate-pulse" />
        <span>系统实时日志</span>
      </div>
      <div class="text-[10px] sm:text-xs text-ios-gray dark:text-gray-400 font-mono">共 {{ logList.length }} 条记录</div>
    </div>

    <div class="flex gap-2 flex-wrap">
      <button class="px-4 py-2.5 bg-ios-blue text-white font-bold rounded-xl text-sm transition-all hover:scale-[1.01] active:scale-[0.98] cursor-pointer dark:shadow-[0_0_12px_2px_rgba(130,180,255,0.2)] flex items-center space-x-1.5" @click="refreshLog">
        <RefreshCwIcon class="w-4 h-4" />
        <span>刷新</span>
      </button>
      <button class="px-4 py-2.5 bg-emerald-500 text-white font-bold rounded-xl text-sm transition-all hover:scale-[1.01] active:scale-[0.98] cursor-pointer dark:shadow-[0_0_12px_2px_rgba(52,211,153,0.2)] flex items-center space-x-1.5" @click="downloadLogFile">
        <DownloadIcon class="w-4 h-4" />
        <span>下载</span>
      </button>
      <button class="px-4 py-2.5 bg-red-500 text-white font-bold rounded-xl text-sm transition-all hover:scale-[1.01] active:scale-[0.98] cursor-pointer dark:shadow-[0_0_12px_2px_rgba(248,113,113,0.2)] flex items-center space-x-1.5" @click="clearAllLog">
        <Trash2Icon class="w-4 h-4" />
        <span>清空</span>
      </button>
    </div>

    <div ref="logContainerRef" class="bg-black border border-neutral-800 rounded-2xl shadow-2xl p-4 font-mono text-[11px] sm:text-xs leading-relaxed max-h-[60vh] overflow-y-auto scroll-smooth">
      <div v-if="logList.length === 0" class="py-16 text-center text-neutral-500 flex flex-col items-center justify-center space-y-2">
        <Loader2Icon class="w-5 h-5 animate-spin text-neutral-600" />
        <span>暂无系统日志，等待自动拉取...</span>
      </div>
      <div v-else class="space-y-0.5 selection:bg-neutral-700 selection:text-white">
        <div v-for="(item, idx) in logList" :key="idx" class="flex items-start py-0.5 px-1 hover:bg-neutral-900 rounded transition-colors group">
          <span class="w-8 select-none text-neutral-600 text-right pr-2 font-mono text-[10px] sm:text-xs">
            {{ idx + 1 }}
          </span>
          <ChevronRightIcon class="w-3.5 h-3.5 text-neutral-600 mt-0.5 pr-0.5 flex-shrink-0 group-hover:text-ios-blue transition-colors" />
          <span class="text-neutral-300 break-all whitespace-pre-wrap flex-1">{{ item }}</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted, nextTick } from 'vue'
import { Terminal as TerminalIcon, RefreshCw as RefreshCwIcon, Download as DownloadIcon, Trash2 as Trash2Icon, ChevronRight as ChevronRightIcon, Loader2 as Loader2Icon } from 'lucide-vue-next'
import { api } from '@/services/api.js'
import { useToastStore } from '@/store/toast.js'

const toast = useToastStore()
const logList = ref([])
const logContainerRef = ref(null)
let timer = null

const scrollToBottom = async () => {
  await nextTick()
  if (logContainerRef.value) {
    logContainerRef.value.scrollTop = logContainerRef.value.scrollHeight
  }
}

const fetchLogs = async (isManual = false) => {
  const res = await api.fetchLogs()
  if (res.isOk && Array.isArray(res.data)) {
    const isAtBottom = logContainerRef.value ? logContainerRef.value.scrollHeight - logContainerRef.value.scrollTop <= logContainerRef.value.clientHeight + 60 : true

    logList.value = res.data

    if (isManual || isAtBottom) {
      scrollToBottom()
    }
  }
}

const refreshLog = async () => {
  await fetchLogs(true)
}

const downloadLogFile = async () => {
  const res = await api.downloadLogs()
  if (!res.isOk) {
    toast.show(res.msg || '下载失败', 'error')
    return
  }
  try {
    const data = res.data || res
    const blob = new Blob([typeof data === 'string' ? data : JSON.stringify(data, null, 2)], { type: 'text/plain' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = `system-log-${Date.now()}.log`
    document.body.appendChild(a)
    a.click()
    document.body.removeChild(a)
    URL.revokeObjectURL(url)
    toast.show('下载成功', 'success')
  } catch {
    toast.show('生成日志文件失败', 'error')
  }
}

const clearAllLog = async () => {
  const res = await api.clearLog()
  if (res.isOk) {
    logList.value = []
    toast.show('清空成功', 'success')
  } else {
    toast.show(res.msg || '清空失败', 'error')
  }
}

onMounted(async () => {
  await fetchLogs(true)
  timer = setInterval(() => fetchLogs(false), 2000)
})

onUnmounted(() => {
  if (timer) clearInterval(timer)
})
</script>
