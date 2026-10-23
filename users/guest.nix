# guest.nix
{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:

{
  users.users.guest = {
    isNormalUser = true;
    HashedPassword = "";

    # User shell
    shell = pkgs.fish;
  };
}
