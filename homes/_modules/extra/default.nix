{
  config,
  pkgs,
  lib,
  ...
}: {
  home.packages = with pkgs; [
    _1password
    _1password-gui
    brave
    gimp-with-plugins
    libreoffice
    zoom-us
  ];
}
