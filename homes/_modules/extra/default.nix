{
  config,
  pkgs,
  inputs,
  lib,
  ...
}: {
  home = {
    packages = with pkgs; [
      jetbrains.idea-ultimate
      jetbrains.pycharm-professional

      brave
      libreoffice
      zoom-us

      gimp-with-plugins

      calibre
      sonixd
      jellyfin-media-player
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
    ];

    sessionVariables.NIXOS_OZONE_WL = "1";
  };

  services = {
    syncthing = {
      enable = true;
    };
  };
}
