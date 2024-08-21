module.exports = {
  env: {
    browser: true,
    es6: true,
    jasmine: true,
    node: true,
  },
  plugins: ['vue'],
  extends: ['eslint:recommended', 'plugin:vue/recommended', 'prettier'],
  parserOptions: {
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
    // Legacy in from the old days. We should remove these:
    'vue/prop-name-casing': ['warn'],
  },
}
