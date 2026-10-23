# zram.nix
{ lib, ... }:

{
  zramSwap = {
    enable = lib.mkDefault true;
    # best compression ratio for zram
    algorithm = "zstd";
    # zram device size = 50% of RAM
    memoryPercent = 50;
  };

  # explicitly no disk-backed swap
  swapDevices = [ ];
}
