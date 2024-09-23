{
  config,
  pkgs,
  lib,
  ...
}: {
  home = {
    packages = with pkgs; [
      _1password
      _1password-gui
      brave
      libreoffice
      zoom-us

      # https://github.com/montchr/dotfield/blob/78de8ff316ccb2d34fd98cd9bfd3bfb5ad775b0e/home/profiles/desktop/common.nix #L17
      # HACK: The `gap` plugin is broken upstream, and I have no intent on using it anyway.
      # FIXME: Remove the override when merged: <https://github.com/NixOS/nixpkgs/pull/295257>
      (pkgs.gimp-with-plugins.override {
        plugins = let
          # <https://github.com/Scrumplex/nixpkgs/blob/cca25fd345f2c48de66ff0a950f4ec3f63e0420f/pkgs/applications/graphics/gimp/wrapper.nix#L5C1-L6C99>
          allPlugins = lib.filter (pkg: lib.isDerivation pkg && !pkg.meta.broken or false) (
            lib.attrValues pkgs.gimpPlugins
          );
          pred = pkg: pkg != pkgs.gimpPlugins.gimp && pkg != pkgs.gimpPlugins.gap;
        in
          lib.filter pred allPlugins;
      })

      calibre
      logseq
      sonixd

      slack
      discord
      appimage-run
    ];

    sessionVariables.NIXOS_OZONE_WL = "1";
  };
  services = {
    syncthing = {
      enable = true;
    };
  };
}
