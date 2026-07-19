# zram.nix

{
  zramSwap = {
    enable = true;
    algorithm = "zstd"; # best compression ratio for zram
    memoryPercent = 50; # zram device size = 50% of RAM
  };

  swapDevices = [ ]; # explicitly no disk-backed swap
}
