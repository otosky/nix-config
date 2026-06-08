# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example'
{pkgs}: {
  # example = pkgs.callPackage ./example { };
  usqlp = pkgs.callPackage ./usqlp {};
  cymbal = pkgs.callPackage ./cymbal {};
  superdirt = pkgs.callPackage ./superdirt {};
}
