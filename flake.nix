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
      toList = nixpkgs.lib.lists.toList;

      # lanzaboote
      # So removeModule isn't dependant on a hardcoded path
      lanzabooteModule = [ ./system/lanzaboote.nix ];

      # base
      baseModule = lanzabooteModule ++ [
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

        # HW-specific stuff
        ./hw/hardware-configuration.nix
        # ./misc/hw/dell-latitude-3530.nix
      ];

      # base-desktop
      desktopModule = [
        # base-desktop core
        ./system/base-desktop.nix

        # Apps etc
        ./apps.nix

        # Desktop
        #./desktop/kde-desktop.nix
        ./desktop/gnome-desktop.nix

        # Misc
        ./misc/font-fix.nix
        ./misc/lang-bangla.nix
      ];

    in
    {
      nixosConfigurations = {
        # Install configs
        base-install = mkSystem (subtractLists (toList lanzabooteModule) (toList baseModule));
        base-desktop-install = mkSystem (
          subtractLists (toList lanzabooteModule) (toList (baseModule ++ desktopModule))
        );

        # Base configs
        base = mkSystem baseModule;
        base-desktop = mkSystem (baseModule ++ desktopModule);

        # Device-specific configs
        dell-l3530-nixos = mkSystem (baseModule ++ desktopModule ++ [ ./hw/dell-latitude-3530.nix ]);
      };
    };
}
