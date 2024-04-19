# nix-config

Declarative configuration of my machines & dotfiles.

> [!WARNING]
> Still a work-in-progress!

## Installation
```sh
git clone https://github.com/otosky/nix-config
cd nix-config
nixos-install --root /mnt --flake .#ot-desktop
```

## Rebuilds
```sh
sudo nixos-rebuild switch --flake .#ot-desktop
home-manager switch --flake .#olivertosky@ot-desktop
```


