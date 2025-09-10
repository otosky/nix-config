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
    ];
  };

  programs = {
    opam.enable = true;
    bat.enable = true;
    gh.enable = true;
  };
}
