# default.nix
{ ... }:

{
  imports = [
    ./apps.nix
    ./app-fixes.nix
    ./app-extras.nix
  ];
}
