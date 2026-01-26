{
  config,
  pkgs,
  inputs,
  lib,
  ...
}: let
  # Override pycdio to skip failing tests
  python3 = pkgs.python3.override {
    packageOverrides = self: super: {
      pycdio = super.pycdio.overridePythonAttrs (old: {
        doCheck = false;
      });
    };
  };
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
      # Use whipper with patched python3
      (whipper.override { inherit python3; })

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
