module.exports = {
  env: {
    'vitest/env': true,
    browser: true,
    commonjs: true,
    es6: true,
    node: true,
  },
  globals: {
    global: true,
    SCAPE: true,
  },
  plugins: ['vitest', 'vue'],
  extends: ['eslint:recommended', 'plugin:vue/recommended', 'prettier'],
  parserOptions: {
    ecmaVersion: 'latest',
    sourceType: 'module',
  },
  rules: {
    'linebreak-style': ['error', 'unix'],
    'no-unused-vars': [
      'error',
      {
        vars: 'all',
        args: 'after-used',
        ignoreRestSiblings: false,
        argsIgnorePattern: '^_|undefined', // `undefined` is legacy and should be removed
      },
    ],
    // We need a proper logging solution (see https://github.com/sanger/limber/issues/836),
    // but until then:
    'no-console': ['error', { allow: ['warn', 'error', 'log'] }],
    // Legacy in from the old days. We should remove these:
    'vue/prop-name-casing': ['warn'],
    'no-shadow-restricted-names': ['warn'], // specifically for `undefined`
  },
  overrides: [
    {
      files: ['**/*.spec.js'],
      plugins: ['vue'],
    },
  ],
}
