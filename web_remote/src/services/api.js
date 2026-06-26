import axios from 'axios'
import { useToastStore } from '@/store/toast.js'

const BASE_URL = ''
const TIMEOUT = 8000
const TEXT_CONTENT_TYPE = 'text/plain; charset=utf-8'
const JSON_CONTENT_TYPE = 'application/json; charset=utf-8'
const FILE_RESPONSE_TYPE = 'blob'

const request = axios.create({
  baseURL: BASE_URL,
  timeout: TIMEOUT
})

const handleErrorTip = msg => {
  const toast = useToastStore()
  toast.show(msg, 'error')
}

function getPureLiveFileName(prefix) {
  const now = new Date()
  const yyyy = now.getFullYear()
  const mm = String(now.getMonth() + 1).padStart(2, '0')
  const dd = String(now.getDate()).padStart(2, '0')
  const HH = String(now.getHours()).padStart(2, '0')
  const nn = String(now.getMinutes()).padStart(2, '0')
  const ss = String(now.getSeconds()).padStart(2, '0')
  return `${prefix}_${yyyy}-${mm}-${dd}T${HH}_${nn}_${ss}.txt`
}

request.interceptors.response.use(
  response => {
    const raw = response.data
    if (response.config.responseType === 'blob') {
      if (response.status < 200 || response.status >= 300) {
        return {
          isOk: false,
          code: response.status,
          msg: `接口请求失败，HTTP ${response.status}`,
          data: null
        }
      }
      const contentType = response.headers['content-type'] || ''
      if (contentType.includes('text/html')) {
        return {
          isOk: false,
          code: response.status,
          msg: '接口不存在，服务返回页面',
          data: null
        }
      }
      const fileName = response.config.downloadTag ? getPureLiveFileName(response.config.downloadTag) : getPureLiveFileName('purelive')
      const link = document.createElement('a')
      link.href = URL.createObjectURL(raw)
      link.download = fileName
      document.body.appendChild(link)
      link.click()
      document.body.removeChild(link)
      URL.revokeObjectURL(link.href)
      return {
        isOk: true,
        code: response.status,
        msg: '下载完成',
        data: raw
      }
    }
    if (typeof raw === 'string' && (raw.includes('<!doctype html>') || raw.includes('<html>'))) {
      return {
        isOk: false,
        code: -1,
        msg: '接口不存在，后端未开发',
        data: null
      }
    }
    const { code, msg, data } = raw
    return {
      isOk: code === 200,
      code,
      msg,
      data
    }
  },
  error => {
    return {
      isOk: false,
      code: error.response?.status ?? -99,
      msg: '网络请求失败',
      data: null
    }
  }
)

async function baseRequest(promise) {
  try {
    return await promise
  } catch (err) {
    let msg = '网络请求异常，请检查局域网连接'
    if (err.response) {
      msg = `同步失败: HTTP ${err.response.status}`
    }
    handleErrorTip(msg)
    return {
      isOk: false,
      code: -999,
      msg,
      data: null
    }
  }
}

export function httpGet(url, params = {}, config = {}) {
  return baseRequest(request.get(url, { params, ...config }))
}

export function httpPostText(url, body, config = {}) {
  return baseRequest(
    request.post(url, body, {
      headers: { 'Content-Type': TEXT_CONTENT_TYPE },
      ...config
    })
  )
}

export function httpPostJson(url, body, config = {}) {
  return baseRequest(
    request.post(url, body, {
      headers: { 'Content-Type': JSON_CONTENT_TYPE },
      ...config
    })
  )
}

export const api = {
  sendMovie(urlText) {
    return httpPostText('/api/movie', urlText)
  },
  async getCookie(site) {
    const res = await httpGet('/api/cookie', { site })
    return res.isOk ? (res.data ?? '') : ''
  },
  updateCookie(site, cookieData) {
    return httpPostJson('/api/cookie', { site, data: cookieData })
  },
  async getDouyinCookie() {
    const res = await httpGet('/api/cookie/douyin')
    return res.isOk ? (res.data ?? { ttwid: '', cookie: '' }) : { ttwid: '', cookie: '' }
  },
  updateDouyinCookie(ttwid, cookieData) {
    return httpPostJson('/api/cookie/douyin', { ttwid, cookie: cookieData })
  },
  getWebDAVList() {
    return httpGet('/api/webdav/list')
  },
  saveWebDAVList(list) {
    return httpPostJson('/api/webdav/save', list)
  },
  exportBackup() {
    return httpGet('/api/backup/export', {}, { responseType: FILE_RESPONSE_TYPE, downloadTag: 'pure_live_backup' })
  },
  importBackup(backupData) {
    return httpPostJson('/api/backup/import', backupData)
  },
  async fetchLogs() {
    const res = await httpGet('/api/log/stream')
    return res.isOk ? (res.data ?? []) : []
  },
  downloadLogs() {
    return httpGet('/api/log/download', {}, { responseType: FILE_RESPONSE_TYPE, downloadTag: 'pure_live_backup_logs' })
  },
  sendStreamer(streamName) {
    return httpPostText('/api/search/streamer', streamName)
  },
  sendRoom(roomId) {
    return httpPostText('/api/search/room', roomId)
  },
  async getDanmakuFilter() {
    const res = await httpGet('/api/danmaku_filter')
    return res.isOk ? (res.data ?? []) : []
  },
  updateDanmakuFilter(filters) {
    return httpPostText('/api/danmaku_filter', filters)
  },
  clearLog() {
    return httpPostJson('/api/log/clear', {})
  },
  getVersion() {
    return httpGet('/api/version')
  }
}
