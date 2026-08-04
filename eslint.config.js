const { defineConfig } = require('eslint/config')

const globals = require('globals')
const vitest = require('@vitest/eslint-plugin')
const vue = require('eslint-plugin-vue')
const js = require('@eslint/js')

const { FlatCompat } = require('@eslint/eslintrc')

const compat = new FlatCompat({
  baseDirectory: __dirname,
  recommendedConfig: js.configs.recommended,
  allConfig: js.configs.all,
})

module.exports = defineConfig([
  {
    languageOptions: {
      globals: {
        ...globals.browser,
        ...globals.node,
        ...vitest.environments.env.globals,
      },

      ecmaVersion: 'latest',
      sourceType: 'module',

      parserOptions: {
        requireConfigFile: false,
        projectService: true
      },
    },
    plugins: {
      vue,
      vitest
    },
    extends: compat.extends('eslint:recommended', 'plugin:vue/recommended', 'prettier'),
    rules: {
      ...vitest.configs.recommended.rules,
      'linebreak-style': ['error', 'unix'],

      'no-unused-vars': [
        'error',
        {
          vars: 'all',
          args: 'after-used',
          ignoreRestSiblings: false,
          argsIgnorePattern: '^_',
        },
      ],

      'no-var': 'error',

      // We need a proper logging solution (see https://github.com/sanger/limber/issues/836), but until then:
      'no-console': [
        'error',
        {
          allow: ['warn', 'error', 'log'],
        },
      ],

      // Legacy in from the old days. We should remove these:
      'vue/prop-name-casing': ['warn'],
    },
  },
])
