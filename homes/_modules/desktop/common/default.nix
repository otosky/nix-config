{
  lib,
  pkgs,
  config,
  ...
}: {
  imports = [
    ./font.nix
  ];
  home = {
    file = {
      ".wallpapers/" = {
        recursive = true;
        source = ./wallpapers;
      };
    };
  };
  xdg.portal.enable = true;
  xresources.properties = {
    "Xft.dpi" = 96;
  };
}
