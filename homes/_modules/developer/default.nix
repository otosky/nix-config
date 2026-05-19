{
  config,
  pkgs,
  lib,
  ...
}: let
  defaultUsqlConfigTemplate = pkgs.writeText "usql-config.yaml.tpl" ''
    # Copy this file per-host and replace the placeholder 1Password references.
    connections:
      mysql_example:
        protocol: mysql
        host: "{{ op://vault/mysql/host }}"
        port: 3306
        database: "{{ op://vault/mysql/database }}"
        username: "{{ op://vault/mysql/username }}"
        password: "{{ op://vault/mysql/password }}"

      postgresql_example:
        protocol: postgres
        host: "{{ op://vault/postgresql/host }}"
        port: 5432
        database: "{{ op://vault/postgresql/database }}"
        username: "{{ op://vault/postgresql/username }}"
        password: "{{ op://vault/postgresql/password }}"
        options:
          sslmode: require

      sqlite_example: "sq:{{ op://vault/sqlite/database-path }}"

      duckdb_example: "duckdb:{{ op://vault/duckdb/database-path }}"

      # Athena uses an S3 output location as the URL and query parameters for
      # region/catalog DB/workgroup. AWS credentials can come from the environment
      # or shared AWS config.
      athena_example: "athena://{{ op://vault/athena/output-bucket }}/{{ op://vault/athena/output-prefix }}?region={{ op://vault/athena/region }}&db={{ op://vault/athena/database }}&workgroupName={{ op://vault/athena/workgroup }}"

      # SQL Server Kerberos uses go-mssqldb integrated auth parameters.
      # Requires a usql build that imports the krb5 integrated auth provider.
      mssql_kerberos_example: "sqlserver://{{ op://vault/mssql-kerberos/username }}@{{ op://vault/mssql-kerberos/host }}:1433/{{ op://vault/mssql-kerberos/database }}?authenticator=krb5&krb5-configfile={{ op://vault/mssql-kerberos/krb5-configfile }}&krb5-credcachefile={{ op://vault/mssql-kerberos/krb5-credcachefile }}"

      # Snowflake uses gosnowflake DSN parameters. The privateKey value is
      # base64 URL-encoded PKCS#8 DER key material, not a local key file path.
      # Convert a .p8 file with:
      # openssl pkcs8 -topk8 -inform PEM -outform DER -in rsa_key.p8 -nocrypt | openssl base64 -A | tr '+/' '-_'
      snowflake_rsa_key_example: "snowflake://{{ op://vault/snowflake-rsa/username }}@{{ op://vault/snowflake-rsa/account }}.snowflakecomputing.com/{{ op://vault/snowflake-rsa/database }}?authenticator=SNOWFLAKE_JWT&privateKey={{ op://vault/snowflake-rsa/private-key-base64url }}&warehouse={{ op://vault/snowflake-rsa/warehouse }}&role={{ op://vault/snowflake-rsa/role }}"

      snowflake_externalbrowser_example: "snowflake://{{ op://vault/snowflake-browser/username }}@{{ op://vault/snowflake-browser/account }}.snowflakecomputing.com/{{ op://vault/snowflake-browser/database }}?authenticator=EXTERNALBROWSER&warehouse={{ op://vault/snowflake-browser/warehouse }}&role={{ op://vault/snowflake-browser/role }}"
  '';
in {
  imports = [
    ../ai
    ./ai-agents
    ./lazygit
  ];

  home = {
    activation.installMutableUsqlTemplate = lib.hm.dag.entryAfter ["writeBoundary"] ''
      template_dir="$HOME/.config/usql"
      template_path="$template_dir/config.yaml.tpl"

      mkdir -p "$template_dir"
      if [ ! -e "$template_path" ] || [ -L "$template_path" ]; then
        rm -f "$template_path"
        install -m 600 ${defaultUsqlConfigTemplate} "$template_path"
      fi
    '';

    packages = with pkgs;
      lib.optionals pkgs.stdenv.isLinux [
        agor
      ]
      ++ [
        sqlit-tui
        usql
        usqlp
        coursier
        delta
        age
        gnumake
        go
        jq
        ast-grep
        uv
        bun
        pnpm
        stable.pdm
        duckdb
        stable.pgcli
        changie
        _1password-cli

        claude-code
        codex
        gemini-cli
        opencode
        pi-coding-agent
        cymbal

        cocogitto
        git-town
        git-spice

        erlang_28
        beamMinimal28Packages.elixir

        awscli2
        google-cloud-sdk
        azure-cli
        opentofu
      ];
  };

  programs = {
    opam.enable = true;
    bat.enable = true;
    gh.enable = true;
  };
}
