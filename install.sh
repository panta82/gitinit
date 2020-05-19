#!/usr/bin/env bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

# Get this script's directory, despite the symlinks
DIR="$(dirname "$(readlink -f "$0")")"

TARGET_PATH='/usr/local/bin/gitinit'
EXEC_PATH="${DIR}/gitinit.sh"

if [[ -f "$TARGET_PATH" ]]; then
	rm "$TARGET_PATH"
fi

ln -s -T "${EXEC_PATH}" "${TARGET_PATH}"

echo "Created symlink from ${TARGET_PATH} to ${EXEC_PATH}. Use 'gitinit' create new projects"