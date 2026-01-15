export default {
  extends: 'recommended',
  rules: {
    'no-forbidden-elements': ['error', ['meta', 'link', 'script']],
  },
  overrides: [
    {
      files: ['**/components/seo/**/*.gts'],
      rules: {
        'no-forbidden-elements': 'off',
      },
    },
  ],
};
