{
  pkgs,
  lib,
  config,
  ...
}: {
  imports = [
    ./hyprlock.nix
    ./hypridle.nix
    ./waybar.nix
    ./wofi.nix
    ./swaync.nix
  ];

  home = {
    packages = with pkgs; [
      grim
      gtk3 # For gtk-launch
      imv
      mimeo
      networkmanager_dmenu
      pulseaudio
      slurp
      waypipe
      wf-recorder
      wl-clipboard
      wl-mirror
      xdg-utils
      ydotool
      libnotify
      brightnessctl
    ];
    sessionVariables = {
      MOZ_ENABLE_WAYLAND = 1;
      QT_QPA_PLATFORM = "wayland";
      LIBSEAT_BACKEND = "logind";
    };
  };

  xdg = {
    mimeApps.enable = true;
    portal.extraPortals = [pkgs.xdg-desktop-portal-wlr];
    configFile."networkmanager-dmenu/config.ini".text = ''
      [dmenu]
      dmenu_command = ${lib.getExe config.programs.wofi.package} -d -i

      [editor]
      gui_if_available = false
    '';
    desktopEntries = {
      sleek = {
        name = "sleek";
        exec = "/home/olivertosky/bin/sleek-2.0.14.AppImage";
        terminal = false;
        type = "Application";
        comment = "todo.txt manager for Linux, Windows and MacOS, free and open-source (FOSS)";
        categories = ["ProjectManagement"];
      };
    };
  };
}
