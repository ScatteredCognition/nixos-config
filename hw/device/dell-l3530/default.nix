# default.nix
# Run sudo nixos-generate-config --show-hardware-config --no-filesystems > ./hardware-configuration.nix to update the hw config of this device
{ config, ... }:

{
  # Set hostname
  networking.hostName = "dell-nixos";

  # Set root disk
  disko.devices.disk.main.device = "/dev/nvme0n1";

  # import hardware-configuration.nix
  imports = [
    ./hardware-configuration.nix
    ../../gpu/intel # for intel iGPU
  ];
}
