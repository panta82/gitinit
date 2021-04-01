module.exports = {
  extends: ['react-app', 'react-app/jest'],

  rules: {
    'no-empty-pattern': 'off',
    'jsx-a11y/anchor-is-valid': 'off',
    'react/jsx-pascal-case': 'off',
  },

  overrides: [
    {
      // Typescript-related stuff should all go here, so it doesn't get called for js stuff

      files: ['**/*.ts?(x)'],
      rules: {
        '@typescript-eslint/naming-convention': [
          'error',
          {
            selector: 'interface',
            format: ['PascalCase'],
            custom: {
              regex: '^I[A-Z]',
              match: true,
            },
          },
        ],
      },
    },
  ],
};
