#!/usr/bin/env bash

set -o errexit

# Get this script's directory, despite the symlinks
DIR="$(dirname "$(readlink -f "$0")")"

# Get project name based on current directory name
NAME=${PWD##*/}
TEMPLATE=""
TEMPLATES=( empty node )
FORCE=false

# Template descriptions
declare -A TEMPLATE_DESCRIPTIONS
TEMPLATE_DESCRIPTIONS[empty]="Just the git, README.md and JetBrains-friendly .gitignore"
TEMPLATE_DESCRIPTIONS[node]="Node.js template, with package.json and prettier"

usage() {
	cat <<END
gitinit: Initialize a git project, with some basic boilerplate

Usage:
  gitinit [-h|--help] [template]

Switches:
  -h|--help        Print this help screen and exit

END
}

log() {
	echo "$@"
}

warning() {
  echo "[WARNING] $*" >&2
}

error() {
  echo "[ERROR] $*" >&2
}

fatal() {
	error "$*"
	exit 1
}

parse_args() {
	for arg in "$@"; do
		if [[ "$arg" = '-h' || "$arg" = '--help' ]]; then
			usage
			exit 0
		elif [[ "$arg" = '-f' || "$arg" = '--force' ]]; then
		  FORCE=true
    elif [[ "${arg:0:1}" != '-' && -z $TEMPLATE ]]; then
			TEMPLATE="$arg"
		else
			fatal "Invalid argument: '$arg'."
		fi
	done
}

ask_for_template() {
  command -v dialog >/dev/null 2>&1 || fatal "Command 'dialog' is not present. Either provide template as argument, or do 'apt install dialog'"

  options=()
  for template in "${TEMPLATES[@]}"; do
    options+=("${template}")
    options+=("${TEMPLATE_DESCRIPTIONS[$template]}")
  done

  TEMPLATE=$(dialog --keep-tite --clear --backtitle "gitinit template" --title "Select template to use" --menu "Choose one of the following templates:" 15 80 4 "${options[@]}" 2>&1 >/dev/tty)
}

validate_empty_dir() {
  local files
  files="$(ls -A)"
  if [[ -z "$files" ]]; then
    return
  fi

  if $FORCE ; then
    warning "Creating a new project in a dirty directory due to the FORCE flag!"
    return
  fi

  fatal "Directory is not empty. Clean it up, or use the --force flag."
}

exec_init() {
  log "Initializing git..."
  git init
  log "Generating README..."
  echo "# ${NAME}" > ./README.md
  cat "$DIR/assets/gitignore_idea" > .gitignore
}

exec_empty() {
  exec_init

  cat "$DIR/assets/gitignore_custom" >> .gitignore

  log "Creating initial commit..."
  git add .
  git commit -m "Initial"
  log "Empty project initialized"
}

exec_node() {
  exec_init

  log "Preparing package.json..."
  cat "${DIR}/assets/package.json" | sed -E 's/\$NAME/'"${NAME}"'/' > package.json

  log "Preparing prettier..."
  cp "${DIR}/assets/.prettierrc.yaml" "./.prettierrc.yaml"

  log "Adding node stuff to gitignore..."
  cat "$DIR/assets/gitignore_node" >> .gitignore

  log "Installing node modules..."
  npm install > /dev/null 2>&1

  cat "$DIR/assets/gitignore_custom" >> .gitignore

  log "Creating initial commit..."
  git add .
  git commit -m "Initial"
  log "Node project initialized"
}

main() {
  parse_args "$*"

  validate_empty_dir

  if  [[ -z $TEMPLATE ]]; then
    ask_for_template
  fi

  if [[ -z $TEMPLATE ]]; then
    # User cancelled
    exit 0
  fi

  [[ ! " ${TEMPLATES[@]} " =~ " ${TEMPLATE} " ]] && fatal "Invalid template: ${TEMPLATE}"

  log "Creating project named \"${NAME}\" using template \"${TEMPLATE}\"..."
  local fn_name="exec_${TEMPLATE}"
  $fn_name
}

main $*