# generic.nix
# Run `sudo nixos-generate-config --no-filesystems --show-hardware-config > ./hw/device/generic.nix`
# or run `./cp-hwconf.sh`
{ lib, ... }:
{
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # Set hostname
  networking.hostName = "generic-nixos";
}
