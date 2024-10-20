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
