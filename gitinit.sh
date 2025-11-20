#!/usr/bin/env bash

set -o errexit

# Get this script's directory, despite the symlinks
DIR="$(dirname "$(readlink -f "$0")")"

# Get project name based on current directory name
NAME=${PWD##*/}
TEMPLATE=""
TEMPLATES=( empty node ts_module ts_app )
FORCE=false

# Template descriptions
declare -A TEMPLATE_DESCRIPTIONS
TEMPLATE_DESCRIPTIONS[empty]="Just git init, README.md and a minimal .gitignore"
TEMPLATE_DESCRIPTIONS[node]="Empty node.js project with package.json and prettier"
TEMPLATE_DESCRIPTIONS[ts_module]="Node.js module project with typescript, jest and eslint"
TEMPLATE_DESCRIPTIONS[ts_app]="Node.js app project with typescript, jest and eslint"

LOG_FILE="/tmp/gitinit.log"
echo "Executed at $(date --iso-8601=seconds)" > $LOG_FILE
echo "--------------------------------------" >> $LOG_FILE

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

error_trap() {
  error "Command has returned an error code. This is the full output log from ${LOG_FILE}:"
  cat "${LOG_FILE}"
  exit 1
}
trap error_trap ERR

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

  TEMPLATE=$(dialog --keep-tite --clear --backtitle "gitinit template" --title "Select template to use" --menu "Choose one of the following templates:" 15 80 8 "${options[@]}" 2>&1 >/dev/tty)
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
  : > .gitignore
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
  cat "$DIR/assets/gitignore_node" >> .gitignore

  log "Installing node modules..."
  npm install >> $LOG_FILE 2>&1

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
  cat "${DIR}/assets/ts_module/package.json" | sed -E 's/\$NAME/'"${NAME}"'/' > package.json

  log "Copying tooling configs..."
  cp "${DIR}/assets/ts_module/tsconfig.json" "./tsconfig.json"
  cp "${DIR}/assets/ts_module/eslintrc.js" "./.eslintrc.js"
  cp "${DIR}/assets/ts_module/jest.config.js" "./jest.config.js"
  cp "${DIR}/assets/ts_module/rollup.config.js" "./rollup.config.js"

  log "Preparing prettier..."
  cp "${DIR}/assets/.prettierrc.yaml" "./.prettierrc.yaml"

  log "Generating gitignore..."
  cat "$DIR/assets/gitignore_node" >> .gitignore
  cat "$DIR/assets/ts_module/gitignore_custom" >> .gitignore
  cat "$DIR/assets/gitignore_custom" >> .gitignore

  log "Copying initial files..."
  cp -r "${DIR}/assets/ts_module/spec" "./spec"
  cp -r "${DIR}/assets/ts_module/src" "./src"

  log "Setting up JetBrains project..."
  cp -r "${DIR}/assets/ts_module/.idea" "./.idea"
  mv "./.idea/project-name.iml" "./.idea/${NAME}.iml"
  sed -i "s/\$NAME/${NAME}/g" "./.idea/modules.xml"

  log "Installing node modules..."
  npm install >> $LOG_FILE 2>&1

  log "Creating initial commit..."
  git add .
  git commit -m "Initial"
  log "Typescript module project initialized"
}

exec_ts_app() {
  validate_empty_dir

  exec_init

  log "Preparing package.json..."
  cat "${DIR}/assets/ts_app/package.json" | sed -E 's/\$NAME/'"${NAME}"'/' > package.json

  log "Preparing prettier..."
  cp "${DIR}/assets/.prettierrc.yaml" "./.prettierrc.yaml"

  log "Generating gitignore..."
  cat "$DIR/assets/gitignore_node" >> .gitignore
  cat "$DIR/assets/ts_app/gitignore_custom" >> .gitignore
  cat "$DIR/assets/gitignore_custom" >> .gitignore

  log "Adding typescript..."
  cp "${DIR}/assets/ts_app/tsconfig.json" "./tsconfig.json"

  log "Adding eslint..."
  cp "${DIR}/assets/ts_app/eslintrc.js" "./.eslintrc.js"

  log "Adding jest..."
  cp "${DIR}/assets/ts_app/jest.config.js" "./jest.config.js"

  log "Copying initial files..."
  cp -r "${DIR}/assets/ts_app/support" "./support"
  cp -r "${DIR}/assets/ts_app/spec" "./spec"
  cp -r "${DIR}/assets/ts_app/src" "./src"

  log "Setting up logo..."
  mkdir -p './src/assets/'
  echo -e "\n\n${NAME}" > './src/assets/logo-ascii.txt'

  log "Setting up JetBrains project..."
  cp -r "${DIR}/assets/ts_app/.idea" "./.idea"
  mv "./.idea/project-name.iml" "./.idea/${NAME}.iml"
  sed -i "s/\$NAME/${NAME}/g" "./.idea/modules.xml"

  log "Adding dev dependencies..."
  npm install --save-dev "typescript" "@typescript-eslint/eslint-plugin" "@typescript-eslint/parser" "eslint" "eslint-config-prettier" "prettier-plugin-import-sort" "import-sort-style-panta" "@types/jest" "jest" "ts-jest"  >> $LOG_FILE 2>&1

  log "Adding dependencies..."
  npm install --save "talented-logger" "talented-args" >> $LOG_FILE 2>&1

  log "Updating dependencies..."
  npm install >> $LOG_FILE 2>&1

  log "Creating initial commit..."
  git add .
  git commit -m "Initial"
  log "Typescript app project initialized"
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
