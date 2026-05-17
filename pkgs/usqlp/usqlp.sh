# shellcheck shell=bash
set -euo pipefail

USQL_BIN="${USQL_BIN:-usql}"
OP_BIN="${OP_BIN:-op}"
FZF_BIN="${FZF_BIN:-fzf}"
YQ_BIN="${YQ_BIN:-yq}"

template="${USQL_CONFIG_TEMPLATE:-$HOME/.config/usql/config.yaml.tpl}"
runtime_base="${USQL_WRAPPER_RUNTIME_DIR:-${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}/usql-runtime-$UID}}"
runtime_dir="$runtime_base/usql"
runtime_config="$runtime_dir/config.yaml"

unsafe_runtime_dir() {
  echo "Refusing unsafe runtime directory: $runtime_base" >&2
  exit 1
}

ensure_runtime_base() {
  if [[ ! -e "$runtime_base" ]]; then
    mkdir -m 700 "$runtime_base"
  fi

  if [[ ! -d "$runtime_base" || -L "$runtime_base" ]]; then
    unsafe_runtime_dir
  fi

  if [[ "$(stat -c '%u' "$runtime_base")" != "$(id -u)" ]]; then
    unsafe_runtime_dir
  fi

  chmod 700 "$runtime_base"
}

usage() {
  cat <<EOF
Usage:
  usqlp                 Pick a usql connection with fzf
  usqlp <conn> [args]   Connect to a named connection
  usqlp --list          List configured connections
  usqlp --refresh       Re-render config from 1Password
  usqlp --config-path   Print generated runtime config path

Agent/non-interactive usage:
  usqlp --list
  usqlp <connection> -c 'select 1'
  usqlp --refresh

Raw usql remains available for direct DSNs and scripts.

Env:
  USQL_CONFIG_TEMPLATE      Override template path
  USQL_WRAPPER_RUNTIME_DIR  Override runtime base directory
  USQL_BIN                  Override usql executable
  OP_BIN                    Override 1Password CLI executable
  FZF_BIN                   Override fzf executable
  YQ_BIN                    Override yq executable
EOF
}

ensure_config() {
  ensure_runtime_base
  mkdir -p "$runtime_dir"
  chmod 700 "$runtime_dir"

  if [[ ! -f "$runtime_config" || "${1:-}" == "refresh" ]]; then
    if [[ ! -f "$template" ]]; then
      echo "Missing template: $template" >&2
      exit 1
    fi

    tmp="$(mktemp "$runtime_dir/config.yaml.XXXXXX")"
    chmod 600 "$tmp"

    if ! "$OP_BIN" inject --in-file "$template" --out-file "$tmp"; then
      rm -f "$tmp"
      exit 1
    fi

    mv "$tmp" "$runtime_config"
    chmod 600 "$runtime_config"
  fi
}

list_connections() {
  "$YQ_BIN" -r '.connections | keys | .[]' "$runtime_config"
}

pick_connection() {
  list_connections | "$FZF_BIN" --prompt='usql connection> '
}

case "${1:-}" in
  -h|--help)
    usage
    exit 0
    ;;
  --refresh)
    ensure_config refresh
    echo "Refreshed: $runtime_config"
    exit 0
    ;;
  --config-path)
    ensure_config
    echo "$runtime_config"
    exit 0
    ;;
  --list)
    ensure_config
    list_connections
    exit 0
    ;;
esac

ensure_config

if [[ $# -gt 0 ]]; then
  exec "$USQL_BIN" --config "$runtime_config" "$@"
fi

if ! conn="$(pick_connection)"; then
  exit 130
fi

if [[ -z "$conn" ]]; then
  exit 1
fi

exec "$USQL_BIN" --config "$runtime_config" "$conn"
