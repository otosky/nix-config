{
  config,
  pkgs,
  ...
}: {
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

      cocogitto

      erlang_28
      beamMinimal28Packages.elixir
    ];
  };

  programs = {
    opam.enable = true;
    bat.enable = true;
    gh.enable = true;
  };
}
