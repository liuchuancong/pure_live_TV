import { defineStore } from 'pinia'
import { ref } from 'vue'

export const useToastStore = defineStore('toast', () => {
  const isVisible = ref(false)
  const message = ref('')
  const type = ref('success') // success, error, info
  let timer = null

  function show(msg, toastType = 'success') {
    if (timer) clearTimeout(timer)

    message.value = msg
    type.value = toastType
    isVisible.value = true

    timer = setTimeout(() => {
      isVisible.value = false
    }, 2300)
  }

  return { isVisible, message, type, show }
})
