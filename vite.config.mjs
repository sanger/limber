import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'
import vue from '@vitejs/plugin-vue2' // TODO: replace with @vitejs/plugin-vue for Vue 3

export default defineConfig({
  build: {
    target: 'chrome65',
  },
  plugins: [RubyPlugin(), vue()],
  test: {
    globals: true,
    environment: 'jsdom',
    coverage: {
      provider: 'v8',
    },
  },
})
