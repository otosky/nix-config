# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example'
{pkgs}: let
  usqlp = pkgs.callPackage ./usqlp {};
in {
  # example = pkgs.callPackage ./example { };
  inherit usqlp;
  agor = pkgs.callPackage ./agor {};
  cymbal = pkgs.callPackage ./cymbal {};
  superdirt = pkgs.callPackage ./superdirt {};
}
