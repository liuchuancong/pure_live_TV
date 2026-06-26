import { createApp } from 'vue'
import { createPinia } from 'pinia'
import { router } from './router.js'
// @ts-ignore
import './style.css'
import App from './App.vue'

const app = createApp(App)
app.use(createPinia())
app.use(router)
app.mount('#app')
