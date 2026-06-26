<template>
  <Transition
    enter-from-class="translate-y-full opacity-0"
    enter-active-class="transform transition duration-300 ease-out"
    enter-to-class="translate-y-0 opacity-100"
    leave-from-class="translate-y-0 opacity-100"
    leave-active-class="transform transition duration-200 ease-in"
    leave-to-class="translate-y-full opacity-0"
  >
    <div v-if="toast.isVisible" class="fixed bottom-16 sm:bottom-20 left-0 right-0 z-[9999] flex justify-center pointer-events-none px-3 sm:px-4">
      <div class="flex items-center gap-2 sm:gap-3 px-3.5 sm:px-5 py-2.5 sm:py-3.5 bg-ios-card/85 dark:bg-ios-card/90 border border-ios-border/30 dark:border-ios-border/40 rounded-full shadow-lg backdrop-blur-xl pointer-events-auto max-w-[min(calc(100vw-24px),420px)]">
        <component :is="iconName" class="w-4 h-4 sm:w-[18px] sm:h-[18px] shrink-0" :class="iconColor" stroke-width="2.2" />
        <span class="text-xs sm:text-sm font-medium text-ios-text-h dark:text-ios-text-h leading-snug">
          {{ toast.message }}
        </span>
      </div>
    </div>
  </Transition>
</template>

<script setup>
import { computed } from 'vue'
import { CheckCircle, XCircle, Info } from 'lucide-vue-next'
import { useToastStore } from '../store/toast.js'

const toast = useToastStore()
const iconName = computed(() => {
  if (toast.type === 'success') return CheckCircle
  if (toast.type === 'error') return XCircle
  return Info
})
const iconColor = computed(() => {
  if (toast.type === 'success') return 'text-emerald-500'
  if (toast.type === 'error') return 'text-rose-500'
  return 'text-ios-blue'
})
</script>
