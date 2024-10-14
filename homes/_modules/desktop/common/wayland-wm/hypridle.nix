{
  pkgs,
  lib,
  config,
  ...
}: let
  hyprlock = "${config.programs.hyprlock.package}/bin/hyprlock";
  hyprctl = "${config.wayland.windowManager.hyprland.package}/bin/hyprctl";
in {
  services.hypridle = {
    enable = true;

    settings = {
      general = {
        lock_cmd = "${hyprlock}";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "${hyprctl} dispatch dpms on";
      };

      listener = [
        {
          timeout = 600;
          on-timeout = "loginctl lock-session";
        }
        {
          timeout = 720;
          on-timeout = "${hyprctl} dispatch dpms off";
          on-resume = "${hyprctl} dispatch dpms on";
        }
        {
          timeout = 1800;
          on-timeout = "systemctl suspend";
        }
      ];
    };
  };
}
