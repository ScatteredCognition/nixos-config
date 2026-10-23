# default.nix
{ ... }:

{
  users.mutableUsers = false;
  services.userborn.enable = true;

  imports = [
    ./faeizmahrus.nix
    ./guest.nix
  ];
}
