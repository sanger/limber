module.exports = {
    "env": {
        "browser": true,
        "es6": true,
        "jasmine": true
    },
    "plugins": ["jasmine", "vue"],
     "extends": [
        "eslint:recommended",
        "plugin:vue/recommended",
        "plugin:jasmine/recommended"
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
        ]
    }
};
