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

    # lanzaboot
    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix-flatpak
    nix-flatpak = {
      url = "github:gmodena/nix-flatpak";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # zen browser
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # Outputs
  outputs =
    {
      self,
      nixpkgs,
      zen-browser,
      ...
    }@inputs: # destructures the previous variables into individual keys

    # Define modules
    let
      inherit (nixpkgs) lib;

      # mkSystem
      mkSystem =
        modules:
        nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = modules;
        };

      # for subtracting lists and converting modules to lists
      subtractLists = nixpkgs.lib.lists.subtractLists;
      # toList = nixpkgs.lib.lists.toList;

      # lanzaboote
      # So removeModule isn't dependant on a hardcoded path
      lanzabooteModule = [ ./system/lanzaboote.nix ];

      # hardware-specific stuff
      hwModule = {
        hardwareConfiguration = [ ./hw/hardware-configuration.nix ];
        dell-l3530 = [
          ./hw/device/dell-l3530.nix
          ./hw/gpu/intel.nix
        ];
        # add other hw stuff here
      };

      # Language stuff
      langModule = {
        bn_BD = [ ./misc/lang/bn_BD.nix ];
      };

      # Inputs module
      inputsModule = [
        inputs.disko.nixosModules.disko
        inputs.lanzaboote.nixosModules.lanzaboote
        inputs.nix-flatpak.nixosModules.nix-flatpak
      ];

      # base
      baseModule =
        (lanzabooteModule ++ hwModule.hardwareConfiguration) # Include Lanzaboote and hwconf
        ++ inputsModule # Include flake inputs
        ++ [
          # System stuff
          ./system/base.nix
          ./system/disko.nix
          ./system/zram.nix
          ./system/tpm2.nix
          ./system/users.nix

          # dirty cache writeback fix
          ./misc/disk-writeback-fix.nix
        ];

      # base-desktop
      desktopModule =
        let
          commonDesktopModules = [
            ./system/base-desktop.nix # base-desktop core
            ./apps/apps.nix # Apps etc
            ./apps/app-fixes.nix
            ./misc/usr-fix.nix # Misc
          ];
        in
        rec {
          nogui = [ ]; # no desktop

          # Desktops
          default = gnome;
          desktop = default;
          gnome = commonDesktopModules ++ [ ./desktop/gnome-desktop.nix ];
          kde = commonDesktopModules ++ [ ./desktop/kde-desktop.nix ];
          cosmic = commonDesktopModules ++ [ ./desktop/cosmic-desktop.nix ];
        };

    in
    {
      nixosConfigurations =
        let
          # base without any DE/GUI
          base = {
            # Install config
            Install = (
              (subtractLists lanzabooteModule baseModule) # base module minus lanzaboote
              # Add language support here
              ++ langModule.bn_BD
            );

            # System config w/ lanzaboote
            System = (
              baseModule # base module
              # Add language support here
              ++ langModule.bn_BD
            );
          };

        in
        # Merges all the generated configs together
        lib.mergeAttrsList [

          (lib.concatMapAttrs (name: modules: {
            # Generates base-{nogui, desktop, gnome, kde, cosmic} and their -install variants
            "base-${name}" = mkSystem (base.System ++ modules);
            "base-${name}-install" = mkSystem (base.Install ++ modules);

            # Generates the base variants with Dell Latitude 3530 patches
            "dell-l3530-${name}" = mkSystem (base.System ++ modules ++ hwModule.dell-l3530);
            "dell-l3530-${name}-install" = mkSystem (base.Install ++ modules ++ hwModule.dell-l3530);
          }) desktopModule)
        ];
    };
}
