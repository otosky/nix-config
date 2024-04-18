{
  config,
  pkgs,
  lib,
  ...
}: {
  home.packages = [
    pkgs._1password
    pkgs._1password-gui
  ];
}
