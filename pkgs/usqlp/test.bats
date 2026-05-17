#!/usr/bin/env bats
# shellcheck shell=bash disable=SC2153

setup() {
  test_dir="$(mktemp -d)"
  fakebin="$test_dir/bin"
  runtime_base="$test_dir/runtime"
  template="$test_dir/config.yaml.tpl"
  call_log="$test_dir/calls.log"
  mkdir -p "$fakebin"
  touch "$call_log"
  bash_path="$(command -v bash)"

  cat > "$template" <<'YAML'
connections:
  prod:
    protocol: postgres
    host: localhost
    port: 5432
    database: app
    username: postgres
    password: postgres
  dev:
    protocol: postgres
    host: localhost
    port: 5432
    database: dev
    username: postgres
    password: postgres
YAML

  printf '#!%s\n' "$bash_path" > "$fakebin/op"
  cat >> "$fakebin/op" <<'SH'
set -euo pipefail
if [[ "${OP_FAIL_IF_CALLED:-}" == "1" ]]; then
  echo "op should not have been called" >&2
  exit 99
fi
echo "op $*" >> "$CALL_LOG"
in_file=""
out_file=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    inject)
      shift
      ;;
    --in-file)
      in_file="$2"
      shift 2
      ;;
    --out-file)
      out_file="$2"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done
cp "$in_file" "$out_file"
SH

  printf '#!%s\n' "$bash_path" > "$fakebin/yq"
  cat >> "$fakebin/yq" <<'SH'
set -euo pipefail
echo "yq $*" >> "$CALL_LOG"
config="${@: -1}"
grep -E '^  [A-Za-z0-9_-]+:' "$config" | sed 's/^  //; s/:.*//'
SH

  printf '#!%s\n' "$bash_path" > "$fakebin/fzf"
  cat >> "$fakebin/fzf" <<'SH'
set -euo pipefail
echo "fzf $*" >> "$CALL_LOG"
cat > /dev/null
if [[ -n "${FZF_EXIT:-}" ]]; then
  exit "$FZF_EXIT"
fi
printf '%s\n' "${FZF_CHOICE:-prod}"
SH

  printf '#!%s\n' "$bash_path" > "$fakebin/usql"
  cat >> "$fakebin/usql" <<'SH'
set -euo pipefail
echo "usql $*" >> "$CALL_LOG"
printf 'USQL_ARGS:'
for arg in "$@"; do
  printf ' [%s]' "$arg"
done
printf '\n'
SH

  chmod +x "$fakebin/op" "$fakebin/yq" "$fakebin/fzf" "$fakebin/usql"

  export CALL_LOG="$call_log"
  export USQL_CONFIG_TEMPLATE="$template"
  export USQL_WRAPPER_RUNTIME_DIR="$runtime_base"
  export OP_BIN="$fakebin/op"
  export YQ_BIN="$fakebin/yq"
  export FZF_BIN="$fakebin/fzf"
  export USQL_BIN="$fakebin/usql"
}

teardown() {
  rm -rf "$test_dir"
}

file_mode() {
  stat -c '%a' "$1" 2>/dev/null || stat -f '%Lp' "$1"
}

@test "--list injects a missing runtime config and prints connection names" {
  run "$USQLP_BIN" --list

  [ "$status" -eq 0 ]
  [ "${lines[0]}" = "prod" ]
  [ "${lines[1]}" = "dev" ]
  [ -f "$runtime_base/usql/config.yaml" ]
  [ "$(file_mode "$runtime_base/usql")" = "700" ]
  [ "$(file_mode "$runtime_base/usql/config.yaml")" = "600" ]
  grep -q '^op inject ' "$call_log"
}

@test "--help includes agent-friendly non-interactive usage" {
  run "$USQLP_BIN" --help

  [ "$status" -eq 0 ]
  [[ "$output" == *"Agent/non-interactive usage:"* ]]
  [[ "$output" == *"usqlp <connection> -c 'select 1'"* ]]
  [[ "$output" == *"Raw usql remains available for direct DSNs and scripts."* ]]
}

@test "--list reuses an existing runtime config without injecting" {
  mkdir -p "$runtime_base/usql"
  chmod 700 "$runtime_base/usql"
  cat > "$runtime_base/usql/config.yaml" <<'YAML'
connections:
  cached:
    protocol: postgres
YAML
  chmod 600 "$runtime_base/usql/config.yaml"
  export OP_FAIL_IF_CALLED=1

  run "$USQLP_BIN" --list

  [ "$status" -eq 0 ]
  [ "$output" = "cached" ]
  if grep -q '^op ' "$call_log"; then
    false
  fi
}

@test "--refresh reinjects an existing runtime config" {
  mkdir -p "$runtime_base/usql"
  echo 'stale: true' > "$runtime_base/usql/config.yaml"

  run "$USQLP_BIN" --refresh

  [ "$status" -eq 0 ]
  [[ "$output" == "Refreshed: $runtime_base/usql/config.yaml" ]]
  grep -q '^op inject ' "$call_log"
  grep -q '^connections:' "$runtime_base/usql/config.yaml"
}

@test "no arguments pick a connection with fzf and execute usql" {
  export FZF_CHOICE=dev

  run "$USQLP_BIN"

  [ "$status" -eq 0 ]
  [[ "$output" == "USQL_ARGS: [--config] [$runtime_base/usql/config.yaml] [dev]" ]]
  grep -q '^fzf ' "$call_log"
}

@test "arguments bypass fzf and are forwarded to usql" {
  run "$USQLP_BIN" prod -c 'select 1'

  [ "$status" -eq 0 ]
  [[ "$output" == "USQL_ARGS: [--config] [$runtime_base/usql/config.yaml] [prod] [-c] [select 1]" ]]
  if grep -q '^fzf ' "$call_log"; then
    false
  fi
}

@test "fzf cancellation exits without running usql" {
  export FZF_EXIT=130

  run "$USQLP_BIN"

  [ "$status" -eq 130 ]
  if grep -q '^usql ' "$call_log"; then
    false
  fi
}

@test "missing template exits with a useful error" {
  export USQL_CONFIG_TEMPLATE="$test_dir/missing.yaml.tpl"

  run "$USQLP_BIN" --list

  [ "$status" -eq 1 ]
  [[ "$output" == "Missing template: $test_dir/missing.yaml.tpl" ]]
}

@test "tmp fallback rejects a symlinked runtime base" {
  unset USQL_WRAPPER_RUNTIME_DIR
  unset XDG_RUNTIME_DIR
  export TMPDIR="$test_dir/tmp"
  mkdir -p "$TMPDIR" "$test_dir/target"
  ln -s "$test_dir/target" "$TMPDIR/usql-runtime-$UID"

  run "$USQLP_BIN" --list

  [ "$status" -eq 1 ]
  [[ "$output" == "Refusing unsafe runtime directory: $TMPDIR/usql-runtime-$UID" ]]
}
