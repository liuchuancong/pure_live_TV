<template>
  <div class="p-3 sm:p-4 lg:p-6 text-left max-w-3xl mx-auto">
    <div class="mb-3 px-1">
      <div class="text-[10px] sm:text-xs font-bold text-ios-text/80 uppercase tracking-wider">弹幕关键词过滤</div>
    </div>

    <!-- add -->
    <div class="bg-ios-card rounded-2xl border border-ios-border/20 shadow-[0_8px_30px_var(--color-ios-shadow)] overflow-hidden mb-4 p-4 sm:p-5 space-y-3">
      <div class="text-sm font-bold text-ios-text-h">添加屏蔽关键词</div>
      <div class="flex gap-2">
        <input
          v-model="currentWord"
          placeholder="输入屏蔽关键词"
          class="flex-1 p-3 bg-ios-bg border border-ios-border/10 rounded-xl text-sm text-ios-text-h outline-none transition-all focus:border-ios-blue focus:shadow-[0_0_0_3px_rgba(59,130,246,0.12)] placeholder:text-ios-text/40"
          @keyup.enter="addWord"
        />
        <button class="px-5 py-3 bg-ios-blue text-white font-bold rounded-xl text-sm transition-all hover:scale-[1.01] active:scale-[0.98] cursor-pointer" @click="addWord">添加</button>
      </div>
    </div>

    <!-- edit -->
    <div v-if="editing" class="bg-ios-card rounded-2xl border border-ios-blue/40 shadow-[0_8px_30px_var(--color-ios-shadow)] overflow-hidden mb-4 p-4 sm:p-5 space-y-3">
      <div class="text-sm font-bold text-ios-text-h">编辑关键词</div>
      <div class="flex gap-2">
        <input v-model="editingWord" placeholder="关键词" class="flex-1 p-3 bg-ios-bg border border-ios-border/10 rounded-xl text-sm text-ios-text-h outline-none transition-all focus:border-ios-blue focus:shadow-[0_0_0_3px_rgba(59,130,246,0.12)]" @keyup.enter="saveEditing" />
      </div>
      <div class="flex gap-2 justify-end">
        <button class="px-4 py-2.5 bg-ios-bg border border-ios-border/20 text-ios-text rounded-xl text-sm cursor-pointer" @click="cancelEditing">取消</button>
        <button class="px-5 py-2.5 bg-ios-blue text-white font-bold rounded-xl text-sm cursor-pointer" @click="saveEditing">保存</button>
      </div>
    </div>

    <!-- list -->
    <div class="bg-ios-card rounded-2xl border border-ios-border/20 shadow-[0_8px_30px_var(--color-ios-shadow)] overflow-hidden p-4 sm:p-5 space-y-2">
      <div v-if="filterList.length === 0" class="py-6 text-center text-[11px] sm:text-xs text-ios-gray">暂无屏蔽关键词，请在上方添加</div>
      <div v-for="(word, idx) in filterList" :key="word + idx" class="flex items-center gap-3 p-3 bg-ios-bg border border-ios-border/10 rounded-xl">
        <div class="flex-1 min-w-0">
          <div class="text-sm font-semibold text-ios-text-h truncate">{{ word }}</div>
        </div>
        <button class="px-3 py-1.5 text-xs font-semibold text-ios-blue bg-ios-blue/10 rounded-lg cursor-pointer hover:bg-ios-blue/20 transition-colors" @click="startEditing(idx)">编辑</button>
        <button class="w-7 h-7 flex items-center justify-center rounded-full bg-red-100 text-red-500 text-base cursor-pointer hover:opacity-80" @click="removeWord(idx)">×</button>
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

const editing = ref(false)
const editingIndex = ref(-1)
const editingWord = ref('')

const loadFilter = async () => {
  const res = await api.getDanmakuFilter()
  if (res.isOk && Array.isArray(res.data)) {
    filterList.value = res.data
  } else {
    filterList.value = []
  }
}

onMounted(loadFilter)

const saveList = async list => {
  const res = await api.updateDanmakuFilter(list.join('\n'))
  await loadFilter()
  return res.isOk
}

const addWord = async () => {
  const val = currentWord.value.trim()
  if (!val) return
  if (filterList.value.includes(val)) {
    toast.show('该关键词已存在', 'error')
    return
  }
  const ok = await saveList([...filterList.value, val])
  if (ok) {
    currentWord.value = ''
    toast.show('添加成功', 'success')
  } else {
    toast.show('同步失败', 'error')
  }
}

const startEditing = idx => {
  editingIndex.value = idx
  editingWord.value = filterList.value[idx]
  editing.value = true
}

const cancelEditing = () => {
  editing.value = false
}

const saveEditing = async () => {
  const val = editingWord.value.trim()
  if (!val) {
    toast.show('关键词不能为空', 'error')
    return
  }
  const idx = editingIndex.value
  if (filterList.value.some((w, i) => i !== idx && w === val)) {
    toast.show('该关键词已存在', 'error')
    return
  }
  const next = [...filterList.value]
  next[idx] = val
  const ok = await saveList(next)
  if (ok) {
    editing.value = false
    toast.show('保存成功', 'success')
  } else {
    toast.show('同步失败', 'error')
  }
}

const removeWord = async idx => {
  if (editingIndex.value === idx) editing.value = false
  const ok = await saveList(filterList.value.filter((_, i) => i !== idx))
  if (ok) {
    toast.show('删除成功', 'success')
  } else {
    toast.show('删除同步失败', 'error')
  }
}
</script>
