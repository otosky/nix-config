{
  config,
  pkgs,
  inputs,
  lib,
  ...
}: let
in {
  home = {
    packages = with pkgs; [
      jetbrains.idea
      jetbrains.pycharm

      brave
      libreoffice
      zoom-us

      gimp-with-plugins

      calibre
      sonixd
      # has an outdated qtwebengine dependency
      #jellyfin-media-player
      vlc

      slack
      discord

      caligula
      makemkv
      whipper

      # needs to be on stable until https://github.com/logseq/logseq/issues/10851 is fixed
      stable.logseq

      qmk
      gcc-arm-embedded

      arduino-ide
      arduino-cli

      code-cursor

      unrar-free
    ];

    sessionVariables.NIXOS_OZONE_WL = "1";
  };

  services = {
    syncthing = {
      enable = true;
    };
  };
}
