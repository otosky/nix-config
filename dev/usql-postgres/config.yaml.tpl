init: |
  \pset pager on

connections:
  local_postgres:
    protocol: postgres
    host: localhost
    port: 15432
    database: usql_test
    username: usql
    password: usql
    options:
      sslmode: disable
