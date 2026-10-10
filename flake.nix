# flake.nix

{
  # Description
  description = "ScatteredCognition's NixOS flake";

  # Inputs
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    # disko
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix-flatpak
    nix-flatpak = {
      url = "github:gmodena/nix-flatpak";
      inputs.nixpkgs.follows = "nixpkgs";
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
    {
      self,
      nixpkgs,
      ...
    }@inputs: # destructures the previous variables into individual keys

    # Define modules
    let
      inherit (nixpkgs) lib;

      # hardware-specific stuff
      hwModule = {
        # hardware-configuration.nix
        hardwareConfiguration = [ ./hw/hardware-configuration.nix ];

        # add other hw stuff here
        # Extra hardware
        extra = [ ./hw/fprint/chipsailing-cs9711.nix ];

        # Dell Latitude 3530
        dell-l3530 = [
          ./hw/device/dell-l3530.nix
          ./hw/gpu/intel.nix
        ];
      };

      # Hosts, devices to deploy on
      hostModule = {
        generic = hwModule.hardwareConfiguration;
        dell-l3530 = hwModule.hardwareConfiguration ++ hwModule.dell-l3530 ++ hwModule.extra;
      };

      # Language stuff
      langModule = {
        bn_BD = [ ./misc/lang/bn_BD.nix ];
      };

      # Inputs module
      # Needed for baseModule as they pull in disko deps and whatnot
      inputsModule = [
        inputs.disko.nixosModules.disko
        inputs.nix-flatpak.nixosModules.nix-flatpak
      ];

      # base
      ## Hardware/host-specific stuff separated out into hostModule
      baseModule =
        inputsModule # Include flake inputs
        ++ [
          # System stuff
          ./system/base.nix
          ./system/disko.nix
          ./system/zram.nix
          ./system/tpm2.nix
          ./system/users.nix

          # dirty cache writeback fix
          ./misc/fixes/disk-writeback-fix.nix
          ./misc/karg-tweaks.nix
        ];

      # base-desktop
      desktopModule =
        let
          commonDesktopModules = [
            ./system/base-desktop.nix # base-desktop core
            ./apps/apps.nix # Apps etc
            ./apps/app-fixes.nix
            ./apps/app-extras.nix
            ./apps/weylus.nix
            ./misc/fixes/usr-fix.nix # Misc
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

      # Define baseSystem, an abstraction over baseModule for ease of use in mkSystem
      baseSystem =
        baseModule # Bare basic system config

        # Add language support here
        # English is added by default
        ++ langModule.bn_BD;

    in

    # Main system config part
    {
      nixosConfigurations = lib.listToAttrs (
        lib.mapCartesianProduct
          (
            { host, desktop }:
            lib.nameValuePair "${host}-${desktop}" (
              nixpkgs.lib.nixosSystem {
                specialArgs = { inherit inputs; };
                modules = baseSystem ++ desktopModule.${desktop} ++ hostModule.${host};
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
