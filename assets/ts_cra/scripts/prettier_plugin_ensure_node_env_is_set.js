// NOTE: WTF is this shit you might ask? Well, here's the cascade of crap we are dealing with here:
//       - We are using prettier-plugin-import-sort to sort our imports
//       - For javascript files, this plugin uses babel to parse files
//       - Babel picks up our babel configuration from package.json, which references shit from create-react-app
//       - Something in create-react-app checks that we have NODE_ENV configured.
//       - Normally, this var would be set by CRA tooling. But since we are going around their tooling, it is undefined.
//       - Therefore, prettier crashes (silently) and doesn't fix our js files
//       SOLUTION: Add this stupid "plugin" which sets NODE_ENV, so that this other plugin doesn't crash
//       This file should be configured in ".prettierrc.yaml" for the hack to work.

if (!process.env.NODE_ENV) {
  process.env.NODE_ENV = 'development';
}

module.exports = {};
