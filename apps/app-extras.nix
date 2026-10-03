# app-extras.nix
# https://github.com/0xc000022070/zen-browser-flake
# https://github.com/fufexan/nix-gaming

{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.custom = {
    # Create toggles
    # nix-gaming
    nix-gaming.enable = lib.mkEnableOption "nix-gaming (precompiled binaries via Cachix)" // {
      default = true;
    };
    # zen-browser-flake
    zen-browser-flake.enable = lib.mkEnableOption "zen-browser-flake (precompiled)" // {
      default = true;
    };
    # antigravity-nix
    antigravity-nix.enable = lib.mkEnableOption "antigravity-nix (precompiled)" // {
      default = true;
    };
  };

  config = {
    # Enable nix-gaming cachix cache
    nix.settings = {
      substituters = [ "https://nix-gaming.cachix.org" ];
      trusted-public-keys = [ "nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4=" ];
    };
  };
}
