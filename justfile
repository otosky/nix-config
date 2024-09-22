# list all recipes
default:
    just --list

# validate nix flake
lint:
    nix flake check

setup:
    curl -sSL https://keybase.io/otosky/pgp_keys.asc | gpg --import

# build custom installer iso
build-iso:
    cd installer && nix build .#nixosConfigurations.customIso.config.system.build.isoImage

# set up drives & partitions
disko-init host:
    sudo disko -m disko --flake .#{{host}}

# mount initialized drives to filesystem
disko-mount host:
    sudo disko -m mount --flake .#{{host}}

# init nix install on a mounted filesystem
install host:
    sudo nixos-install --root /mnt --flake .#{{host}}

# rebuild flake
rebuild host:
    sudo nixos-rebuild switch --flake .#{{host}}

