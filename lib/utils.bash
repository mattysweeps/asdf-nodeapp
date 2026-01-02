ASDF_NODEAPP_MY_NAME=asdf-nodeapp

ASDF_NODEAPP_RESOLVED_NODE_PATH=

if [[ ${ASDF_NODEAPP_DEBUG:-} -eq 1 ]]; then
  # In debug mode, dump everything to a log file
  # got a little help from https://askubuntu.com/a/1345538/985855

  ASDF_NODEAPP_DEBUG_LOG_PATH="/tmp/${ASDF_NODEAPP_MY_NAME}-debug.log"
  mkdir -p "$(dirname "$ASDF_NODEAPP_DEBUG_LOG_PATH")"

  printf "\n\n-------- %s ----------\n\n" "$(date)" >>"$ASDF_NODEAPP_DEBUG_LOG_PATH"

  exec > >(tee -ia "$ASDF_NODEAPP_DEBUG_LOG_PATH")
  exec 2> >(tee -ia "$ASDF_NODEAPP_DEBUG_LOG_PATH" >&2)

  exec 19>>"$ASDF_NODEAPP_DEBUG_LOG_PATH"
  export BASH_XTRACEFD=19
  set -x
fi

fail() {
  echo >&2 -e "${ASDF_NODEAPP_MY_NAME}: [ERROR] $*"
  exit 1
}

log() {
  if [[ ${ASDF_NODEAPP_DEBUG:-} -eq 1 ]]; then
    echo >&2 -e "${ASDF_NODEAPP_MY_NAME}: $*"
  fi
}

# asdf plugin names can't start with @ or contain /
# hacky but use __and__ and __slash__ as placeholders.
get_package_escaped() {
  local package=$1
  package="${package//__and__/@}"
  package="${package//__slash__//}"
  echo $package
}

get_node_version() {
  local node_path="$1"
  local regex='v(.+)'

  node_version_raw=$("$node_path" --version)

  if [[ $node_version_raw =~ $regex ]]; then
    echo -n "${BASH_REMATCH[1]}"
  else
    fail "Unable to determine node version"
  fi
}

get_npm_version() {
  local npm_path="$1"

  npm_version_raw=$("${npm_path}" --version)
  echo -n "$npm_version_raw"
}

resolve_node_path() {
  # if ASDF_NODEAPP_DEFAULT_NODE_PATH is set, use it, else:
  # 1. try $(which node)
  # 2. try $(asdf which node)
  # 3. try /usr/local/bin/node

  if [ -n "${ASDF_NODEAPP_DEFAULT_NODE_PATH+x}" ]; then
    ASDF_NODEAPP_RESOLVED_NODE_PATH="$ASDF_NODEAPP_DEFAULT_NODE_PATH"
    return
  fi

  # cd to $HOME to avoid picking up a local node from .tool-versions
  pushd "$HOME" >/dev/null || fail "Failed to pushd \$HOME"

  # run direnv in $HOME to escape any direnv we might already be in
  if type -P direnv &>/dev/null; then
    eval "$(DIRENV_LOG_FORMAT= direnv export bash)"
  fi

  local nodes=()

  nodes+=(node)
  local asdf_node
  if asdf_node=$(asdf which node 2>/dev/null); then
    nodes+=("$asdf_node")
  fi
  nodes+=(/usr/local/bin/node)

  for n in "${nodes[@]}"; do
    local node_version
    log "Testing '$n' ..."
    if node_version=$(get_node_version "$n" 2>/dev/null); then
      if [[ $node_version =~ ^([0-9]+)\.([0-9]+)\. ]]; then
        local node_version_major=${BASH_REMATCH[1]}
        if [ "$node_version_major" -ge 16 ]; then
          ASDF_NODEAPP_RESOLVED_NODE_PATH="$n"
          break
        fi
      fi
    else
      continue
    fi
  done

  popd >/dev/null || fail "Failed to popd"

  if [ -z "$ASDF_NODEAPP_RESOLVED_NODE_PATH" ]; then
    fail "Failed to find node >= 16"
  else
    log "Using node at '$ASDF_NODEAPP_RESOLVED_NODE_PATH'"
  fi
}

get_package_versions() {
  local package=$(get_package_escaped "$1")
  # Escape package name for URL (replace @ with %40)
  local escaped_package=${package//@/%40}
  curl -s "https://registry.npmjs.org/${escaped_package}" | jq -r '.versions | keys | .[]' | sort -V
}

install_version() {
  local package=$(get_package_escaped "$1")
  local install_type="$2"
  local full_version="$3"
  local install_path="$4"

  local versions=(${full_version//\@/ })
  local app_version=${versions[0]}
  if [ "${#versions[@]}" -gt 1 ]; then

    if ! asdf plugin list | grep nodejs; then
      fail "Cannot install $1 $3 - asdf nodejs plugin is not installed!"
    fi

    node_version=${versions[1]}
    asdf install nodejs "$node_version"
    ASDF_NODEAPP_RESOLVED_NODE_PATH=$(ASDF_NODEJS_VERSION="$node_version" asdf which node)
  fi

  if [ "${install_type}" != "version" ]; then
    fail "supports release installs only"
  fi

  mkdir -p "${install_path}"

  # Create a clean npm installation directory
  local npm_prefix="$install_path"/npm
  mkdir -p "$npm_prefix"

  # Get the npm path associated with our node
  local npm_path
  npm_path=$(dirname "$ASDF_NODEAPP_RESOLVED_NODE_PATH")/npm
  if [ ! -f "$npm_path" ]; then
    npm_path="npm"
  fi

  (
  # export env vars
  if [[ -n "${ASDF_PLUGIN_PATH-}" ]] && [[ -e "$ASDF_PLUGIN_PATH/install_env" ]]; then
    log "sourcing $ASDF_PLUGIN_PATH/install_env"
    eval "$(grep '^export ' "$ASDF_PLUGIN_PATH/install_env" | awk '{print $1 " " $2}' | grep -v ';')"
  fi

  # Install the App globally in our isolated prefix
  cd "$npm_prefix"
  PATH="$(dirname "$ASDF_NODEAPP_RESOLVED_NODE_PATH"):$PATH" "$npm_path" install -g --prefix="$npm_prefix" "$package@$app_version"
  )

  # Create bin directory and symlink executables
  mkdir -p "$install_path"/bin

  # Find all executables in the npm bin directory
  local npm_bin_dir="$npm_prefix/bin"
  if [ -d "$npm_bin_dir" ]; then
    for exe in "$npm_bin_dir"/*; do
      if [ -f "$exe" ] && [ -x "$exe" ]; then
        local exe_name=$(basename "$exe")
        # using a shim instead of a sym link
        cat > "$install_path/bin/$exe_name" << END
#!/usr/bin/env bash
"$npm_prefix/../../../nodejs/$node_version/bin/node" "$exe" "\$@"
END
        chmod +x "$install_path/bin/$exe_name"
      fi
    done
  fi
}

resolve_node_path
