{
  lib,
  config,
  ...
}: let
  hostname = config.networking.hostName;
in {
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/${hostname}";
      fsType = "btrfs";
      options = [
        "subvol=root"
        "compress=zstd"
      ];
    };

    "/nix" = {
      device = "/dev/disk/by-label/${hostname}";
      fsType = "btrfs";
      options = [
        "subvol=nix"
        "noatime"
        "compress=zstd"
      ];
    };

    "/persist" = {
      device = "/dev/disk/by-label/${hostname}";
      fsType = "btrfs";
      options = [
        "subvol=persist"
        "compress=zstd"
      ];
      neededForBoot = true;
    };

    "/swap" = {
      device = "/dev/disk/by-label/${hostname}";
      fsType = "btrfs";
      options = [
        "subvol=swap"
        "noatime"
      ];
    };
  };
}
