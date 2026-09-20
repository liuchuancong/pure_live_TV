<template>
  <div class="p-3 sm:p-4 lg:p-6 text-left max-w-3xl mx-auto">
    <div class="mb-3 px-1">
      <div class="text-[10px] sm:text-xs font-bold text-ios-text/80 uppercase tracking-wider">标签管理</div>
    </div>

    <!-- add -->
    <div class="bg-ios-card rounded-2xl border border-ios-border/20 shadow-[0_8px_30px_var(--color-ios-shadow)] overflow-hidden mb-4 p-4 sm:p-5 space-y-3">
      <div class="text-sm font-bold text-ios-text-h">添加标签</div>
      <div class="flex flex-col sm:flex-row gap-2">
        <input
          v-model="newName"
          placeholder="标签名称（必填）"
          class="flex-1 p-3 bg-ios-bg border border-ios-border/10 rounded-xl text-sm text-ios-text-h outline-none transition-all focus:border-ios-blue focus:shadow-[0_0_0_3px_rgba(59,130,246,0.12)] placeholder:text-ios-text/40"
          @keyup.enter="addTag"
        />
        <input
          v-model="newDescription"
          placeholder="描述（可选）"
          class="flex-1 p-3 bg-ios-bg border border-ios-border/10 rounded-xl text-sm text-ios-text-h outline-none transition-all focus:border-ios-blue focus:shadow-[0_0_0_3px_rgba(59,130,246,0.12)] placeholder:text-ios-text/40"
          @keyup.enter="addTag"
        />
        <button
          class="px-5 py-3 bg-ios-blue text-white font-bold rounded-xl text-sm transition-all hover:scale-[1.01] active:scale-[0.98] cursor-pointer"
          @click="addTag"
        >
          添加
        </button>
      </div>
    </div>

    <!-- edit -->
    <div v-if="editing" class="bg-ios-card rounded-2xl border border-ios-blue/40 shadow-[0_8px_30px_var(--color-ios-shadow)] overflow-hidden mb-4 p-4 sm:p-5 space-y-3">
      <div class="text-sm font-bold text-ios-text-h">编辑标签</div>
      <div class="flex flex-col sm:flex-row gap-2">
        <input
          v-model="editingName"
          placeholder="标签名称"
          class="flex-1 p-3 bg-ios-bg border border-ios-border/10 rounded-xl text-sm text-ios-text-h outline-none transition-all focus:border-ios-blue focus:shadow-[0_0_0_3px_rgba(59,130,246,0.12)]"
          @keyup.enter="saveEditing"
        />
        <input
          v-model="editingDescription"
          placeholder="描述（可选）"
          class="flex-1 p-3 bg-ios-bg border border-ios-border/10 rounded-xl text-sm text-ios-text-h outline-none transition-all focus:border-ios-blue focus:shadow-[0_0_0_3px_rgba(59,130,246,0.12)]"
          @keyup.enter="saveEditing"
        />
      </div>
      <div class="flex gap-2 justify-end">
        <button class="px-4 py-2.5 bg-ios-bg border border-ios-border/20 text-ios-text rounded-xl text-sm cursor-pointer" @click="cancelEditing">取消</button>
        <button class="px-5 py-2.5 bg-ios-blue text-white font-bold rounded-xl text-sm cursor-pointer" @click="saveEditing">保存</button>
      </div>
    </div>

    <!-- list -->
    <div class="bg-ios-card rounded-2xl border border-ios-border/20 shadow-[0_8px_30px_var(--color-ios-shadow)] overflow-hidden p-4 sm:p-5 space-y-2">
      <div v-if="tags.length === 0" class="py-6 text-center text-[11px] sm:text-xs text-ios-gray">暂无标签，请在上方添加</div>
      <div
        v-for="tag in tags"
        :key="tag.id"
        class="flex items-center gap-3 p-3 bg-ios-bg border border-ios-border/10 rounded-xl"
      >
        <div class="flex-1 min-w-0">
          <div class="text-sm font-semibold text-ios-text-h truncate">{{ tag.name }}</div>
          <div v-if="tag.description" class="text-xs text-ios-text/60 truncate">{{ tag.description }}</div>
        </div>
        <button
          class="px-3 py-1.5 text-xs font-semibold text-ios-blue bg-ios-blue/10 rounded-lg cursor-pointer hover:bg-ios-blue/20 transition-colors"
          @click="startEditing(tag)"
        >
          编辑
        </button>
        <button
          class="w-7 h-7 flex items-center justify-center rounded-full bg-red-100 text-red-500 text-base cursor-pointer hover:opacity-80"
          @click="removeTag(tag)"
        >
          ×
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { api } from '@/services/api.js'
import { useToastStore } from '@/store/toast.js'

const toast = useToastStore()
const tags = ref([])
const newName = ref('')
const newDescription = ref('')

const editing = ref(false)
const editingId = ref('')
const editingName = ref('')
const editingDescription = ref('')

const loadTags = async () => {
  const res = await api.getTags()
  if (res.isOk && Array.isArray(res.data)) {
    tags.value = res.data
  } else {
    tags.value = []
  }
}

onMounted(loadTags)

const addTag = async () => {
  const name = newName.value.trim()
  if (!name) {
    toast.show('请输入标签名称', 'error')
    return
  }
  if (tags.value.some(t => t.name === name)) {
    toast.show('该标签已存在', 'error')
    return
  }
  const res = await api.tagAction({ action: 'add', name, description: newDescription.value.trim() })
  if (res.isOk) {
    newName.value = ''
    newDescription.value = ''
    await loadTags()
    toast.show('添加成功', 'success')
  } else {
    toast.show('同步失败', 'error')
  }
}

const startEditing = tag => {
  editingId.value = tag.id
  editingName.value = tag.name
  editingDescription.value = tag.description || ''
  editing.value = true
}

const cancelEditing = () => {
  editing.value = false
}

const saveEditing = async () => {
  const name = editingName.value.trim()
  if (!name) {
    toast.show('标签名称不能为空', 'error')
    return
  }
  const res = await api.tagAction({
    action: 'update',
    id: editingId.value,
    name,
    description: editingDescription.value.trim()
  })
  if (res.isOk) {
    editing.value = false
    await loadTags()
    toast.show('保存成功', 'success')
  } else {
    toast.show('同步失败', 'error')
  }
}

const removeTag = async tag => {
  const res = await api.tagAction({ action: 'delete', id: tag.id })
  if (res.isOk) {
    if (editingId.value === tag.id) editing.value = false
    await loadTags()
    toast.show('删除成功', 'success')
  } else {
    toast.show('删除同步失败', 'error')
  }
}
</script>
