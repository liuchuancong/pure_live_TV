import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import tailwindcss from '@tailwindcss/vite'
import path from 'path'

export default defineConfig({
  plugins: [
    vue(),
    tailwindcss(),
  ],
  base: './',
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src') 
    }
  },
  server: {
    host: '0.0.0.0',
    port: 3000
  }
})
