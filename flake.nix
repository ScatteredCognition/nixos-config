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
        dell-l3530 = [ ./hw/dell-l3530.nix ];
        # add other hw stuff here
      };

      # Language stuff
      langModule = {
        bn-BD = [ ./misc/lang-bn_BD.nix ];
      };

      # base
      baseModule = [
        # inputs modules
        inputs.disko.nixosModules.disko
        inputs.lanzaboote.nixosModules.lanzaboote
        inputs.nix-flatpak.nixosModules.nix-flatpak

        # System stuff
        ./system/base.nix
        ./system/disko.nix
        ./system/zram.nix
        ./system/tpm2.nix
        ./system/users.nix
      ]
      # Include Lanzaboote
      ++ lanzabooteModule
      # HW config
      ++ hwModule.hardwareConfiguration
      # Languages
      ++ langModule.bn-BD;

      # base-desktop
      desktopModule =
        let
          commonDesktopModules = [
            # base-desktop core
            ./system/base-desktop.nix

            # Apps etc
            ./apps.nix

            # Misc
            ./misc/font-fix.nix
          ];
        in
        rec {
          default = gnome-desktop;
          gnome-desktop = commonDesktopModules ++ [ ./desktop/gnome-desktop.nix ];
          kde-desktop = commonDesktopModules ++ [ ./desktop/kde-desktop.nix ];
        };

    in
    {
      nixosConfigurations =
        let

          # Install configs
          baseInstall = (subtractLists lanzabooteModule baseModule);
          baseDesktopInstall = (baseInstall ++ desktopModule.default);

          # Base configs
          baseSystem = baseModule;
          baseDesktopSystem = baseSystem ++ desktopModule.default;

        in
        {
          # Install configs
          base-install = mkSystem baseInstall;
          base-desktop-install = mkSystem baseDesktopInstall;

          # Base configs
          base = mkSystem baseSystem;
          base-desktop = mkSystem baseDesktopSystem;

          # Device-specific configs
          dell-l3530-nixos = mkSystem (baseDesktopSystem ++ hwModule.dell-l3530);
        };
    };
}
