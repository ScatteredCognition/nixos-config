# users.nix

{ pkgs, ... }:

{
  users.users = {
    faeizmahrus = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      hashedPassword = "";

      # User shell
      shell = pkgs.fish;
    };

    guest = {
      isNormalUser = true;
      hashedPassword = "";

      # User shell
      shell = pkgs.zsh;
    };
  };
}
