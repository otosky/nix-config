{
  lib,
  pkgs,
  ...
}: {
  imports = [
    ../_modules/base
    ../_modules/linux
    ../_modules/terminal
    ../_modules/terminal/foot
    ../_modules/desktop/hyprland.nix
    ../_modules/kubernetes
    ../_modules/developer
    ../_modules/extra
  ];

  modules = {
    shell = {
      mise = {
        enable = true;
        package = pkgs.mise;
      };
    };
  };

  wayland.windowManager.hyprland.settings.input = {
    kb_options = "ctrl:nocaps";
  };
}
