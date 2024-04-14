{
  disko.device = {
    disk = {
      ssd = {
        type = "disk";
        device = "/dev/sda";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              name = "ESP";
              size = "512M";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [
                  "defaults"
                ];
              };
            };

            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "crypted";
                settings = {
                  allowDiscards = true;
                };
                keyFile = "/tmp/secret.key";
                content = {
                  type = "btrfs";
                  extraArgs = ["-f"];
                  subvolumes = {
                    "/root" = {
                      mountpoint = "/";
                      mountOptions = ["compress=zstd"];
                    };
                    "/nix" = {
                      mountOptions = ["compress=zstd" "noatime"];
                    };
                    "/persist" = {
                      mountOptions = ["compress=zstd" "noatime"];
                    };
                    "/swap" = {
                      mountOptions = ["noatime"];
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
