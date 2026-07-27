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

      # base
      baseModule = [
        # inputs modules
        inputs.disko.nixosModules.disko
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

      # lanzaboote
      lanzabooteModule = [
        inputs.lanzaboote.nixosModules.lanzaboote
        ./system/lanzaboote.nix
      ];

    in
    {
      nixosConfigurations = {
        # Install configs
        base-install = mkSystem baseModule;
        base-desktop-install = mkSystem (baseModule ++ desktopModule);

        # Base configs
        base = mkSystem (baseModule ++ lanzabooteModule);
        base-desktop = mkSystem (baseModule ++ desktopModule ++ lanzabooteModule);

        # Device-specific configs
        dell-l3530-nixos = mkSystem (
          baseModule ++ desktopModule ++ lanzabooteModule ++ [ ./hw/dell-latitude-3530.nix ]
        );
      };
    };
}
