#!/usr/bin/env bash
set -euo pipefail

compose_file="dev/usql-postgres/compose.yaml"
template_file="dev/usql-postgres/config.yaml.tpl"
op_copy_file="dev/usql-postgres/op-inject-copy"
justfile="justfile"

[[ -f "$compose_file" ]]
[[ -f "$template_file" ]]
[[ -x "$op_copy_file" ]]

grep -q 'postgres:' "$compose_file"
grep -q '15432:5432' "$compose_file"
grep -q 'POSTGRES_DB: usql_test' "$compose_file"
grep -q 'POSTGRES_USER: usql' "$compose_file"
grep -q 'POSTGRES_PASSWORD: usql' "$compose_file"

grep -q '^  local_postgres:' "$template_file"
grep -q 'host: localhost' "$template_file"
grep -q 'port: 15432' "$template_file"
grep -q 'database: usql_test' "$template_file"
grep -q 'username: usql' "$template_file"
grep -q 'password: usql' "$template_file"
grep -q 'sslmode: disable' "$template_file"

grep -q '^usql-postgres-up:' "$justfile"
grep -q '^usql-postgres-test:' "$justfile"
grep -q '^usql-postgres-down:' "$justfile"
grep -q 'OP_BIN="$PWD/dev/usql-postgres/op-inject-copy"' "$justfile"
