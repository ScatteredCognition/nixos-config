# services.nix
{ pkgs, ... }:

{
  services.syncthing = {
    enable = true;
    openDefaultPorts = true;
  };
}
