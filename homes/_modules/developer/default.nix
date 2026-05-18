{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ../ai
    ./ai-agents
    ./lazygit
  ];

  home = {
    file.".config/usql/config.yaml.tpl".text = ''
      connections:
        local_postgres:
          protocol: postgres
          host: localhost
          port: 5432
          database: postgres
          username: postgres
          password: postgres
          options:
            sslmode: disable
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
