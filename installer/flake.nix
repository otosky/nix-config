{
  description = "Minimal NixOS installation media";
  inputs = {
    nixpkgs.url = "nixpkgs/23.11";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    disko,
  }: {
    nixosConfigurations = {
      customIso = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
          disko.nixosModules.disko

          ({pkgs, ...}: {
            nix = {
              settings = {
                experimental-features = [
                  "nix-command"
                  "flakes"
                  "repl-flake"
                ];
              };
            };
            environment.systemPackages = with pkgs; [
              neovim
              git
              sops
              gnupg
              just
              disko.packages.${system}.disko
            ];

            boot.swraid.enable = nixpkgs.lib.mkForce false;
            disko.enableConfig = false;
          })
        ];
      };
    };
  };
}
