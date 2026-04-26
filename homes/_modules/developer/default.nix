{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./claude-code
    ./lazygit
  ];

  home = {
    packages = with pkgs; [
      coursier
      delta
      age
      gnumake
      go
      uv
      pdm
      duckdb
      pgcli
      changie

      agor
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
