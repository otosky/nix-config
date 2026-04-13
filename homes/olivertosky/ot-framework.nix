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
    voxtype = {
      package = pkgs.voxtype-onnx;
      engine = "parakeet";
      model = "parakeet-tdt-0.6b-v3";
    };
  };

  wayland.windowManager.hyprland.settings.input = {
    kb_options = "ctrl:nocaps";
  };
}
