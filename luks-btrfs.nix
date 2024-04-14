{
  disk = {
    ssd = {
      type = "disk";
      device = "/dev/sda1";
      content = {
        type = "table";
        format = "gpt";
        partitions = {
          ESP = {
            priority = 1;
            name = "ESP";
            start = "1MiB";
            end = "512MiB";
            bootable = true;
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              options = [
                "defaults"
              ];
            };
          };

          luks = {
            end = "100%";
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
}
