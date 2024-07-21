build-iso:
    cd installer && nix build .#nixosConfigurations.customIso.config.system.build.isoImage

disko-mount host:
    disko -m mount --flake .#{{host}}

disko-init host:
    disko -m disko --flake .#{{host}}

lint:
    nix flake check
