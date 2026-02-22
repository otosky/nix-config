{
  description = "otosky Nix Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
    systems.url = "github:nix-systems/default-linux";

    # Home manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hardware.url = "github:nixos/nixos-hardware";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    impermanence.url = "github:nix-community/impermanence";
    nix-colors.url = "github:misterio77/nix-colors";

    sops-nix = {
      url = "github:mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
    };

    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    nixpkgs-stable,
    flake-utils,
    systems,
    ...
  } @ inputs: let
    inherit (self) outputs;
    lib = nixpkgs.lib // home-manager.lib;
    forEachSystem = f: lib.genAttrs (import systems) (system: f pkgsFor.${system});
    pkgsFor = lib.genAttrs (import systems) (
      system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        }
    );
  in {
    # Your custom packages
    # Accessible through 'nix build', 'nix shell', etc
    packages = forEachSystem (pkgs: import ./pkgs {inherit pkgs;});
    # Formatter for your nix files, available through 'nix fmt'
    # Other options beside 'alejandra' include 'nixpkgs-fmt'
    formatter = forEachSystem (pkgs: pkgs.alejandra);

    # Your custom packages and modifications, exported as overlays
    overlays = import ./overlays {inherit inputs outputs;};
    # Reusable nixos modules you might want to export
    # These are usually stuff you would upstream into nixpkgs
    nixosModules = import ./modules/nixos;
    # Reusable home-manager modules you might want to export
    # These are usually stuff you would upstream into home-manager
    homeModules = import ./modules/home-manager;

    # NixOS configuration entrypoint
    # Available through 'nixos-rebuild --flake .#your-hostname'
    nixosConfigurations = {
      ot-desktop = lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [
          inputs.disko.nixosModules.disko
          ./hosts/ot-desktop
        ];
      };
      ot-framework = lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [
          inputs.disko.nixosModules.disko
          ./hosts/ot-framework
        ];
      };
    };

    # Standalone home-manager configuration entrypoint
    # Available through 'home-manager --flake .#your-username@your-hostname'
    homeConfigurations = {
      "olivertosky@ot-desktop" = lib.homeManagerConfiguration {
        pkgs = pkgsFor.x86_64-linux;
        extraSpecialArgs = {inherit inputs outputs;};
        modules = [
          ./homes/olivertosky/ot-desktop.nix
        ];
      };
      "olivertosky@ot-framework" = lib.homeManagerConfiguration {
        pkgs = pkgsFor.x86_64-linux;
        extraSpecialArgs = {inherit inputs outputs;};
        modules = [
          ./homes/olivertosky/ot-framework.nix
        ];
      };
      "oliver.tosky@DMAC24-T1699DT90K" = lib.homeManagerConfiguration {
        pkgs = pkgsFor.aarch64-darwin;
        extraSpecialArgs = {inherit inputs outputs;};
        modules = [
          ./homes/olivertosky/ot-work-macbook.nix
        ];
      };
    };

    devShells = forEachSystem (pkgs: {
      default = with pkgs;
        mkShell {
          buildInputs = with pkgs; [
            gcc
            python311
            python311Packages.ruff
            git
            neovim

            sops
            ssh-to-age
            gnupg
            age
            uv
          ];
        };
    });
  };
}
