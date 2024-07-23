module.exports = {
  env: {
    'jest/globals': true,
    browser: true,
    commonjs: true,
    es6: true,
    jasmine: true,
    node: true,
  },
  globals: {
    global: true,
    SCAPE: true,
  },
  plugins: ['jest', 'vue'],
  extends: ['eslint:recommended', 'plugin:vue/recommended', 'plugin:jest/recommended', 'prettier'],
  parserOptions: {
    parser: '@babel/eslint-parser',
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
        argsIgnorePattern: '^_|undefined', // `undefined` is grandfathered in and should be removed
      },
    ],
    // We need a proper logging solution (see https://github.com/sanger/limber/issues/836),
    // but until then:
    'no-console': ['error', { allow: ['warn', 'error', 'log'] }],
    // Grandfathered in from the old days. We should remove these:
    'vue/prop-name-casing': ['warn'],
    'no-shadow-restricted-names': ['warn'], // specifically for `undefined`
  },
  overrides: [
    {
      files: ['**/*.spec.js'],
      plugins: ['jest', 'vue'],
    },
  ],
}
