const augments: { [key: string]: any } = {};

// TODO: Attach your globals to arguments

// Set local dirname and filename
augments.__dirname = __dirname;
augments.__filename = __filename;

// Just dump ALL our modules into the main
for (const key in require.cache) {
  if (/\/node_modules\//.test(key)) {
    continue;
  }

  const mod = require.cache[key];
  if (mod.loaded) {
    for (const name in mod.exports) {
      if (!(name in augments)) {
        augments[name] = mod.exports[name];
      }
    }
  }
}

// Helper for calling async methods
augments.$p = async arg => {
  try {
    if (typeof arg === 'function') {
      arg = arg();
    }

    const result = await arg;
    console.log(result);
  } catch (err) {
    console.error(err);
  }
};

Object.assign(global, augments);
