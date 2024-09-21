{
  pkgs,
  lib,
  config,
  ...
}: let
  swaylock = "${config.programs.swaylock.package}/bin/swaylock";
  hyprctl = "${config.wayland.windowManager.hyprland.package}/bin/hyprctl";
  lockTime = 10 * 60; # TODO: configurable desktop (10 min)/laptop (4 min)
  img = "/etc/_wallpapers/milad-fakurian-nY14Fs8pxT8-unsplash.jpg";
in {
  services.swayidle = {
    enable = true;
    systemdTarget = "graphical-session.target";
    timeouts =
      # Lock screen
      [
        {
          timeout = lockTime;
          command = "${swaylock} -defF -i ${img}";
        }
        {
          timeout = lockTime + 120;
          command = "${hyprctl} dispatch dpms off";
          resumeCommand = "${hyprctl} dispatch dpms on";
        }
        {
          timeout = 600;
          command = "systemctl suspend";
        }
      ];
    events = [
      {
        event = "lock";
        command = "${swaylock} -defF -i ${img}";
      }
      {
        event = "after-resume";
        command = "${hyprctl} dispatch dpms on";
      }
      {
        event = "before-sleep";
        command = "${swaylock} -defF -i ${img}";
      }
    ];
  };
}
