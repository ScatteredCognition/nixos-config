# disko.nix
# sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko/latest -- --mode destroy,format,mount ./disko.nix

{
  disko.devices = {
    disk = {
      main = {
        device = "/dev/nvme0n1"; # use lsblk to find this
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "2G";
              type = "EF00"; # EFI System Partition GUID
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ]; # only root can read ESP contents
              };
            };
            luks = {
              size = "100%"; # everything left after the ESP
              content = {
                type = "luks";
                name = "cryptroot"; # becomes /dev/mapper/cryptroot
                settings = {
                  allowDiscards = true; # forward TRIM to the SSD through LUKS
                };
                content = {
                  type = "btrfs";
                  extraArgs = [
                    "-L"
                    "nixos"
                    "-f"
                  ]; # -f forces format even if signatures exist
                  subvolumes = {
                    "@root" = {
                      mountpoint = "/";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                      ];
                    };
                    "@home" = {
                      mountpoint = "/home";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                      ];
                    };
                    "@nix" = {
                      mountpoint = "/nix";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                      ];
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
