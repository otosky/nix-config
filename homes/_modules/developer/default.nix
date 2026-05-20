{
  config,
  pkgs,
  lib,
  ...
}: let
  defaultPspgConfig = pkgs.writeText "pspgconf" ''
    custom_theme_name = "tokyonight"
    direct_color = true
  '';

  defaultPspgTheme = pkgs.writeText "pspg-theme-tokyonight" ''
    template = 1
    template_menu = 1

    background = #c0caf5, #1a1b26
    data = #c0caf5, #1a1b26
    data* = #c0caf5, #16161e
    label = #7aa2f7, #1f2335, bold
    label* = #7aa2f7, #24283b, bold
    border = #3b4261, #1a1b26
    border* = #3b4261, #16161e
    row_number = #565f89, #1a1b26
    selected_area = #c0caf5, #364a82, bold
    footer = #a9b1d6, #1f2335

    cursor_data = #1a1b26, #7aa2f7, bold
    cursor_border = #1a1b26, #7aa2f7, bold
    cursor_label = #1a1b26, #7aa2f7, bold
    cursor_row_number = #1a1b26, #7aa2f7, bold
    cursor_selected_area = #1a1b26, #bb9af7, bold
    cursor_footer = #1a1b26, #7dcfff, bold
    cross_cursor = #1a1b26, #bb9af7, bold
    cross_cursor_border = #1a1b26, #bb9af7, bold

    status_bar = #c0caf5, #1f2335
    title = #bb9af7, #1f2335, bold
    prompt_bar = #7dcfff, #1f2335
    info_bar = #9ece6a, #1f2335
    input_bar = #c0caf5, #1f2335
    error_bar = #f7768e, #1f2335, bold

    bookmark = #e0af68, #1a1b26, bold
    bookmark_border = #e0af68, #1a1b26
    cursor_bookmark = #1a1b26, #e0af68, bold

    matched_pattern = #1a1b26, #e0af68, bold
    matched_line = #c0caf5, #292e42
    matched_line_border = #e0af68, #292e42
    matched_pattern_cursor = #1a1b26, #ff9e64, bold
    matched_line_vertical_cursor = #1a1b26, #bb9af7, bold
    matched_line_vertical_cursor_border = #1a1b26, #bb9af7, bold

    scrollbar_arrows = #7aa2f7, #1f2335
    scrollbar_background = #3b4261, #1a1b26
    scrollbar_slider = #7aa2f7, #1a1b26
    scrollbar_active_slider = #bb9af7, #1a1b26
  '';

  defaultUsqlConfigTemplate = pkgs.writeText "usql-config.yaml.tpl" ''
    # Copy this file per-host and replace the placeholder 1Password references.
    init: |
      \set PAGER pspg
      \pset pager on

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
    file = {
      ".pspgconf".source = defaultPspgConfig;
      ".pspg_theme_tokyonight".source = defaultPspgTheme;
    };

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
        pspg
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
