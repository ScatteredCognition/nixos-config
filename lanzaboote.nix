# lanzeboot.nix
{ pkgs, lib, ... }:

{
  environment.systemPackages = [
    pkgs.sbctl
    pkgs.e2fsprogs
  ]; # key management + status tool

  boot.loader.systemd-boot.enable = lib.mkForce false; # Lanzaboote replaces this module
  boot.lanzaboote = {
    enable = true;
    pkiBundle = "/var/lib/sbctl"; # where sbctl stores your Secure Boot keys
  };
}
