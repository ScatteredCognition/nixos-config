# users.nix

{ config, pkgs, ... }:

{
  users.users.faeizmahrus = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    hashedPassword = "";
    packages = with pkgs; [ ];

    shell = pkgs.fish;
  };
}
