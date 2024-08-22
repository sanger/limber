module.exports = {
  env: {
    'vitest/env': true,
    browser: true,
    node: true,
  },
  plugins: ['vitest', 'vue'],
  extends: ['eslint:recommended', 'plugin:vue/recommended', 'prettier'],
  parserOptions: {
    ecmaVersion: 'latest',
    sourceType: 'module',
    requireConfigFile: false,
  },
  rules: {
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
    // We need a proper logging solution (see https://github.com/sanger/limber/issues/836),
    // but until then:
    'no-console': ['error', { allow: ['warn', 'error', 'log'] }],
    // Legacy in from the old days. We should remove these:
    'vue/prop-name-casing': ['warn'],
  },
}
