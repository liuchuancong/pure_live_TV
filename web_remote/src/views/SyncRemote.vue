<template>
  <div class="p-4 text-left max-w-3xl mx-auto space-y-4">
    <div class="bg-ios-card dark:bg-ios-card rounded-2xl border border-ios-border/20 dark:border-ios-border/40 shadow-[0_8px_30px_var(--color-ios-shadow)] p-4 sm:p-5">
      <div class="mb-4">
        <span class="text-sm sm:text-[15px] font-bold text-ios-text-h dark:text-gray-100">导入备份数据</span>
        <p class="text-[11px] sm:text-xs text-ios-gray dark:text-gray-400 mt-1">选择本地备份文件，覆盖当前电视配置</p>
      </div>
      <input ref="fileUploadRef" type="file" accept=".json" class="hidden" @change="handleImport" />
      <button class="w-full py-3 sm:py-3.5 bg-ios-blue text-white font-bold rounded-xl text-sm transition-all md:hover:scale-[1.01] active:scale-[0.98] cursor-pointer dark:shadow-[0_0_24px_4px_rgba(130,180,255,0.25)]" @click="fileUploadRef?.click()">选择备份文件导入</button>
    </div>

    <div class="bg-ios-card dark:bg-ios-card rounded-2xl border border-ios-border/20 dark:border-ios-border/40 shadow-[0_8px_30px_var(--color-ios-shadow)] p-4 sm:p-5">
      <div class="mb-4">
        <span class="text-sm sm:text-[15px] font-bold text-ios-text-h dark:text-gray-100">导出备份数据</span>
        <p class="text-[11px] sm:text-xs text-ios-gray dark:text-gray-400 mt-1">一键下载当前全部配置备份到本地</p>
      </div>
      <button class="w-full py-3 sm:py-3.5 bg-ios-blue text-white font-bold rounded-xl text-sm transition-all md:hover:scale-[1.01] active:scale-[0.98] cursor-pointer dark:shadow-[0_0_24px_4px_rgba(130,180,255,0.25)]" @click="handleExport">导出并下载备份文件</button>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { api } from '@/services/api.js'
import { useToastStore } from '@/store/toast.js'

const toast = useToastStore()
const fileUploadRef = ref(null)

const handleExport = async () => {
  const res = await api.exportBackup()
  if (!res.isOk) {
    toast.show(res.msg || '导出失败', 'error')
    return
  }
  try {
    const data = res.data || res
    const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' })
    const url = URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = `tv-config-backup-${Date.now()}.json`
    document.body.appendChild(a)
    a.click()
    document.body.removeChild(a)
    URL.revokeObjectURL(url)
    toast.show('导出成功', 'success')
  } catch {
    toast.show('生成备份文件失败', 'error')
  }
}

const handleImport = async e => {
  const file = e.target.files[0]
  if (!file) return
  const reader = new FileReader()
  reader.onload = async ev => {
    try {
      const jsonData = JSON.parse(ev.target.result)
      const res = await api.importBackup(jsonData)
      if (res.isOk) {
        toast.show('数据导入成功，刷新页面生效', 'success')
      } else {
        toast.show(res.msg || '导入失败', 'error')
      }
    } catch {
      toast.show('备份文件格式错误', 'error')
    }
    fileUploadRef.value.value = ''
  }
  reader.readAsText(file)
}
</script>
