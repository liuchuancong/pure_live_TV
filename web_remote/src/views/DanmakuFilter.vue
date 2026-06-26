<template>
  <div class="p-3 sm:p-4 lg:p-6 text-left max-w-3xl mx-auto">
    <div class="mb-3 px-1">
      <div class="text-[10px] sm:text-xs font-bold text-ios-text/80 uppercase tracking-wider">弹幕过滤关键词列表</div>
    </div>

    <div class="bg-ios-card dark:bg-ios-card rounded-2xl border border-ios-border/20 dark:border-ios-border/40 shadow-[0_8px_30px_var(--color-ios-shadow)] overflow-hidden mb-4 p-4 sm:p-5 space-y-4">
      <div class="flex gap-2">
        <input
          v-model="currentWord"
          placeholder="输入屏蔽关键词"
          class="flex-1 p-3 sm:p-3.5 bg-ios-bg dark:bg-ios-bg border border-ios-border/10 dark:border-ios-border/20 rounded-xl text-sm sm:text-[15px] text-ios-text-h dark:text-gray-100 outline-none transition-all focus:border-ios-blue focus:shadow-[0_0_0_3px_rgba(59,130,246,0.12)] placeholder:text-ios-text/40 dark:placeholder:text-gray-500"
          @keyup.enter="addWord"
        />
        <button class="px-4 py-3 sm:py-3.5 bg-ios-blue text-white font-bold rounded-xl text-sm transition-all md:hover:scale-[1.01] active:scale-[0.98] cursor-pointer dark:shadow-[0_0_12px_2px_rgba(130,180,255,0.2)]" @click="addWord">添加</button>
      </div>

      <div v-if="filterList.length === 0" class="py-6 text-center text-[11px] sm:text-xs text-ios-gray dark:text-gray-400">暂无弹幕屏蔽关键词，请上方输入添加</div>
      <div v-else class="flex flex-wrap gap-2">
        <div v-for="(word, idx) in filterList" :key="idx" class="flex items-center gap-3 px-3 py-2 bg-ios-bg dark:bg-ios-border/20 rounded-lg">
          <span class="text-sm text-ios-text-h dark:text-gray-100">{{ word }}</span>
          <button class="w-6 h-6 flex items-center justify-center rounded-full bg-red-100 dark:bg-red-900/50 text-red-500 dark:text-red-300 text-base cursor-pointer hover:opacity-80" @click="removeWord(idx)">×</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { api } from '@/services/api.js'
import { useToastStore } from '@/store/toast.js'

const toast = useToastStore()
const filterList = ref([])
const currentWord = ref('')

const loadFilter = async () => {
  const res = await api.getDanmakuFilter()
  if (res.isOk && Array.isArray(res.data)) {
    filterList.value = res.data
  } else {
    filterList.value = []
  }
}

onMounted(loadFilter)

const addWord = async () => {
  const val = currentWord.value.trim()
  if (!val) return
  if (filterList.value.includes(val)) {
    toast.show('该关键词已存在', 'error')
    return
  }
  const temp = [...filterList.value, val]
  const saveRes = await api.updateDanmakuFilter(temp.join('\n'))
  if (saveRes.isOk) {
    currentWord.value = ''
    await loadFilter()
    toast.show('添加成功', 'success')
  } else {
    toast.show('同步失败', 'error')
  }
}

const removeWord = async idx => {
  const temp = filterList.value.filter((_, i) => i !== idx)
  const saveRes = await api.updateDanmakuFilter(temp.join('\n'))
  if (saveRes.isOk) {
    await loadFilter()
    toast.show('删除成功', 'success')
  } else {
    toast.show('删除同步失败', 'error')
  }
}
</script>
