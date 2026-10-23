# default.nix
{ ... }:

{
  imports = [
    ./base.nix
    ./disko.nix
    ./tpm2.nix
    ./zram.nix
  ];
}
