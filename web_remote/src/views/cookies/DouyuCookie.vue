<template>
  <div class="p-3 sm:p-4 space-y-4 sm:space-y-5 text-left">
    <!-- 登录态 -->
    <div class="p-3 sm:p-4 bg-ios-card dark:bg-ios-card border border-ios-border/20 dark:border-ios-border/30 rounded-2xl shadow-[0_8px_30px_var(--color-ios-shadow)] space-y-2">
      <div class="flex items-center gap-2 px-0.5">
        <span class="w-2 h-2 rounded-full shrink-0" :class="stateDotClass"></span>
        <span class="text-[12px] sm:text-[13px] font-bold text-ios-text-h dark:text-ios-text-h tracking-wide opacity-80">{{ stateTitle }}</span>
      </div>
      <p class="px-0.5 text-[11px] sm:text-xs text-ios-gray dark:text-ios-gray font-medium leading-relaxed">{{ stateDetail }}</p>
    </div>

    <!-- 页面 Cookie -->
    <div class="p-3 sm:p-4 bg-ios-card dark:bg-ios-card border border-ios-border/20 dark:border-ios-border/30 rounded-2xl shadow-[0_8px_30px_var(--color-ios-shadow)] space-y-3 sm:space-y-4">
      <div class="flex items-center justify-between px-0.5">
        <label class="text-[12px] sm:text-[13px] font-bold text-ios-text-h dark:text-ios-text-h tracking-wide opacity-80">页面 Cookie（含 dy_auth）</label>
        <button v-if="cookieData.trim()" class="text-xs font-semibold text-ios-blue cursor-pointer active:opacity-60 transition-opacity" @click="clearCookieField">一键清空</button>
      </div>
      <textarea
        v-model="cookieData"
        placeholder="F12 打开任意斗鱼页面请求，复制完整 Cookie..."
        class="w-full h-32 sm:h-36 p-3 sm:p-3.5 bg-ios-bg dark:bg-ios-bg border border-ios-border/10 dark:border-ios-border/20 rounded-xl text-sm sm:text-[15px] font-medium text-ios-text-h dark:text-ios-text-h outline-none resize-none transition-all focus:border-ios-blue focus:shadow-[0_0_0_3px_rgba(59,130,246,0.12)] placeholder:text-ios-text/40 shadow-inner"
        @input="handleCookieInput"
      ></textarea>
      <div class="flex items-center justify-between px-0.5 text-[10px] sm:text-[11px] text-ios-gray dark:text-ios-gray font-medium">
        <div class="flex items-center gap-2">
          <span>实时同步模式</span>
          <button class="relative w-9 h-5 rounded-full transition-colors duration-200" :class="autoSync ? 'bg-ios-blue' : 'bg-ios-border/40 dark:bg-ios-border/60'" @click="autoSync = !autoSync">
            <span class="absolute top-0.5 left-0.5 w-4 h-4 rounded-full shadow transition-transform duration-200" :class="autoSync ? 'translate-x-5 bg-white' : 'translate-x-0.5 bg-ios-card dark:bg-ios-bg'"></span>
          </button>
        </div>
        <span class="font-mono">已输入 {{ cookieData.length }} 字</span>
      </div>
    </div>

    <!-- 续期凭据 -->
    <div class="p-3 sm:p-4 bg-ios-card dark:bg-ios-card border border-ios-border/20 dark:border-ios-border/30 rounded-2xl shadow-[0_8px_30px_var(--color-ios-shadow)] space-y-3 sm:space-y-4">
      <div class="flex items-center justify-between px-0.5">
        <label class="text-[12px] sm:text-[13px] font-bold text-ios-text-h dark:text-ios-text-h tracking-wide opacity-80">续期凭据（passport.douyu.com 请求，可选）</label>
        <button v-if="ltp0.trim() || did.trim()" class="text-xs font-semibold text-ios-blue cursor-pointer active:opacity-60 transition-opacity" @click="clearCredentials">一键清空</button>
      </div>
      <div class="space-y-2.5">
        <div class="space-y-1.5">
          <label class="px-0.5 text-[10px] sm:text-[11px] font-semibold text-ios-text-h dark:text-ios-text-h opacity-70">LTP0（长期密钥）</label>
          <input
            v-model="ltp0"
            type="text"
            autocapitalize="off"
            autocomplete="off"
            spellcheck="false"
            placeholder="passport 请求 Cookie 里的 LTP0"
            class="w-full px-3.5 py-3.5 bg-ios-bg dark:bg-ios-bg border border-ios-border/10 dark:border-ios-border/20 rounded-xl text-[15px] font-medium text-ios-text-h dark:text-ios-text-h outline-none transition-all focus:border-ios-blue focus:shadow-[0_0_0_3px_rgba(59,130,246,0.12)] placeholder:text-ios-text/40 shadow-inner"
            @input="handleFieldInput"
          />
        </div>
        <div class="space-y-1.5">
          <label class="px-0.5 text-[10px] sm:text-[11px] font-semibold text-ios-text-h dark:text-ios-text-h opacity-70">dy_did（登录所属设备）</label>
          <input
            v-model="did"
            type="text"
            autocapitalize="off"
            autocomplete="off"
            spellcheck="false"
            placeholder="同一个请求 Cookie 里的 dy_did（32 位十六进制）"
            class="w-full px-3.5 py-3.5 bg-ios-bg dark:bg-ios-bg border border-ios-border/10 dark:border-ios-border/20 rounded-xl text-[15px] font-medium text-ios-text-h dark:text-ios-text-h outline-none transition-all focus:border-ios-blue focus:shadow-[0_0_0_3px_rgba(59,130,246,0.12)] placeholder:text-ios-text/40 shadow-inner"
            @input="handleFieldInput"
          />
        </div>
      </div>
      <p class="px-0.5 text-[10px] sm:text-[11px] text-ios-gray dark:text-ios-gray font-medium leading-relaxed">页面 Cookie 有 7 天时效。</p>
    </div>

    <!-- 操作按钮 -->
    <div class="space-y-3">
      <div class="flex gap-3">
        <button
          :disabled="loading || !cookieData.trim()"
          class="flex-1 py-3 sm:py-3.5 bg-ios-blue text-white font-bold rounded-2xl text-sm sm:text-[15px] transition-all md:hover:scale-[1.01] active:scale-[0.98] disabled:opacity-40 disabled:cursor-not-allowed cursor-pointer shadow-[0_8px_20px_rgba(0,122,255,0.25)] dark:shadow-[0_8px_20px_rgba(59,130,246,0.3)]"
          @click="submitCookie"
        >
          {{ loading ? '正在同步...' : '立即同步' }}
        </button>
        <button
          :disabled="renewing || !cookieData.trim()"
          class="flex-1 py-3 sm:py-3.5 bg-ios-blue/10 text-ios-blue font-bold rounded-2xl text-sm sm:text-[15px] transition-all md:hover:scale-[1.01] active:scale-[0.98] disabled:opacity-40 disabled:cursor-not-allowed cursor-pointer"
          @click="renewNow"
        >
          {{ renewing ? '正在续期...' : '立即续期' }}
        </button>
      </div>
      <button class="w-full py-3 sm:py-3.5 bg-zinc-500/10 text-red-500 font-bold rounded-2xl text-sm sm:text-[15px] transition-all md:hover:scale-[1.01] active:scale-[0.98] cursor-pointer" @click="submitClear">清除电视上的 Cookie（保留 LTP0 / dy_did）</button>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { api } from '@/services/api.js'
import { useToastStore } from '@/store/toast.js'

const cookieData = ref('')
const ltp0 = ref('')
const did = ref('')
const state = ref('none')
const renewable = ref(false)
const expiry = ref('')
const loading = ref(false)
const renewing = ref(false)
const autoSync = ref(true)
const toast = useToastStore()
let syncTimer = null

onMounted(loadSession)

/// Reads the whole session back from the TV: the page cookie plus the pair the
/// passport request carries.
async function loadSession() {
  const data = await api.getDouyuCookie()
  cookieData.value = data.cookie || ''
  ltp0.value = data.ltp0 || ''
  did.value = data.did || ''
  applyState(data)
}

/// Adopts the session the TV reports, fields included.
///
/// The credential pair lives in the TV's store, not in this page: reading it
/// back is what makes the two boxes show the session actually in effect
/// instead of whatever was typed here last (and an empty box then means the TV
/// really has nothing).
function applyState(data) {
  state.value = data.state || 'none'
  renewable.value = data.renewable === true
  expiry.value = data.expiry || ''
  if (typeof data.cookie === 'string' && data.cookie !== cookieData.value) cookieData.value = data.cookie
  if (typeof data.ltp0 === 'string' && data.ltp0 !== ltp0.value) ltp0.value = data.ltp0
  if (typeof data.did === 'string' && data.did !== did.value) did.value = data.did
}

const stateTitle = computed(() => {
  switch (state.value) {
    case 'valid':
      return '登录态有效'
    case 'expiredRefreshable':
      return '登录态已过期（可自动续期）'
    case 'expired':
      return '登录态已过期'
    case 'guest':
      return '已是游客身份'
    default:
      return '尚未配置 Cookie'
  }
})

const stateDetail = computed(() => {
  const at = formatExpiry(expiry.value)
  switch (state.value) {
    case 'valid':
      if (!at) return 'Cookie 里没有可读取的到期时间；如需自动续期请补上 LTP0。'
      return renewable.value ? `预计 ${at} 到期；已配置 LTP0，到期前会自动续期。` : `预计 ${at} 到期；未配置 LTP0，到期后需要重新粘贴。`
    case 'expiredRefreshable':
      return `已于 ${at} 过期；已配置 LTP0，下次播放会自动续期。`
    case 'expired':
      return `已于 ${at} 过期，且没有 LTP0，需要重新获取 Cookie。`
    case 'guest':
      return 'Cookie 里没有 dy_auth / acf_jwt_token，高清与超清不可用。'
    default:
      return '粘贴斗鱼页面 Cookie（含 dy_auth）后即可用于播放。'
  }
})

const stateDotClass = computed(() => {
  if (state.value === 'valid') return 'bg-emerald-500'
  if (state.value === 'expiredRefreshable') return 'bg-amber-500'
  if (state.value === 'expired' || state.value === 'guest') return 'bg-red-500'
  return 'bg-ios-border/60'
})

/// Sends the session, letting the TV apply the same rules the TV page does.
///
/// The renewal pair is only sent when it has something to say: an empty field
/// means "this page has nothing to contribute", not "erase what the TV holds" —
/// pasting a page cookie while the pair sits empty used to wipe the stored one.
/// Clearing is therefore explicit, through [clearCredentials].
async function syncSession({ clearCredentials: clearingCredentials = false } = {}) {
  const payload = { cookie: cookieData.value.trim() }
  if (clearingCredentials) {
    payload.ltp0 = ''
    payload.did = ''
  } else {
    if (ltp0.value.trim()) payload.ltp0 = ltp0.value.trim()
    if (did.value.trim()) payload.did = did.value.trim()
  }
  const res = await api.updateDouyuCookie(payload)
  if (res.isOk && res.data) applyState(res.data)
  return res
}

/// One field of a `a=b; c=d` cookie string, or null. Mirrors the TV's own rule,
/// including a pasted `Cookie: a=b; c=d` header line.
function cookieField(cookie, name) {
  const header = cookie.replace(/^\s*Cookie:\s*/i, '')
  const wanted = name.toLowerCase()
  for (const piece of header.split(';')) {
    const separator = piece.indexOf('=')
    if (separator <= 0) continue
    if (piece.slice(0, separator).trim().toLowerCase() !== wanted) continue
    const value = piece.slice(separator + 1).trim()
    if (value) return value
  }
  return null
}

/// Copies `LTP0` / `dy_did` out of whatever was pasted into the page-cookie box,
/// so a passport cookie only needs one paste instead of a manual split. Fills
/// what it finds and never clears a field, exactly like the TV's page.
function absorbCredentials() {
  const text = cookieData.value
  if (!text.trim()) return
  const token = cookieField(text, 'LTP0')
  if (token && token !== ltp0.value) ltp0.value = token
  const device = cookieField(text, 'dy_did')
  if (device && device !== did.value) did.value = device
}

function handleCookieInput() {
  absorbCredentials()
  handleFieldInput()
}

function handleFieldInput() {
  if (!autoSync.value) return
  if (syncTimer) clearTimeout(syncTimer)
  syncTimer = setTimeout(syncSession, 400)
}

function clearCookieField() {
  cookieData.value = ''
  if (autoSync.value) syncSession()
}

function clearCredentials() {
  ltp0.value = ''
  did.value = ''
  if (autoSync.value) syncSession({ clearCredentials: true })
}

async function submitCookie() {
  loading.value = true
  const res = await syncSession()
  toast.show(res.isOk ? '斗鱼 Cookie 已同步至电视端' : res.msg || '同步失败，请重试', res.isOk ? 'success' : 'error')
  loading.value = false
}

/// Renews now, so the pasted LTP0 / dy_did can be checked without waiting for
/// the seven-day window to prove them.
async function renewNow() {
  renewing.value = true
  const res = await api.refreshDouyuCookie({
    cookie: cookieData.value.trim(),
    ltp0: ltp0.value.trim(),
    did: did.value.trim()
  })
  if (res.data) {
    cookieData.value = res.data.cookie || cookieData.value
    applyState(res.data)
  }
  // A renewal that changed nothing still answers 200 with a reason, so the
  // server says whether anything was actually renewed.
  const renewed = res.isOk && res.data && res.data.renewed === true
  toast.show(res.msg || (renewed ? '续期完成' : '续期失败，请重试'), renewed ? 'success' : 'error')
  renewing.value = false
}

async function submitClear() {
  if (!window.confirm('清除电视上的斗鱼 Cookie？LTP0 与 dy_did 会保留。')) return
  cookieData.value = ''
  // An empty cookie on its own is not a session, and the TV keeps a stored login
  // rather than reading that as a wipe — so the clear has to say so.
  const res = await api.updateDouyuCookie({
    cookie: '',
    clear: true,
    ...(ltp0.value.trim() ? { ltp0: ltp0.value.trim() } : {}),
    ...(did.value.trim() ? { did: did.value.trim() } : {})
  })
  if (res.isOk && res.data) applyState(res.data)
  toast.show(res.isOk ? '已清除' : res.msg || '清除失败', res.isOk ? 'success' : 'error')
}

/// The web `dy_auth` is opaque, so its end comes from the TV's recorded save
/// time plus Douyu's seven-day rule; the TV sends it as local ISO time.
function formatExpiry(value) {
  if (!value) return ''
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return ''
  const two = number => String(number).padStart(2, '0')
  return `${date.getFullYear()}-${two(date.getMonth() + 1)}-${two(date.getDate())} ${two(date.getHours())}:${two(date.getMinutes())}`
}
</script>
