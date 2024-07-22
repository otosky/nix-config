{
  lib,
  config,
  pkgs,
  ...
}: let
  hyprland = pkgs.inputs.hyprland.hyprland.override {wrapRuntimeDeps = false;};
  xdph = pkgs.inputs.hyprland.xdg-desktop-portal-hyprland.override {inherit hyprland;};
  # wallpaper = "$HOME/.wallpapers/milad-fakurian-JrMz6hVQeu4-unsplash.jpg";
in {
  imports = [
    ./common
    ./common/wayland-wm
  ];

  xdg.portal = {
    extraPortals = [xdph];
    configPackages = [hyprland];
  };

  home.packages = with pkgs; [
    inputs.hyprwm-contrib.grimblast
    # hyprslurp
    # hyprpicker
    firefox
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    package = hyprland;
    systemd = {
      enable = true;
      # Same as default, but stop graphical-session too
      extraCommands = lib.mkBefore [
        "systemctl --user stop graphical-session.target"
        "systemctl --user start hyprland-session.target"
      ];
    };

    settings = {
      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 1;
      };
      # exec = ["${pkgs.swaybg}/bin/swaybg -i ${wallpaper} --mode fill"];

      decoration = {
        rounding = 10;
        blur = {
          enabled = true;
          size = 2;
          passes = 2;
          new_optimizations = true;
          xray = false;
        };
        drop_shadow = true;
        shadow_range = 4;
        shadow_render_power = 3;
      };

      animations = {
        enabled = true;
        bezier = [
          "easein,0.11, 0, 0.5, 0"
          "easeout,0.5, 1, 0.89, 1"
          "easeinout,0.45, 0, 0.55, 1"
          "easeinback,0.36, 0, 0.66, -0.56"
          "easeoutback,0.34, 1.56, 0.64, 1"
          "easeinoutback,0.68, -0.6, 0.32, 1.6"
        ];

        animation = [
          "border,1,3,easeout"
          "workspaces,1,2,easeoutback,slide"
          "windowsIn,1,3,easeoutback,slide"
          "windowsOut,1,3,easeinback,slide"
          "windowsMove,1,3,easeoutback"
          "fadeIn,1,3,easeout"
          "fadeOut,1,3,easein"
          "fadeSwitch,1,3,easeinout"
          "fadeShadow,1,3,easeinout"
          "fadeDim,1,3,easeinout"
          "fadeLayersIn,1,3,easeoutback"
          "fadeLayersOut,1,3,easeinback"
          "layersIn,1,3,easeoutback,slide"
          "layersOut,1,3,easeinback,slide"
        ];
      };

      bind =
        [
          "SUPER, F, exec, firefox"
          "SUPER, B, exec, brave"
          ", Print, exec, grimblast copy area"
          "SUPER, return, exec, [float;tile] wezterm start --always-new-process"
          "SUPER, M, exec, wlogout --protocol layer-shell"

          "SUPER, 1, workspace, 1"
          "SUPER, 2, workspace, 2"
          "SUPER, 3, workspace, 3"
          "SUPER, 4, workspace, 4"
          "SUPER, 5, workspace, 5"
          "SUPER, 6, workspace, 6"
          "SUPER, 7, workspace, 7"
          "SUPER, 8, workspace, 8"
          "SUPER, 9, workspace, 9"

          "SUPER SHIFT, 1, movetoworkspace, 1"
          "SUPER SHIFT, 2, movetoworkspace, 2"
          "SUPER SHIFT, 3, movetoworkspace, 3"
          "SUPER SHIFT, 4, movetoworkspace, 4"
          "SUPER SHIFT, 5, movetoworkspace, 5"
          "SUPER SHIFT, 6, movetoworkspace, 6"
          "SUPER SHIFT, 7, movetoworkspace, 7"
          "SUPER SHIFT, 8, movetoworkspace, 8"
          "SUPER SHIFT, 9, movetoworkspace, 9"
        ]
        ++
        # LAUNCHER
        (
          let
            wofi = lib.getExe config.programs.wofi.package;
          in
            lib.optionals config.programs.wofi.enable [
              "SUPER,x,exec,${wofi} -S drun -x 10 -y 10 -W 25% -H 60%"
              "SUPER,d,exec,${wofi} -S run"
            ]
        )
        ++
        # LOCKSCREEN
        (
          let
            swaylock = lib.getExe config.programs.swaylock.package;
          in
            lib.optionals config.programs.swaylock.enable [
              ",XF86Launch5,exec,${swaylock} -S --grace 2"
              ",XF86Launch4,exec,${swaylock} -S --grace 2"
              "SUPER SHIFT,L,exec,${swaylock} -S --grace 2"
            ]
        );
    };
  };
}
