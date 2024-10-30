{
  outputs,
  config,
  lib,
  pkgs,
  inputs,
  osConfig,
  ...
}: let
  # Dependencies
  cat = "${pkgs.coreutils}/bin/cat";
  cut = "${pkgs.coreutils}/bin/cut";
  find = "${pkgs.findutils}/bin/find";
  grep = "${pkgs.gnugrep}/bin/grep";
  pgrep = "${pkgs.procps}/bin/pgrep";
  tail = "${pkgs.coreutils}/bin/tail";
  wc = "${pkgs.coreutils}/bin/wc";
  xargs = "${pkgs.findutils}/bin/xargs";
  timeout = "${pkgs.coreutils}/bin/timeout";
  ping = "${pkgs.iputils}/bin/ping";

  jq = "${pkgs.jq}/bin/jq";
  systemctl = "${pkgs.systemd}/bin/systemctl";
  journalctl = "${pkgs.systemd}/bin/journalctl";
  playerctl = "${pkgs.playerctl}/bin/playerctl";
  playerctld = "${pkgs.playerctl}/bin/playerctld";
  pavucontrol = "${pkgs.pavucontrol}/bin/pavucontrol";
  wofi = "${pkgs.wofi}/bin/wofi";

  fontSize =
    if osConfig.networking.hostName == "ot-framework"
    then "18"
    else "12";

  # Function to simplify making waybar outputs
  jsonOutput = name: {
    pre ? "",
    text ? "",
    tooltip ? "",
    alt ? "",
    class ? "",
    percentage ? "",
  }: "${pkgs.writeShellScriptBin "waybar-${name}" ''
    set -euo pipefail
    ${pre}
    ${jq} -cn \
      --arg text "${text}" \
      --arg tooltip "${tooltip}" \
      --arg alt "${alt}" \
      --arg class "${class}" \
      --arg percentage "${percentage}" \
      '{text:$text,tooltip:$tooltip,alt:$alt,class:$class,percentage:$percentage}'
  ''}/bin/waybar-${name}";

  hasSway = config.wayland.windowManager.sway.enable;
  sway = config.wayland.windowManager.sway.package;
  hasHyprland = config.wayland.windowManager.hyprland.enable;
  hyprland = config.wayland.windowManager.hyprland.package;
in {
  # Let it try to start a few more times
  systemd.user.services.waybar = {
    Unit.StartLimitBurst = 30;
  };
  programs.waybar = {
    enable = true;
    systemd.enable = true;
    settings = {
      primary = {
        layer = "top";
        position = "top";
        mode = "dock";
        modules-left = [
          "hyprland/workspaces"
        ];

        modules-center = [
          "clock"
        ];

        modules-right = [
          "cpu"
          "memory"
          "pulseaudio"
          "battery"
          "network"
          "custom/hostname"
        ];

        clock = {
          interval = 1;
          format = "{:%m/%d %H:%M:%S}";
          format-alt = "{:%Y-%m-%d %H:%M:%S %z}";
          on-click-left = "mode";
          tooltip-format = ''
            <big>{:%Y %B}</big>
            <tt><small>{calendar}</small></tt>'';
        };

        cpu = {
          format = "  {usage}%";
        };
        memory = {
          format = "  {}%";
          interval = 5;
        };

        pulseaudio = {
          format = "{icon}  {volume}%";
          format-muted = "   0%";
          format-icons = {
            headphone = "󰋋";
            headset = "󰋎";
            portable = "";
            default = [
              ""
              ""
              ""
            ];
          };
          on-click = pavucontrol;
        };

        "custom/hostname" = {
          exec = "echo $USER@$HOSTNAME";
          on-click = "${systemctl} --user restart waybar";
        };
      };
    };
    style = ''
      * {
        border: none;
        font-family: JetBrains Mono, "Font Awesome 5 Free";
        font-size: ${fontSize}px;
        font-weight: bold;
        min-height: 0;
      }

      window#waybar {
        background-color: transparent;
      }

      window > box {
        background: rgba(26, 27, 38, 1);
        border-radius: 10px;
        min-width: 46px;
        margin: 10px;
        background-clip: border-box;
        box-shadow: 0 0 0 1px rgba(0, 0, 0, 0.25), 0 1px 3px 1px rgba(0, 0, 0, 0.25),
          0 2px 6px 2px rgba(0, 0, 0, 0.25);
      }

      #taskbar {
        background: #1a1b26;
        padding: 0 0.6em;
        margin-right: 10px;
        margin-left: 4px;
        margin-top: 5px;
        margin-bottom: 5px;
        border-radius: 10px;
        color: #ebdbb2;
      }

      #taskbar button {
        border-radius: 10px;
        background: #24283b;
        color: #a89984;
        margin-right: 6px;
      }

      #taskbar button.minimized {
        border-radius: 10px;
        background: #24283b;
        color: #a89984;
      }

      #taskbar button.active {
        border-radius: 10px;
        background: #4e635b;
        color: #ebdbb2;
      }

      #disk {
        color: #89ddff;
      }

      #memory {
        color: #c792ea;
      }

      #cpu {
        color: #ffcb6b;
      }

      #battery {
        color: #c3e88d;
      }

      #temperature {
        color: #c792ea;
      }

      #temperature {
        color: #c792ea;
      }

      #temperature.critical {
        background-color: #f07178;
        color: #1a1b26;
      }

      #pulseaudio {
        color: #ffcb6b;
      }

      #pulseaudio.muted {
        background-color: #f07178;
      }

      @keyframes gradient {
        0% {
          background-position: 0% 50%;
        }
        50% {
          background-position: 100% 50%;
        }
        100% {
          background-position: 0% 50%;
        }
      }

      #workspaces,
      #clock,
      #custom-power,
      #window,
      #disk,
      #cpu,
      #memory,
      #battery,
      #network,
      #tray {
        padding: 0 5px;
        margin: 2px;
      }

      .modules-left,
      .modules-center,
      .modules-right {
        background-color: #24283b;
        margin: 5px 5px 5px 5px;
        border-radius: 10px;
        background-clip: padding-box;
      }

      #workspaces button {
        padding: 0 4px;
        min-width: 18px;
        color: #82aaff;
      }

      #workspaces button:hover {
        background-color: rgba(0, 0, 0, 0.2);
      }

      #workspaces button.active {
        color: #c792ea;
      }

      #workspaces button.focused {
        color: #c792ea;
      }

      #workspaces button.urgent {
        color: #f07178;
      }

      #memory {
        color: #c792ea;
      }

      #clock {
        color: #82aaff;
      }

      #mode {
        color: #ffcb6b;
      }

      #window {
        color: #c3e88d;
        /*color: #b0bec5;*/
        background-color: transparent;
      }

      #custom-power {
        color: #f25287;
        background-color: #1a1b26;
      }


      @keyframes blink {
        to {
          background-color: #1a1b26;
          color: #f07178;
        }
      }

      #network {
        color: #c792ea;
      }

      #network.disconnected {
        background-color: #f07178;
        color: #1a1b26;
      }
    '';
  };
}
