<template>
  <div class="p-3 sm:p-4 lg:p-6 text-left max-w-3xl mx-auto">
    <div class="mb-3 px-1">
      <div class="text-[10px] sm:text-xs font-bold text-ios-text/80 uppercase tracking-wider">WebDAV 存储列表</div>
    </div>
    <div class="bg-ios-card dark:bg-ios-card rounded-2xl border border-ios-border/20 dark:border-ios-border/40 shadow-[0_8px_30px_var(--color-ios-shadow)] overflow-hidden mb-4">
      <div v-if="davList.length === 0" class="p-6 text-center text-[11px] sm:text-xs text-ios-gray dark:text-ios-gray">暂无 WebDAV 配置，点击下方按钮新增</div>
      <div v-else class="divide-y divide-ios-border/60 dark:divide-ios-border/40">
        <div v-for="(item, idx) in davList" :key="idx" class="p-3.5 sm:p-4 flex items-center justify-between group hover:bg-ios-bg/60 dark:hover:bg-ios-border/10 transition-all">
          <div class="flex flex-col gap-1">
            <span class="text-sm sm:text-[15px] font-bold text-ios-text-h dark:text-ios-text-h">{{ item.name || '未命名' }}</span>
            <span class="text-[10px] sm:text-xs text-ios-gray dark:text-ios-gray truncate max-w-[320px]">{{ item.address }}</span>
          </div>
          <div class="flex items-center gap-3">
            <button class="text-xs font-semibold text-ios-blue cursor-pointer active:opacity-60 transition-opacity" @click="openEdit(idx)">编辑</button>
            <button class="text-xs font-semibold text-red-500 cursor-pointer active:opacity-60 transition-opacity" @click="deleteItem(idx)">删除</button>
          </div>
        </div>
      </div>
    </div>

    <button class="w-full py-3 sm:py-3.5 bg-ios-blue text-white font-bold rounded-2xl text-sm sm:text-[15px] transition-all md:hover:scale-[1.01] active:scale-[0.98] cursor-pointer shadow-[0_8px_20px_rgba(0,122,255,0.25)] dark:shadow-[0_0_24px_4px_rgba(130,180,255,0.25)]" @click="openAdd">
      新增 WebDAV 配置
    </button>

    <div v-if="showModal" class="fixed inset-0 bg-black/40 dark:bg-black/70 backdrop-blur-sm flex items-center justify-center z-50 p-4 transition-all">
      <div class="w-full max-w-lg bg-ios-card dark:bg-neutral-900 rounded-2xl border border-ios-border/20 dark:border-blue-600 dark:shadow-[0_0_25px_5px_rgba(37,99,235,0.6),0_0_50px_15px_rgba(37,99,235,0.3)] shadow-[0_8px_30px_var(--color-ios-shadow)] p-4 sm:p-5 space-y-4">
        <div class="flex items-center justify-between">
          <span class="text-sm sm:text-[15px] font-bold text-ios-text-h dark:text-white">
            {{ editIndex > -1 ? '编辑配置' : '新增配置' }}
          </span>
          <button class="cursor-pointer transition-colors" @click="closeModal">
            <XIcon class="w-4 h-4 text-ios-gray dark:text-white hover:dark:text-sky-200" />
          </button>
        </div>

        <div class="space-y-3 sm:space-y-4">
          <div>
            <label class="block text-[12px] sm:text-[13px] font-bold text-ios-text-h dark:text-gray-300 mb-1.5">名称</label>
            <input
              v-model="form.name"
              type="text"
              placeholder="自定义存储名称"
              class="w-full p-3 sm:p-3.5 bg-ios-bg dark:bg-black/40 border border-ios-border/10 dark:border-white/10 rounded-xl text-sm sm:text-[15px] text-ios-text-h dark:text-white outline-none transition-all focus:border-ios-blue dark:focus:border-blue-500 focus:shadow-[0_0_0_3px_rgba(59,130,246,0.12)] placeholder:text-ios-text/40 dark:placeholder:text-white/30"
            />
          </div>

          <div>
            <label class="block text-[12px] sm:text-[13px] font-bold text-ios-text-h dark:text-gray-300 mb-1.5">服务地址 Address</label>
            <input
              v-model="form.address"
              type="text"
              placeholder="https://xxx.com"
              class="w-full p-3 sm:p-3.5 bg-ios-bg dark:bg-black/40 border border-ios-border/10 dark:border-white/10 rounded-xl text-sm sm:text-[15px] text-ios-text-h dark:text-white outline-none transition-all focus:border-ios-blue dark:focus:border-blue-500 focus:shadow-[0_0_0_3px_rgba(59,130,246,0.12)] placeholder:text-ios-text/40 dark:placeholder:text-white/30"
            />
          </div>

          <div>
            <label class="block text-[12px] sm:text-[13px] font-bold text-ios-text-h dark:text-gray-300 mb-1.5">用户名 Username</label>
            <input
              v-model="form.username"
              type="text"
              placeholder="账号"
              class="w-full p-3 sm:p-3.5 bg-ios-bg dark:bg-black/40 border border-ios-border/10 dark:border-white/10 rounded-xl text-sm sm:text-[15px] text-ios-text-h dark:text-white outline-none transition-all focus:border-ios-blue dark:focus:border-blue-500 focus:shadow-[0_0_0_3px_rgba(59,130,246,0.12)] placeholder:text-ios-text/40 dark:placeholder:text-white/30"
            />
          </div>

          <div>
            <label class="block text-[12px] sm:text-[13px] font-bold text-ios-text-h dark:text-gray-300 mb-1.5">密码 Password</label>
            <div class="relative">
              <input
                v-model="form.password"
                :type="showPwd ? 'text' : 'password'"
                placeholder="密码"
                class="w-full p-3 sm:p-3.5 pr-16 bg-ios-bg dark:bg-black/40 border border-ios-border/10 dark:border-white/10 rounded-xl text-sm sm:text-[15px] text-ios-text-h dark:text-white outline-none transition-all focus:border-ios-blue dark:focus:border-blue-500 focus:shadow-[0_0_0_3px_rgba(59,130,246,0.12)] placeholder:text-ios-text/40 dark:placeholder:text-white/30"
              />
              <button class="absolute right-3 top-1/2 -translate-y-1/2 text-ios-blue cursor-pointer active:opacity-60 transition-opacity" @click="showPwd = !showPwd">
                <EyeIcon v-if="!showPwd" class="w-4 h-4" />
                <EyeOffIcon v-if="showPwd" class="w-4 h-4" />
              </button>
            </div>
          </div>
        </div>

        <button
          class="w-full py-3 sm:py-3.5 bg-ios-blue dark:bg-blue-600 text-white font-bold rounded-2xl text-sm sm:text-[15px] transition-all md:hover:scale-[1.01] active:scale-[0.98] cursor-pointer shadow-[0_8px_20px_rgba(0,122,255,0.25)] dark:shadow-[0_0_20px_rgba(37,99,235,0.5)]"
          @click="saveConfig"
        >
          保存配置
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { api } from '@/services/api.js'
import { useToastStore } from '@/store/toast.js'
import { X, Eye, EyeOff } from 'lucide-vue-next'
const XIcon = X
const EyeIcon = Eye
const EyeOffIcon = EyeOff
const toast = useToastStore()
const davList = ref([])
const showModal = ref(false)
const editIndex = ref(-1)
const showPwd = ref(true)
const form = reactive({
  name: '',
  address: '',
  username: '',
  password: ''
})

const loadList = async () => {
  const res = await api.getWebDAVList()
  if (res.isOk && Array.isArray(res.data)) {
    davList.value = res.data
  } else {
    davList.value = []
  }
}

onMounted(loadList)

const closeModal = () => {
  showModal.value = false
  editIndex.value = -1
  showPwd.value = false
  form.name = ''
  form.address = ''
  form.username = ''
  form.password = ''
}

const openAdd = () => {
  closeModal()
  showModal.value = true
}

const openEdit = idx => {
  const item = davList.value[idx]
  if (!item) return
  editIndex.value = idx
  form.name = item.name ?? ''
  form.address = item.address ?? ''
  form.username = item.username ?? ''
  form.password = item.password ?? ''
  showModal.value = true
}

const deleteItem = async idx => {
  davList.value.splice(idx, 1)
  const saveRes = await api.saveWebDAVList(davList.value)
  if (saveRes.isOk) {
    toast.show('已删除该配置', 'success')
    await loadList()
  }
}

const saveConfig = async () => {
  if (!form.address.trim()) {
    toast.show('服务地址不能为空', 'error')
    return
  }
  if (editIndex.value > -1) {
    davList.value[editIndex.value] = { ...form }
  } else {
    davList.value.push({ ...form })
  }
  const saveRes = await api.saveWebDAVList(davList.value)
  if (saveRes.isOk) {
    toast.show('WebDAV 配置保存成功', 'success')
    closeModal()
    await loadList()
  } else {
    toast.show(saveRes.msg || '保存失败', 'error')
  }
}
</script>
