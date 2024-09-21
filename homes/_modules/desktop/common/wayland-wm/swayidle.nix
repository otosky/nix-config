{
  pkgs,
  lib,
  config,
  ...
}: let
  swaylock = "${config.programs.swaylock.package}/bin/swaylock";
  hyprctl = "${config.wayland.windowManager.hyprland.package}/bin/hyprctl";
  lockTime = 1 * 60; # TODO: configurable desktop (10 min)/laptop (4 min)
in {
  services.swayidle = {
    enable = true;
    systemdTarget = "graphical-session.target";
    extraArgs = [
      "-d"
    ];
    timeouts =
      # Lock screen
      [
        {
          timeout = lockTime;
          command = "${swaylock} -defF";
        }
        {
          timeout = 180;
          command = "${hyprctl} dispatch dpms off";
          resumeCommand = "${hyprctl} dispatch dpms on";
        }
      ];
    events = [
      {
        event = "lock";
        command = "${swaylock} -defF";
      }
      {
        event = "after-resume";
        command = "${hyprctl} dispatch dpms on";
      }
      {
        event = "before-sleep";
        command = "${swaylock} -defF";
      }
    ];
  };
}
