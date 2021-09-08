module.exports = {
    "env": {
        "browser": true,
        "es6": true,
        "jest/globals": true
    },
    "plugins": ["jest", "vue"],
     "extends": [
        "eslint:recommended",
        "plugin:vue/recommended"
    ],
    "parserOptions": {
        "parser": "babel-eslint",
        "sourceType": "module"
    },
    "rules": {
        "indent": [
            "error",
            2
        ],
        "linebreak-style": [
            "error",
            "unix"
        ],
        "quotes": [
            "error",
            "single"
        ],
        "semi": [
            "error",
            "never"
        ],
        "no-unused-vars": [
            "error", {
                "vars": "all",
                "args": "after-used",
                "ignoreRestSiblings": false,
                "argsIgnorePattern": "^_"
            }
        ],
        /* We need a proper logging solution, but until then: */
        "no-console": ["error", { "allow": ["warn", "error", "log"] }],
        // The API sends snake case stuff, and this lets us pass things straight
        // through. Not a great compromise though.
        "vue/prop-name-casing": ['off']
    },
    "overrides": [
        {
          "files": [ "**/*.spec.js" ],
          "plugins": ["jest", "vue"]
        }
      ]
};
