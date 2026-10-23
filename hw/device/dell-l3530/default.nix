# default.nix
# Run sudo nixos-generate-config --show-hardware-config --no-filesystems > ./hardware-configuration.nix to update the hw config of this device
{ config, ... }:

{
  # Set hostname
  networking.hostName = "dell-nixos";

  # import hardware-configuration.nix
  imports = [
    ./hardware-configuration.nix
    ../../gpu/intel # for intel iGPU
  ];
}
