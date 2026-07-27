# flake.nix

# Inputs
{
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
      base-desktop = [
        # inputs modules
        inputs.disko.nixosModules.disko
        inputs.lanzaboote.nixosModules.lanzaboote
        inputs.nix-flatpak.nixosModules.nix-flatpak

        # System stuff
        ./system/base.nix
        ./system/disko.nix
        ./system/lanzaboote.nix # <-- add ONLY after first successful boot
        ./system/zram.nix
        ./system/tpm2.nix
        ./system/users.nix

        # HW-specific stuff
        ./system/hardware-configuration.nix
        # ./misc/hw/dell-latitude-3530.nix

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
      nixosConfigurations.base-desktop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        # Every child module gets access to the inputs defined (needed for Zen browser in apps.nix)
        specialArgs = { inherit inputs; };
        modules = base-desktop ++ [
          # Empty on purpose
        ];
      };

      nixosConfigurations.dell-nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        # Every child module gets access to the inputs defined (needed for Zen browser in apps.nix)
        specialArgs = { inherit inputs; };
        modules = base-desktop ++ [
          ./misc/hw/dell-latitude-3530.nix
        ];
      };
    };
}
