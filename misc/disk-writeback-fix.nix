# disk-writeback-fix.nix
{ lib, ... }:

{
  boot.kernel.sysctl = {
    "vm.dirty_bytes" = lib.mkDefault (256 * 1024 * 1024); # Hard flush at 256MB
    "vm.dirty_background_bytes" = lib.mkDefault (16 * 1024 * 1024); # Start flushing at 16MB
    "vm.dirty_expire_centisecs" = lib.mkDefault 100; # Expire dirty pages every second
    "vm.dirty_writeback_centisecs" = lib.mkDefault 300; # Wake flush threads every 3s
  };
}
