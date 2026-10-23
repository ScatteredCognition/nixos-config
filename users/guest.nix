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
    hashedPassword = ""; # set blank password for user

    # User shell
    shell = pkgs.fish;
  };
}
