import js from '@eslint/js'
import pluginVue from 'eslint-plugin-vue'

export default [
  {
    ignores: ['**/node_modules/**', '**/dist/**', '**/.nuxt/**', '**/.output/**', '**/.vscode/**']
  },

  js.configs.recommended,

  ...pluginVue.configs['flat/recommended'],

  {
    name: 'app/files-to-lint',
    files: ['**/*.{js,mjs,cjs,ts,vue}'],
    languageOptions: {
      ecmaVersion: 'latest',
      sourceType: 'module',
      globals: {
        process: 'readonly',
        window: 'readonly',
        document: 'readonly',
        navigator: 'readonly',
        localStorage: 'readonly',
        sessionStorage: 'readonly',
        setTimeout: 'readonly',
        clearTimeout: 'readonly',
        setInterval: 'readonly',
        clearInterval: 'readonly',
        defineProps: 'readonly',
        defineEmits: 'readonly',
        defineExpose: 'readonly',
        defineOptions: 'readonly',
        URL: 'readonly',
        Blob: 'readonly',
        FileReader: 'readonly'
      }
    },
    rules: {
      'no-console': process && process.env && process.env.NODE_ENV === 'production' ? 'warn' : 'off',
      'no-debugger': process && process.env && process.env.NODE_ENV === 'production' ? 'warn' : 'off',
      'vue/multi-word-component-names': 'off',
      'vue/no-v-html': 'off',
      'vue/max-attributes-per-line': 'off',
      'vue/singleline-html-element-content-newline': 'off',
      'vue/html-self-closing': [
        'error',
        {
          html: {
            void: 'always',
            normal: 'never',
            component: 'always'
          }
        }
      ],
      'vue/attributes-order': [
        'error',
        {
          order: ['DEFINITION', 'LIST_RENDERING', 'CONDITIONALS', 'RENDER_MODIFIERS', 'GLOBAL', ['UNIQUE', 'SLOT'], 'TWO_WAY_BINDING', 'OTHER_DIRECTIVES', 'OTHER_ATTR', 'EVENTS', 'CONTENT'],
          alphabetical: false
        }
      ]
    }
  }
]
