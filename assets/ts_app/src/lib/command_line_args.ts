import libPath from 'path';

import { TalentedArgOptions, TalentedArgs } from 'talented-args';

import { AnyRecord } from './types';

export function commandLineArgs<TDestination extends AnyRecord, TCommands extends string = never>(
  options?: TalentedArgOptions<TDestination, TCommands>
) {
  return new TalentedArgs<TDestination, TCommands>({
    ...options,
    logo_path: libPath.resolve(__dirname, '../assets/logo-ascii.txt'),
  });
}
