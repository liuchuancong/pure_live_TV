<template>
  <div class="card step-card">
    <div class="step-text-wrap">
      <p v-for="(line, i) in stepContent" :key="i" class="step-line">{{ line }}</p>
    </div>
    <div class="img-wrap" @click="$emit('preview')">
      <img :src="imgSrc" alt="教程截图" class="preview-img" />
    </div>
  </div>
</template>
<script setup>
defineProps({
  stepContent: {
    type: Array,
    required: true
  },
  imgSrc: {
    type: String,
    required: true
  }
})
defineEmits(['preview'])
</script>
<style scoped>
.step-card {
  width: 100%;
}
.step-text-wrap {
  text-align: left;
}
.step-line {
  font-size: 13.5px;
  line-height: 1.55;
  margin: 3px 0;
}
.img-wrap {
  margin-top: 14px;
  text-align: center;
  cursor: pointer;
}
.preview-img {
  height: 200px;
  border-radius: 8px;
  object-fit: cover;
  max-width: 100%;
}
</style>
