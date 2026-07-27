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

      # base
      base = [
        # inputs modules
        inputs.disko.nixosModules.disko
        inputs.lanzaboote.nixosModules.lanzaboote
        inputs.nix-flatpak.nixosModules.nix-flatpak

        # System stuff
        ./system/base.nix
        ./system/disko.nix
        ./system/lanzaboote.nix
        ./system/zram.nix
        ./system/tpm2.nix
        ./system/users.nix

        # HW-specific stuff
        ./hw/hardware-configuration.nix
        # ./misc/hw/dell-latitude-3530.nix
      ];

      # base-desktop
      base-desktop = base ++ [
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
      # base
      nixosConfigurations.base = nixpkgs.lib.nixosSystem {
        # system = nixpkgs.hostPlatform;
        # Every child module gets access to the inputs defined (needed for Zen browser in apps.nix)
        specialArgs = { inherit inputs; };
        modules = base ++ [
          # Empty on purpose
        ];
      };

      # base-desktop
      nixosConfigurations.base-desktop = nixpkgs.lib.nixosSystem {
        # system = nixpkgs.hostPlatform;
        # Every child module gets access to the inputs defined (needed for Zen browser in apps.nix)
        specialArgs = { inherit inputs; };
        modules = base-desktop ++ [
          # Empty on purpose
        ];
      };

      # base-install
      nixosConfigurations.base-install = nixpkgs.lib.nixosSystem {
        # system = nixpkgs.hostPlatform;
        # Every child module gets access to the inputs defined (needed for Zen browser in apps.nix)
        specialArgs = { inherit inputs; };
        modules = (nixpkgs.lib.remove ./system/lanzaboote.nix base-desktop) ++ [
          # Empty on purpose
        ];
      };

      # base-desktop-install
      # Run `sudo sbctl create-keys` and `sudo sbctl enroll-keys -m` before using this module
      nixosConfigurations.base-desktop-install = nixpkgs.lib.nixosSystem {
        # system = nixpkgs.hostPlatform;
        # Every child module gets access to the inputs defined (needed for Zen browser in apps.nix)
        specialArgs = { inherit inputs; };
        modules = (nixpkgs.lib.remove ./system/lanzaboote.nix base-desktop) ++ [
          # Empty on purpose
        ];
      };

      # For dell-latitude-3530
      nixosConfigurations.dell-l3530-nixos = nixpkgs.lib.nixosSystem {
        # system = nixpkgs.hostPlatform;
        # Every child module gets access to the inputs defined (needed for Zen browser in apps.nix)
        specialArgs = { inherit inputs; };
        modules = base-desktop ++ [
          ./hw/dell-latitude-3530.nix
        ];
      };
    };
}
