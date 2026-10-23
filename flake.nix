# flake.nix

{
  # Description
  description = "ScatteredCognition's NixOS flake";

  # Inputs
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixos-hardware.url = "github:ScatteredCognition/nixos-hardware/dell-latitude-3530"; # Temporary, change to upstream when commit merged

    # disko
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix-flatpak
    nix-flatpak = {
      url = "github:gmodena/nix-flatpak";
      # inputs.nixpkgs.follows = "nixpkgs";
    };

    # zen browser
    zen-browser-flake = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix-gaming
    nix-gaming = {
      url = "github:fufexan/nix-gaming";
      # inputs.nixpkgs.follows = "nixpkgs"; # forces compile from source
    };

    # antigravity-nix
    antigravity-nix = {
      url = "github:jacopone/antigravity-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # Outputs
  outputs =
    inputs:

    # Define modules
    let
      lib = inputs.nixpkgs.lib;

      # hardware-specific stuff
      hwModule = {
        # generic
        generic = [ ./hw/device/generic ];

        # Dell Latitude 3530
        dell-l3530 = [
          inputs.nixos-hardware.nixosModules.dell-latitude-3530
          ./hw/device/dell-l3530
        ];

        # Extra hardware
        extra = [ ./hw/extra ];
      };

      # Hosts, devices to deploy on
      hostModule = {
        generic = hwModule.generic;
        dell-l3530 = hwModule.dell-l3530 ++ hwModule.extra;
      };

      # base
      ## Hardware/host-specific stuff separated out into hostModule
      baseModule = [
        ./system # System + language stuff
        ./users # Users

        # dirty cache writeback fix
        ./misc/fixes/disk-writeback-fix.nix
        ./misc/tweaks/karg-tweaks.nix
      ];

      # base-desktop
      desktopModule =
        let
          commonDesktopModules = [
            ./desktop/base-desktop.nix # base-desktop core
            ./desktop/lang-extra # extra language stuff
            ./apps # apps etc
            ./misc/fixes/usr-fix.nix # usr fix
          ];
        in
        rec {
          nogui = [ ]; # no desktop

          # Desktops
          desktop = gnome; # default target for desktop
          gnome = commonDesktopModules ++ [ ./desktop/gnome-desktop.nix ];
          kde = commonDesktopModules ++ [ ./desktop/kde-desktop.nix ];
          cosmic = commonDesktopModules ++ [ ./desktop/cosmic-desktop.nix ];
        };

    in

    # Main system config part
    {
      nixosConfigurations = lib.listToAttrs (
        lib.mapCartesianProduct
          (
            { host, desktop }:
            lib.nameValuePair "${host}-${desktop}" (
              lib.nixosSystem {
                specialArgs = { inherit inputs; };
                modules = baseModule ++ desktopModule.${desktop} ++ hostModule.${host};
              }
            )
          )
          {
            host = lib.attrNames hostModule;
            desktop = lib.attrNames desktopModule;
          }
      );
    };
}
