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
    antigravity-nix = {
      # Enable switch
      enable = lib.mkEnableOption "antigravity-nix (patched w/o fhsEnv sandboxing)" // {
        default = true;
      };

      # Browser package to shim as google-chrome-stable for Antigravity /browser
      browserPackage = lib.mkOption {
        type = lib.types.package;
        default = pkgs.google-chrome;
        description = "Browser package to shim as google-chrome-stable for Antigravity /browser";
      };

      # Path to the browser's DevToolsActivePort file
      devToolsActivePort = lib.mkOption {
        type = lib.types.str;
        default = "%h/.config/google-chrome/DevToolsActivePort";
        description = "Path to the browser's DevToolsActivePort file for Antigravity Puppeteer connection";
      };

      # Browser presets for reference:
      # Google Chrome (default):
      #   custom.antigravity-nix.browserPackage = pkgs.google-chrome;
      #   custom.antigravity-nix.devToolsActivePort = "%h/.config/google-chrome/DevToolsActivePort";
      # Chromium (with Widevine):
      #   custom.antigravity-nix.browserPackage = pkgs.chromium.override { enableWideVine = true; };
      #   custom.antigravity-nix.devToolsActivePort = "%h/.config/chromium/DevToolsActivePort";
      # Brave:
      #   custom.antigravity-nix.browserPackage = pkgs.brave;
      #   custom.antigravity-nix.devToolsActivePort = "%h/.config/BraveSoftware/Brave-Browser/DevToolsActivePort";
      # Vivaldi:
      #   custom.antigravity-nix.browserPackage = pkgs.vivaldi;
      #   custom.antigravity-nix.devToolsActivePort = "%h/.config/vivaldi/DevToolsActivePort";
      # Ungoogled Chromium:
      #   custom.antigravity-nix.browserPackage = pkgs.ungoogled-chromium;
      #   custom.antigravity-nix.devToolsActivePort = "%h/.config/chromium/DevToolsActivePort";
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
