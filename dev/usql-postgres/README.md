# Local usql Postgres test database

This directory contains a disposable Postgres container and a matching `usqlp`
template for testing Neovim/Dadbod SQL workflows.

```sh
just usql-postgres-up
just usql-postgres-test
USQL_CONFIG_TEMPLATE="$PWD/dev/usql-postgres/config.yaml.tpl" \
  OP_BIN="$PWD/dev/usql-postgres/op-inject-copy" \
  nvim test.sql
```

Inside Neovim, use the custom Dadbod adapter with:

```vim
:DB usqlp:local_postgres select * from widgets;
```

Or set the default database for a window:

```vim
:let w:db = 'usqlp:local_postgres'
```

Then run visual selections or commands with `:DB`.

```sh
USQL_CONFIG_TEMPLATE="$PWD/dev/usql-postgres/config.yaml.tpl" \
  OP_BIN="$PWD/dev/usql-postgres/op-inject-copy" \
  usqlp local_postgres
just usql-postgres-down
```

The test connection is intentionally local-only:

- host: `localhost`
- port: `15432`
- database: `usql_test`
- username: `usql`
- password: `usql`
