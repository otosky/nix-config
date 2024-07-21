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
}
