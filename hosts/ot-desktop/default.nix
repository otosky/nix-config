{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    inputs.hardware.nixosModules.common-cpu-intel
    inputs.hardware.nixosModules.common-gpu-amd
    inputs.hardware.nixosModules.common-pc-ssd

    ./hardware-configuration.nix

    ../common/base
    ../common/users/olivertosky

    ../common/optional/greetd.nix
    ../common/optional/pipewire.nix
    ../common/optional/quietboot.nix
    ../common/optional/1password.nix
    ../common/optional/bluetooth.nix
  ];

  networking = {
    hostName = "ot-desktop";
    useDHCP = false;
    networkmanager = {
      enable = true;
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

  environment.systemPackages = with pkgs; [
    android-tools
  ];

  programs = {
    dconf.enable = true;
    kdeconnect.enable = true;
  };

  hardware = {
    graphics.enable = true;
    opentabletdriver.enable = true;
  };

  services.fprintd.enable = true;

  system.stateVersion = "23.11";
}
