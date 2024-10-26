{
  lib,
  pkgs,
  ...
}: {
  imports = [
    ../_modules/base
    ../_modules/terminal
    ../_modules/desktop/hyprland.nix
    ../_modules/kubernetes
    ../_modules/developer
    ../_modules/extra
    ../_modules/daw
  ];

  modules = {
    shell = {
      mise = {
        enable = true;
        package = pkgs.mise;
      };
    };
  };

  programs = {
    obs-studio.enable = true;
  };
}
