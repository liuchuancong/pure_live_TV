<template>
  <div class="p-4 text-left max-w-3xl mx-auto space-y-4">
    <div class="bg-ios-card dark:bg-ios-card rounded-2xl border border-ios-border/20 dark:border-ios-border/40 shadow-[0_8px_30px_var(--color-ios-shadow)] p-4 sm:p-5 space-y-3">
      <div>
        <span class="text-sm sm:text-[15px] font-bold text-ios-text-h dark:text-gray-100">网络代理</span>
        <p class="text-[11px] sm:text-xs text-ios-gray dark:text-gray-400 mt-1">与电视上「自定义网络代理」页面一致，保存立即生效</p>
      </div>

      <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
        <div>
          <label class="block text-[11px] sm:text-xs font-bold text-ios-text/80 mb-1">接口请求代理</label>
          <select v-model="form.enableProxy" class="w-full px-3 py-2.5 bg-ios-bg dark:bg-ios-bg border border-ios-border/10 rounded-xl text-sm text-ios-text-h outline-none focus:border-ios-blue">
            <option :value="false">关闭</option>
            <option :value="true">开启</option>
          </select>
        </div>
        <div>
          <label class="block text-[11px] sm:text-xs font-bold text-ios-text/80 mb-1">代理地址</label>
          <input v-model="form.proxyHost" placeholder="127.0.0.1" class="w-full px-3 py-2.5 bg-ios-bg dark:bg-ios-bg border border-ios-border/10 rounded-xl text-sm text-ios-text-h outline-none focus:border-ios-blue placeholder:text-ios-text/30" />
        </div>
        <div>
          <label class="block text-[11px] sm:text-xs font-bold text-ios-text/80 mb-1">端口</label>
          <input v-model="form.proxyPort" inputmode="numeric" placeholder="7897" class="w-full px-3 py-2.5 bg-ios-bg dark:bg-ios-bg border border-ios-border/10 rounded-xl text-sm text-ios-text-h outline-none focus:border-ios-blue placeholder:text-ios-text/30" />
        </div>
        <div>
          <label class="block text-[11px] sm:text-xs font-bold text-ios-text/80 mb-1">播放代理</label>
          <select v-model="form.enableAppProxy" class="w-full px-3 py-2.5 bg-ios-bg dark:bg-ios-bg border border-ios-border/10 rounded-xl text-sm text-ios-text-h outline-none focus:border-ios-blue">
            <option :value="false">关闭</option>
            <option :value="true">开启</option>
          </select>
        </div>
        <div>
          <label class="block text-[11px] sm:text-xs font-bold text-ios-text/80 mb-1">播放代理地址</label>
          <input v-model="form.appProxyHost" placeholder="127.0.0.1" class="w-full px-3 py-2.5 bg-ios-bg dark:bg-ios-bg border border-ios-border/10 rounded-xl text-sm text-ios-text-h outline-none focus:border-ios-blue placeholder:text-ios-text/30" />
        </div>
        <div>
          <label class="block text-[11px] sm:text-xs font-bold text-ios-text/80 mb-1">播放代理端口</label>
          <input v-model="form.appProxyPort" inputmode="numeric" placeholder="7897" class="w-full px-3 py-2.5 bg-ios-bg dark:bg-ios-bg border border-ios-border/10 rounded-xl text-sm text-ios-text-h outline-none focus:border-ios-blue placeholder:text-ios-text/30" />
        </div>
      </div>

      <button
        :disabled="loading"
        class="w-full py-3 bg-ios-blue text-white font-bold rounded-xl text-sm transition-all md:hover:scale-[1.01] active:scale-[0.98] disabled:opacity-40 cursor-pointer"
        @click="submit"
      >
        {{ loading ? '正在保存...' : '保存代理' }}
      </button>
    </div>
  </div>
</template>

<script setup>
import { reactive, ref, onMounted } from 'vue'
import { api } from '@/services/api.js'
import { useToastStore } from '@/store/toast.js'

const form = reactive({
  enableProxy: false,
  proxyHost: '',
  proxyPort: '',
  enableAppProxy: false,
  appProxyHost: '',
  appProxyPort: ''
})
const loading = ref(false)
const toast = useToastStore()

onMounted(async () => {
  const data = await api.getProxy()
  if (!data) return
  form.enableProxy = !!data.enableProxy
  form.proxyHost = data.proxyHost || ''
  form.proxyPort = data.proxyPort || ''
  form.enableAppProxy = !!data.enableAppProxy
  form.appProxyHost = data.appProxyHost || ''
  form.appProxyPort = data.appProxyPort || ''
})

async function submit() {
  loading.value = true
  const payload = {
    enableProxy: !!form.enableProxy,
    proxyHost: String(form.proxyHost || '').trim(),
    proxyPort: parseInt(form.proxyPort, 10) || 0,
    enableAppProxy: !!form.enableAppProxy,
    appProxyHost: String(form.appProxyHost || '').trim(),
    appProxyPort: parseInt(form.appProxyPort, 10) || 0
  }
  const res = await api.saveProxy(payload)
  toast.show(res.isOk ? '代理已保存到电视' : res.msg || '保存失败', res.isOk ? 'success' : 'error')
  loading.value = false
}
</script>
