{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./ai-agents
    ./lazygit
  ];

  home = {
    packages = with pkgs;
      lib.optionals pkgs.stdenv.isLinux [
        agor
      ]
      ++ [
        coursier
        delta
        age
        gnumake
        go
        uv
        stable.pdm
        duckdb
        stable.pgcli
        changie

        claude-code
        codex
        gemini-cli
        opencode
        pi-coding-agent

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
