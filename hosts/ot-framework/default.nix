{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    inputs.hardware.nixosModules.common-cpu-intel
    inputs.hardware.nixosModules.common-pc-ssd
    inputs.hardware.nixosModules.framework-13th-gen-intel

    ./hardware-configuration.nix

    ../common/base
    ../common/users/olivertosky

    ../common/optional/greetd.nix
    ../common/optional/pipewire.nix
    ../common/optional/quietboot.nix
    ../common/optional/1password.nix
  ];

  networking = {
    hostName = "ot-framework";
    useDHCP = false;

    networkmanager = {
      enable = true;
    };

    wg-quick.interfaces = {
      wg0 = {
        address = ["10.66.5.2/32"];
        dns = ["10.67.0.3"];
        generatePrivateKeyFile = true;
        privateKeyFile = "/persist/etc/wireguard/privatekey";

        peers = [
          {
            publicKey = "NgjelohY50W5asSSmaw4lL3A3RtJQNVXX3JU2hmU0xA=";
            allowedIPs = ["0.0.0.0/0"];
            endpoint = "ot-eh.casa:51820";
            persistentKeepalive = 15;
          }
        ];
      };
    };
  };

  boot = {
    kernelPackages = pkgs.linuxKernel.packages.linux_zen;
    binfmt.emulatedSystems = [
      "aarch64-linux"
      "i686-linux"
    ];
    initrd = {
      supportedFilesystems = ["nfs"];
      kernelModules = ["nfs"];
    };
  };

  services = {
    fwupd.enable = true;
    # we need fwupd 1.9.7 to downgrade the fingerprint sensor firmware
    fwupd.package =
      (import (builtins.fetchTarball {
          url = "https://github.com/NixOS/nixpkgs/archive/bb2009ca185d97813e75736c2b8d1d8bb81bde05.tar.gz";
          sha256 = "sha256:003qcrsq5g5lggfrpq31gcvj82lb065xvr7bpfa8ddsw8x4dnysk";
        }) {
          inherit (pkgs) system;
        })
      .fwupd;
  };

  environment.systemPackages = with pkgs; [
    fw-ectool
    powertop
    lact
  ];

  programs = {
    adb.enable = true;
    dconf.enable = true;
    kdeconnect.enable = true;
  };

  hardware = {
    graphics.enable = true;
    opentabletdriver.enable = true;
  };

  system.stateVersion = "23.11";
}
