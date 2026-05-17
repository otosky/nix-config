# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example'
{pkgs}: {
  # example = pkgs.callPackage ./example { };
  usqlp = pkgs.callPackage ./usqlp {};
  agor = pkgs.callPackage ./agor {};
  cymbal = pkgs.callPackage ./cymbal {};
  superdirt = pkgs.callPackage ./superdirt {};
}
