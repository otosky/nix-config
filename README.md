# nix-config

Declarative configuration of my machines & dotfiles.

> [!WARNING]
> Still a work-in-progress!

```sh
git clone https://github.com/otosky/nix-config
cd nix-config

sudo nixos-rebuild switch --flake .#ot-desktop
home-manager switch --flake .#olivertosky@ot-desktop
```

