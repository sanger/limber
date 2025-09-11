import { defineConfig } from 'vite'
import RubyPlugin from 'vite-plugin-ruby'
import vue from '@vitejs/plugin-vue'
import Components from 'unplugin-vue-components/vite'
import { BootstrapVueNextResolver } from 'bootstrap-vue-next'

export default defineConfig({
  build: {
    target: 'chrome65',
  },
  css: {
    preprocessorOptions: {
      scss: {
        quietDeps: true,
        silenceDeprecations: ['import', 'color-functions', 'global-builtin'],
        verbose: false,
      },
    },
  },
  plugins: [
    RubyPlugin(),
    vue(),
    Components({
      dts: false,
      resolvers: [BootstrapVueNextResolver()],
    }),
  ],
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: './javascript/test_support/setup.js',
    coverage: {
      provider: 'v8',
      reporter: ['lcov', 'text'],
    },
    // This hides the "Download the Vue Devtools extension" message from the console
    onConsoleLog(log) {
      if (log.includes('Download the Vue Devtools extension')) return false
    },
  },
})
