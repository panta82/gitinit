#!/usr/bin/env ts-node-script

import { log } from 'talented-logger';
import { commandLineArgs } from '../lib/command_line_args';

Promise.resolve().then(main).catch(err => {
  log.error(err);
  process.exit(1);
});

async function main() {
  const args = commandLineArgs({
    title: 'App',
    description: 'My app',
  }).parseOrDie();

  log.info(`Supplied args are: ${JSON.stringify(args)}`);
}
