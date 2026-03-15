{
  config,
  pkgs,
  ...
}: {
  imports = [
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

      claude-code
      gemini-cli
      opencode

      cocogitto
      git-town

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
