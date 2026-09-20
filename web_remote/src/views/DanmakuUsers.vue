<template>
  <div class="p-3 sm:p-4 lg:p-6 text-left max-w-3xl mx-auto">
    <div class="mb-3 px-1">
      <div class="text-[10px] sm:text-xs font-bold text-ios-text/80 uppercase tracking-wider">弹幕用户屏蔽</div>
    </div>

    <!-- add -->
    <div class="bg-ios-card rounded-2xl border border-ios-border/20 shadow-[0_8px_30px_var(--color-ios-shadow)] overflow-hidden mb-4 p-4 sm:p-5 space-y-3">
      <div class="text-sm font-bold text-ios-text-h">添加屏蔽用户</div>
      <div class="flex gap-2">
        <input
          v-model="currentUser"
          placeholder="输入用户名"
          class="flex-1 p-3 bg-ios-bg border border-ios-border/10 rounded-xl text-sm text-ios-text-h outline-none transition-all focus:border-ios-blue focus:shadow-[0_0_0_3px_rgba(59,130,246,0.12)] placeholder:text-ios-text/40"
          @keyup.enter="addUser"
        />
        <button class="px-5 py-3 bg-ios-blue text-white font-bold rounded-xl text-sm transition-all hover:scale-[1.01] active:scale-[0.98] cursor-pointer" @click="addUser">添加</button>
      </div>
    </div>

    <!-- edit -->
    <div v-if="editing" class="bg-ios-card rounded-2xl border border-ios-blue/40 shadow-[0_8px_30px_var(--color-ios-shadow)] overflow-hidden mb-4 p-4 sm:p-5 space-y-3">
      <div class="text-sm font-bold text-ios-text-h">编辑用户</div>
      <div class="flex gap-2">
        <input v-model="editingWord" placeholder="用户名" class="flex-1 p-3 bg-ios-bg border border-ios-border/10 rounded-xl text-sm text-ios-text-h outline-none transition-all focus:border-ios-blue focus:shadow-[0_0_0_3px_rgba(59,130,246,0.12)]" @keyup.enter="saveEditingUser" />
      </div>
      <div class="flex gap-2 justify-end">
        <button class="px-4 py-2.5 bg-ios-bg border border-ios-border/20 text-ios-text rounded-xl text-sm cursor-pointer" @click="cancelEditingUser">取消</button>
        <button class="px-5 py-2.5 bg-ios-blue text-white font-bold rounded-xl text-sm cursor-pointer" @click="saveEditingUser">保存</button>
      </div>
    </div>

    <!-- list -->
    <div class="bg-ios-card rounded-2xl border border-ios-border/20 shadow-[0_8px_30px_var(--color-ios-shadow)] overflow-hidden p-4 sm:p-5 space-y-2">
      <div v-if="userList.length === 0" class="py-6 text-center text-[11px] sm:text-xs text-ios-gray">暂无屏蔽用户，请在上方添加</div>
      <div v-for="(word, idx) in userList" :key="word + idx" class="flex items-center gap-3 p-3 bg-ios-bg border border-ios-border/10 rounded-xl">
        <div class="flex-1 min-w-0">
          <div class="text-sm font-semibold text-ios-text-h truncate">{{ word }}</div>
        </div>
        <button class="px-3 py-1.5 text-xs font-semibold text-ios-blue bg-ios-blue/10 rounded-lg cursor-pointer hover:bg-ios-blue/20 transition-colors" @click="startEditingUser(idx)">编辑</button>
        <button class="w-7 h-7 flex items-center justify-center rounded-full bg-red-100 text-red-500 text-base cursor-pointer hover:opacity-80" @click="removeUser(idx)">×</button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { api } from '@/services/api.js'
import { useToastStore } from '@/store/toast.js'

const toast = useToastStore()
const userList = ref([])
const currentUser = ref('')

const editing = ref(false)
const editingIndex = ref(-1)
const editingWord = ref('')

const loadUsers = async () => {
  const res = await api.getDanmakuUsers()
  if (res.isOk && Array.isArray(res.data)) {
    userList.value = res.data
  } else {
    userList.value = []
  }
}

onMounted(loadUsers)

const saveUsers = async list => {
  const res = await api.updateDanmakuUsers(list.join('\n'))
  await loadUsers()
  return res.isOk
}

const addUser = async () => {
  const val = currentUser.value.trim()
  if (!val) return
  if (userList.value.includes(val)) {
    toast.show('该用户已在屏蔽列表', 'error')
    return
  }
  const ok = await saveUsers([...userList.value, val])
  if (ok) {
    currentUser.value = ''
    toast.show('添加成功', 'success')
  } else {
    toast.show('同步失败', 'error')
  }
}

const startEditingUser = idx => {
  editingIndex.value = idx
  editingWord.value = userList.value[idx]
  editing.value = true
}

const cancelEditingUser = () => {
  editing.value = false
}

const saveEditingUser = async () => {
  const val = editingWord.value.trim()
  if (!val) {
    toast.show('用户名不能为空', 'error')
    return
  }
  const idx = editingIndex.value
  if (userList.value.some((w, i) => i !== idx && w === val)) {
    toast.show('该用户已在屏蔽列表', 'error')
    return
  }
  const next = [...userList.value]
  next[idx] = val
  const ok = await saveUsers(next)
  if (ok) {
    editing.value = false
    toast.show('保存成功', 'success')
  } else {
    toast.show('同步失败', 'error')
  }
}

const removeUser = async idx => {
  if (editingIndex.value === idx) editing.value = false
  const ok = await saveUsers(userList.value.filter((_, i) => i !== idx))
  if (ok) {
    toast.show('删除成功', 'success')
  } else {
    toast.show('删除同步失败', 'error')
  }
}
</script>
