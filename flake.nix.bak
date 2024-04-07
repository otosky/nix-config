{
  description = "Home Manager configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    nixGL = {
      url = "github:guibou/nixgl";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    nixpkgs,
    nixGL,
    home-manager,
    ...
  } @ inputs: let
    allowUnfree = true;
    allowUnfreePredicate = _: true;
  in {
    defaultPackage = {
      x86_64-linux = home-manager.defaultPackage.x86_64-linux;
      aarch64-darwin = home-manager.defaultPackage.aarch64-darwin;
    };

    homeConfigurations = {
      "olivertosky@ot-framework" = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          system = "x86_64-linux";
          config.allowUnfree = allowUnfree;
          config.allowUnfreePredicate = allowUnfreePredicate;
          overlays = [nixGL.overlay];
        };
        extraSpecialArgs = {inherit inputs;};
        modules = [
          ./home/users/olivertosky/home.nix
          ({...}: {
            nixGLPrefix = "${nixGL.packages.x86_64-linux.nixGLIntel}/bin/nixGLIntel ";
          })
        ];
      };

      "olivertosky@ot-desktop" = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          system = "x86_64-linux";
          config.allowUnfree = allowUnfree;
          config.allowUnfreePredicate = allowUnfreePredicate;
          overlays = [nixGL.overlay];
        };
        extraSpecialArgs = {inherit inputs;};
        modules = [
          ./home/users/olivertosky/home.nix
          ({...}: {
            nixGLPrefix = "${nixGL.packages.x86_64-linux.nixGLIntel}/bin/nixGLIntel ";
          })
        ];
      };
    };
  };
}
