module.exports = {
  env: {
    browser: true,
    es6: true,
    amd: true,
  },
  plugins: ['vue'],
  extends: ['eslint:recommended', 'plugin:vue/recommended', 'prettier'],
  parserOptions: {
    parser: 'babel-eslint',
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
        argsIgnorePattern: '^_',
      },
    ],
    // The API sends snake case stuff, and this lets us pass things straight
    // through. Not a great compromise though.
    'vue/prop-name-casing': ['off'],
  },
}
