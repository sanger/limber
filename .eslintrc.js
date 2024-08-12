module.exports = {
  env: {
    browser: true,
    commonjs: true,
    es6: true,
    jasmine: true,
    node: true,
  },
  plugins: ['vue'],
  extends: ['eslint:recommended', 'plugin:vue/recommended', 'prettier'],
  parserOptions: {
    parser: '@babel/eslint-parser',
    sourceType: 'module',
    requireConfigFile: false,
    ecmaVersion: 2018,
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
