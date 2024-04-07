{
  lib,
  pkgs,
  ...
}: {
  imports = [
    ../_modules/base
    ../_modules/terminal
  ];
  # Disable impermanence
  home.persistence = lib.mkForce {};
  modules = {
    shell = {
      mise = {
        enable = true;
        package = pkgs.unstable.mise;
      };
    };
  };
}
