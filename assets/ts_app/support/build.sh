#!/usr/bin/env bash

# Build project, and then copy assets (so they can be accessed by build code)

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $DIR
cd ..

PATH="$(pwd)/node_modules/.bin:$PATH" tsc "$@"

cp -arf ./src/assets ./dist/assets

