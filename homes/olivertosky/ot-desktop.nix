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
  ];
  # Disable impermanence
  home.persistence = lib.mkForce {};
  modules = {
    shell = {
      mise = {
        enable = true;
        package = pkgs.mise;
      };
    };
  };
}
