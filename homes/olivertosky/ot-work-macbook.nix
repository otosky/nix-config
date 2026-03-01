{
  lib,
  pkgs,
  ...
}: {
  imports = [
    ../_modules/base
    ../_modules/terminal
    ../_modules/developer
  ];

  home.username = "oliver.tosky";

  modules = {
    shell = {
      mise = {
        enable = true;
        package = pkgs.mise;
      };
    };
  };
}
