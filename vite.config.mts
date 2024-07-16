import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'
import vue from '@vitejs/plugin-vue2' // TODO: replace with @vitejs/plugin-vue for Vue 3

export default defineConfig({
  plugins: [RubyPlugin(), vue()],
})
