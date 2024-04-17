{
  pkgs,
  lib,
  config,
  ...
}: let
  homeCfgs = config.home-manager.users;
  homeSharePaths = lib.mapAttrsToList (_: v: "${v.home.path}/share") homeCfgs;
  vars = ''XDG_DATA_DIRS="$XDG_DATA_DIRS:${lib.concatStringsSep ":" homeSharePaths}" GTK_USE_PORTAL=0'';

  sway-kiosk = command: "${lib.getExe pkgs.sway} --unsupported-gpu --config ${pkgs.writeText "kiosk.config" ''
    output * bg #000000 solid_color
    xwayland disable
    input "type:touchpad" {
      tap enabled
    }
    exec '${vars} ${command}; ${pkgs.sway}/bin/swaymsg exit'
  ''}";
in {
  users.extraUsers.greeter = {
    # packages = [
    #   gtkTheme.package
    #   iconTheme.package
    # ];
    # For caching and such
    home = "/tmp/greeter-home";
    createHome = true;
  };

  programs.regreet = {
    enable = true;
    settings = {
      GTK = {
        # Whether to use the dark theme
        application_prefer_dark_theme = true;
        icon_theme_name = "Papirus";
        font_name = "JetBrainsMono 16";
      };
      background = {
        path = "/etc/_wallpapers/milad-fakurian-nY14Fs8pxT8-unsplash.jpg";
        fit = "Cover";
      };
    };
  };

  environment.etc = {
    _wallpapers.source = ../../../homes/_modules/desktop/common/wallpapers;
  };

  services.greetd = {
    enable = true;
    settings.default_session.command = sway-kiosk (lib.getExe config.programs.regreet.package);
  };
}
