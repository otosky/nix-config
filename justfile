ssh_dir := "/mnt/persist/etc/ssh"

# list all recipes
default:
    just --list

# validate nix flake
lint:
    nix flake check

setup:
    curl -sSL https://keybase.io/otosky/pgp_keys.asc | gpg --import

init-keys:
    sudo mkdir -p {{ ssh_dir }}
    cp /etc/ssh/ssh_host_ed25519* {{ ssh_dir }}
    nix-shell --run "sudo ssh-to-age -private-key -i {{ ssh_dir }}/ssh_host_ed25519_key -o {{ ssh_dir }}/age_key.txt"
    nix-shell --run "sudo ssh-to-age -i {{ ssh_dir }}/ssh_host_ed25519_key.pub -o {{ ssh_dir }}/pub.txt"

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

