# flake.nix

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
    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, disko, lanzaboote, zen-browser, ... } @ inputs: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        disko.nixosModules.disko
        lanzaboote.nixosModules.lanzaboote
        ./disko.nix
        ./zram.nix
        ./tpm2.nix
        ./lanzaboote.nix  # <-- add ONLY after first successful boot, see steps below
        ./hardware-configuration.nix
        ./apps.nix
        ./default.nix
        ./kde-desktop.nix
        ./lang-bangla.nix
        ./users.nix
      ];
    };
  };
}
