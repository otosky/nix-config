{pkgs, ...}: {
  imports = [
    ./swaylock.nix
    ./waybar.nix
    ./wofi.nix
    ./swaync.nix
  ];

  xdg.mimeApps.enable = true;

  home.packages = with pkgs; [
    grim
    gtk3 # For gtk-launch
    imv
    mimeo
    pulseaudio
    slurp
    waypipe
    wf-recorder
    wl-clipboard
    wl-mirror
    xdg-utils
    ydotool
    libnotify
  ];

  home.sessionVariables = {
    MOZ_ENABLE_WAYLAND = 1;
    QT_QPA_PLATFORM = "wayland";
    LIBSEAT_BACKEND = "logind";
  };

  xdg.portal.extraPortals = [pkgs.xdg-desktop-portal-wlr];
}
