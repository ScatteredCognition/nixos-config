# flake.nix

# Inputs
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-flatpak = {
      url = "github:gmodena/nix-flatpak";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
    {
      nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        # Every child module gets access to the inputs defined (needed for Zen browser in apps.nix)
        specialArgs = { inherit inputs; };
        modules = [
          # inputs modules
          inputs.disko.nixosModules.disko
          inputs.lanzaboote.nixosModules.lanzaboote
          inputs.nix-flatpak.nixosModules.nix-flatpak

          # System stuff
          ./system/base.nix
          ./system/disko.nix
          ./system/lanzaboote.nix # <-- add ONLY after first successful boot, see steps below
          ./system/zram.nix
          ./system/tpm2.nix
          ./system/hardware-configuration.nix
          ./system/kargs.nix
          ./system/users.nix

          # Apps etc
          ./apps.nix

          # Desktop
          #./desktop/kde-desktop.nix
          ./desktop/gnome-desktop.nix

          # Misc
          ./misc/font-fix.nix
          ./misc/lang-bangla.nix
        ];
      };
    };
}
