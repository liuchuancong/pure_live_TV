import { ref } from 'vue'

export function useNativeClipboard() {
  const copied = ref(false)
  const isSupported = typeof navigator !== 'undefined' && !!navigator.clipboard

  const copy = async text => {
    if (!isSupported) return false
    try {
      await navigator.clipboard.writeText(text)
      copied.value = true
      setTimeout(() => {
        copied.value = false
      }, 2000)
      return true
    } catch {
      return false
    }
  }

  return { copy, copied, isSupported }
}
