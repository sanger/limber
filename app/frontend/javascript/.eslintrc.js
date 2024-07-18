module.exports = {
  env: {
    browser: true,
    es6: true,
    jasmine: true,
    'jest/globals': true,
  },
  globals: {
    global: true,
  },
  plugins: ['jest', 'vue'],
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
    // We need a proper logging solution (see https://github.com/sanger/limber/issues/836),
    // but until then:
    'no-console': ['error', { allow: ['warn', 'error', 'log'] }],
    // The API sends snake case stuff, and this lets us pass things straight
    // through. Not a great compromise though.
    'vue/prop-name-casing': ['off'],
  },
  overrides: [
    {
      files: ['**/*.spec.js'],
      plugins: ['jest', 'vue'],
    },
  ],
}
