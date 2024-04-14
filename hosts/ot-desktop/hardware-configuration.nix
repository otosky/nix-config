{
  imports = [
    # ../common/optional/ephemeral-btrfs.nix
    # ../common/optional/encrypted-root.nix
    ../common/optional/disko.nix
  ];

  boot = {
    initrd = {
      availableKernelModules = [
        "nvme"
        "xhci_pci"
        "ahci"
        "usb_storage"
        "usbhid"
        "sd_mod"
      ];
      kernelModules = ["kvm-intel"];
    };
    loader = {
      systemd-boot = {
        enable = true;
        consoleMode = "max";
      };
      efi.canTouchEfiVariables = true;
    };
  };

  # fileSystems = {
  #   "/boot" = {
  #     device = "/dev/disk/by-label/ESP";
  #     fsType = "vfat";
  #   };
  # };
  #
  # swapDevices = [
  #   {
  #     device = "/swap/swapfile";
  #     size = 8196;
  #   }
  # ];

  nixpkgs.hostPlatform.system = "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = true;
}
