import antfu from '@antfu/eslint-config'

export default antfu({
  ignores: ['mise.toml', '**/_typings/**'],
}, {
  files: ['runtime/src/**/*.ts'],
  rules: {
    'style/padding-line-between-statements': ['error', { blankLine: 'always', prev: 'if', next: '*' }, { blankLine: 'always', prev: '*', next: 'return' }],
    'object-shorthand': 'off',
  },
})
