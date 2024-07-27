# nix-config

Declarative configuration of my machines & dotfiles.

> [!WARNING]
> Still a work-in-progress!

## Setup

The following requires custom boot media built from manifests under
`installer/`.

To build the install-usb media, run

```sh
just build-iso
```

### Init Drives

```sh
echo -n "<luks-secret-key>" > /tmp/secret.key
# set up the drive partitions
sudo just disko-init <host>
# mount the drives so that you can perform nix installation
sudo just disko-mount <host>
```

### Init Install

```sh
git clone https://github.com/otosky/nix-config
cd nix-config
sudo nixos-install --root /mnt --flake .#ot-desktop
```

## Rebuilds
```sh
sudo nixos-rebuild switch --flake .#ot-desktop
home-manager switch --flake .#olivertosky@ot-desktop
```


