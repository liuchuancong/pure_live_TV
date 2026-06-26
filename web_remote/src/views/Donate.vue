<template>
  <div class="p-3 sm:p-4 lg:p-6 max-w-3xl mx-auto space-y-6">
    <div class="px-1">
      <div class="text-[10px] sm:text-xs font-bold text-ios-text/80 uppercase tracking-wider">支持开发者</div>
    </div>
    <div class="bg-ios-card dark:bg-ios-card rounded-2xl border border-ios-border/20 dark:border-ios-border/40 shadow-[0_8px_30px_var(--color-ios-shadow)] p-5 sm:p-6 text-center">
      <h2 class="text-lg sm:text-xl font-bold text-ios-text-h dark:text-gray-100">自愿随心赞助</h2>
      <p class="text-xs sm:text-sm text-ios-gray dark:text-gray-400 mt-3 leading-relaxed">项目全程开源免费，无任何付费门槛。 若是工具给您带来便利，不妨请开发者喝瓶牛奶，心意不分大小，万分感谢。 所有赞助都会投入后续功能更新与长期维护。</p>
      <div class="w-64 h-64 sm:w-72 sm:h-72 mx-auto mt-6 p-4 bg-white rounded-xl shadow-lg">
        <img :src="wechatImg" alt="微信赞助二维码" class="w-full h-full object-contain" />
      </div>
      <p class="text-xs text-ios-gray dark:text-gray-500 mt-4">微信扫码随心赞助，支持开发者</p>
      <div class="mt-6 pt-4 border-t border-ios-border/20 dark:border-ios-border/40">
        <p class="text-[11px] text-ios-gray dark:text-gray-500 leading-relaxed">由衷感谢每一位愿意给予支持的朋友，您的认可就是持续更新的动力。</p>
      </div>
    </div>
  </div>
</template>

<script setup>
import wechatImg from '@/assets/wechat.png'
</script>
