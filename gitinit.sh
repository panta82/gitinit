#!/usr/bin/env bash

set -o errexit

# Get this script's directory, despite the symlinks
DIR="$(dirname "$(readlink -f "$0")")"

# Get project name based on current directory name
NAME=${PWD##*/}
TEMPLATE=""
TEMPLATES=( empty node ts_module )
FORCE=false

# Template descriptions
declare -A TEMPLATE_DESCRIPTIONS
TEMPLATE_DESCRIPTIONS[empty]="Just the git, README.md and JetBrains-friendly .gitignore"
TEMPLATE_DESCRIPTIONS[node]="Empty node.js project with package.json and prettier"
TEMPLATE_DESCRIPTIONS[ts_module]="Node.js project with typescript, jest and eslint"

usage() {
  local templates
  templates=""
  for template in "${TEMPLATES[@]}"; do
    templates="${templates}  ${template}\t\t   ${TEMPLATE_DESCRIPTIONS[$template]}\n"
  done

	cat <<END
gitinit: Initialize a git project, using a few basic boilerplates that panta likes.
Should be executed inside the (empty) directory where you want the project to live.

Usage:
  gitinit [-h|--help][-f|--force] [template]

Switches:
  -h|--help        Print this help screen and exit
  -f|--force       Force execution of the template even if directory is not empty.

END
echo "Templates:"
echo -e "${templates}"
echo -e "If you don't specify a template, you will be asked to pick one interactively\n"
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
  validate_empty_dir

  exec_init

  cat "$DIR/assets/gitignore_custom" >> .gitignore

  log "Creating initial commit..."
  git add .
  git commit -m "Initial"
  log "Empty project initialized"
}

exec_node() {
  validate_empty_dir

  exec_init

  log "Preparing package.json..."
  cat "${DIR}/assets/node/package.json" | sed -E 's/\$NAME/'"${NAME}"'/' > package.json

  log "Preparing prettier..."
  cp "${DIR}/assets/.prettierrc.yaml" "./.prettierrc.yaml"

  log "Adding node stuff to gitignore..."
  cat "$DIR/assets/node/gitignore_node" >> .gitignore

  log "Installing node modules..."
  npm install > /dev/null 2>&1

  cat "$DIR/assets/gitignore_custom" >> .gitignore

  log "Creating initial commit..."
  git add .
  git commit -m "Initial"
  log "Node project initialized"
}

exec_ts_module() {
  validate_empty_dir

  exec_init

  log "Preparing package.json..."
  cat "${DIR}/assets/ts/package.json" | sed -E 's/\$NAME/'"${NAME}"'/' > package.json
  npm install > /dev/null 2>&1

  log "Preparing prettier..."
  cp "${DIR}/assets/.prettierrc.yaml" "./.prettierrc.yaml"

  log "Adding node stuff to gitignore..."
  cat "$DIR/assets/node/gitignore_node" >> .gitignore

  log "Adding typescript stuff to gitignore..."
  cat "$DIR/assets/ts/gitignore_ts" >> .gitignore

  cat "$DIR/assets/gitignore_custom" >> .gitignore

  log "Adding typescript..."
  cp "${DIR}/assets/ts/tsconfig.json" "./tsconfig.json"
  npm install --save-dev typescript  > /dev/null 2>&1

  log "Adding eslint..."
  cp "${DIR}/assets/ts/eslintrc.js" "./.eslintrc.js"
  npm install --save-dev "@typescript-eslint/eslint-plugin" "@typescript-eslint/parser" "eslint" "eslint-config-prettier"  > /dev/null 2>&1

  log "Adding jest..."
  cp "${DIR}/assets/ts/jest.config.js" "./jest.config.js"
  npm install --save-dev "@types/jest" "jest" "ts-jest"  > /dev/null 2>&1

  log "Copying initial files..."
  cp -r "${DIR}/assets/ts/spec" "./spec"
  cp -r "${DIR}/assets/ts/src" "./src"

  log "Creating initial commit..."
  git add .
  git commit -m "Initial"
  log "Typescript module project initialized"
}

main() {
  parse_args "$*"

  if  [[ -z $TEMPLATE ]]; then
    ask_for_template
  fi

  if [[ -z $TEMPLATE ]]; then
    # User cancelled
    exit 0
  fi

  # shellcheck disable=SC2199
  # shellcheck disable=SC2076
  [[ ! " ${TEMPLATES[@]} " =~ " ${TEMPLATE} " ]] && fatal "Invalid template: ${TEMPLATE}"

  log "Creating project named \"${NAME}\" using template \"${TEMPLATE}\"..."
  local fn_name="exec_${TEMPLATE}"
  $fn_name
}

main $*