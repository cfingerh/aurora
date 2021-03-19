module.exports = {
  root: true,
  env: {
    browser: true
  },
  parserOptions: {
    parser: "babel-eslint",
    sourceType: "module"
  },
  extends: ["plugin:vue/essential", "@vue/standard"],
  rules: {
    "comma-dangle": "off",
    "class-methods-use-this": "off",
    "import/no-unresolved": "off",
    "import/extensions": "off",
    "implicit-arrow-linebreak": "off",
    "import/prefer-default-export": "off",
    "no-console": process.env.NODE_ENV === "production" ? "warn" : "off",
    "no-debugger": process.env.NODE_ENV === "production" ? "warn" : "off",
    "vue/component-name-in-template-casing": [
      "error",
      "kebab-case",
      {
        ignores: []
      }
    ]
  }
};