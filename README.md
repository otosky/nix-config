# nix-config

Declarative configuration of my machines & dotfiles.

## Setup

### Prerequisite

```sh
git clone https://github.com/otosky/nix-config
cd nix-config
```

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
just disko-init <host>
# mount the drives so that you can perform nix installation
just disko-mount <host>
# import gpg key
just setup
# copy ssh keys from live-media to nixos fs
just init-keys
```

> [!CAUTION]
> I need to figure out a way to get sops-nix to recognize my gpg key
> from a yubikey.  Right now this blocks a successful bootstrap install.
> 
> To get this working at the moment, I use ssh-to-age to convert the new
> ed25519 key to an age key, update the host key in .sops.yaml, and then
> re-encrypt the password file at ./hosts/common/secrets.yaml.
> 
> This is an admittedly clunky process.

### Init Install

```sh
just install <host>
```

## Rebuilds
```sh
just rebuild <host>
```

```sh
# just home-manager modules
home-manager switch --flake .#olivertosky@ot-desktop
```

