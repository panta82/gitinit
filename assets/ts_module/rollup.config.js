import babel from '@rollup/plugin-babel';
import nodeResolve from '@rollup/plugin-node-resolve';
import { defineConfig } from 'rollup';
import { terser } from 'rollup-plugin-terser';
import typescript from 'rollup-plugin-typescript2';

import pkg from './package.json';

const extensions = ['.ts'];
const noDeclarationFiles = { compilerOptions: { declaration: false } };

const babelRuntimeVersion =
  (pkg.dependencies?.['@babel/runtime'] || '').replace(/^[^0-9]*/, '') || '0.0.0';

const libraryName =
  (pkg.name || 'Library')
    .replace(/(^|[@/_\-\s])(\w)/g, (_, __, char) => (char ? char.toUpperCase() : ''))
    .replace(/[^A-Za-z0-9]/g, '') || 'Library';

const external = [
  ...Object.keys(pkg.dependencies || {}),
  ...Object.keys(pkg.peerDependencies || {}),
].map(name => RegExp(`^${name}($|/)`));

export default defineConfig([
  // CommonJS
  {
    input: 'src/index.ts',
    output: { file: 'dist/index.js', format: 'cjs', indent: false },
    external,
    plugins: [
      nodeResolve({
        extensions,
      }),
      typescript({ useTsconfigDeclarationDir: true }),
      babel({
        extensions,
        plugins: [['@babel/plugin-transform-runtime', { version: babelRuntimeVersion }]],
        babelHelpers: 'runtime',
      }),
    ],
  },

  // ES
  {
    input: 'src/index.ts',
    output: { file: 'dist/es/index.js', format: 'es', indent: false },
    external,
    plugins: [
      nodeResolve({
        extensions,
      }),
      typescript({ tsconfigOverride: noDeclarationFiles }),
      babel({
        extensions,
        plugins: [
          ['@babel/plugin-transform-runtime', { version: babelRuntimeVersion, useESModules: true }],
        ],
        babelHelpers: 'runtime',
      }),
    ],
  },

  // ES for Browsers
  {
    input: 'src/index.ts',
    output: { file: 'dist/es/index.mjs', format: 'es', indent: false },
    plugins: [
      nodeResolve({
        extensions,
      }),
      typescript({ tsconfigOverride: noDeclarationFiles }),
      babel({
        extensions,
        exclude: 'node_modules/**',
        skipPreflightCheck: true,
        babelHelpers: 'bundled',
      }),
      terser({
        compress: {
          pure_getters: true,
          unsafe: true,
          unsafe_comps: true,
        },
      }),
    ],
  },

  // UMD Development
  {
    input: 'src/index.ts',
    output: {
      file: 'dist/umd/index.js',
      format: 'umd',
      name: libraryName,
      indent: false,
    },
    plugins: [
      nodeResolve({
        extensions,
      }),
      typescript({ tsconfigOverride: noDeclarationFiles }),
      babel({
        extensions,
        exclude: 'node_modules/**',
        babelHelpers: 'bundled',
      }),
    ],
  },

  // UMD Production
  {
    input: 'src/index.ts',
    output: {
      file: 'dist/umd/index.min.js',
      format: 'umd',
      name: libraryName,
      indent: false,
    },
    plugins: [
      nodeResolve({
        extensions,
      }),
      typescript({ tsconfigOverride: noDeclarationFiles }),
      babel({
        extensions,
        exclude: 'node_modules/**',
        skipPreflightCheck: true,
        babelHelpers: 'bundled',
      }),
      terser({
        compress: {
          pure_getters: true,
          unsafe: true,
          unsafe_comps: true,
        },
      }),
    ],
  },
]);

