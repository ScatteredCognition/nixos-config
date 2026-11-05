# faeizmahrus.nix
{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:

{
  users.users.faeizmahrus = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    initialHashedPassword = "$6$eYzqbH8iKuFk5PMT$ZRm33dU3TxgD0IX7UcAqYuzFj3PTXLHtt9wm795gW3pkV9hhnJhvTNAhtSRtJ.REKRfeIaWOhOM9KWiK4jmch1";

    # User shell
    shell = pkgs.fish;

    # syncthing
    services.syncthing = {
      enable = true;
      openDefaultPorts = true;
      user = "faeizmahrus";
      group = "users";
      dataDir = config.users.users.faeizmahrus.home;
      configDir = "${config.users.users.faeizmahrus.home}/.config/syncthing";
    };
  };
}
