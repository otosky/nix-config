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
      jetbrains.idea-ultimate
      jetbrains.pycharm-professional
      go
    ];
  };

  programs = {
    opam.enable = true;
    bat.enable = true;
    gh.enable = true;
  };
}
