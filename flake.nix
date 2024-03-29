{
  description = "Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    home-manager,
    ...
  }: {
    defaultPackage = {
      x86_64-linux = home-manager.defaultPackage.x86_64-linux;
      aarch64-darwin = home-manager.defaultPackage.aarch64-darwin;
    };

    homeConfigurations = {
      "olivertosky@ot-framework" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        modules = [
          ./home/users/olivertosky/home.nix
        ];
      };
    };
  };
}
