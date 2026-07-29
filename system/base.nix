# base.nix
{
  pkgs,
  config,
  lib,
  inputs,
  ...
}:

{
  # NixOS Version + allow unfree
  system.stateVersion = "26.05";
  nixpkgs.config.allowUnfree = true;
  nix.registry.nixpkgs.flake = inputs.nixpkgs; # explicitly set nixpkgs to system nixpkgs
  nix.settings = {
    auto-optimise-store = true;
    trusted-users = [
      "@wheel"
    ];
    experimental-features = [
      "nix-command"
      "flakes"
    ];
  };

  # Boot stuff
  boot = {
    loader = {
      systemd-boot.enable = lib.mkDefault true; # systemd-boot
      timeout = 0; # Hides boot selector
      efi.canTouchEfiVariables = true;
    };
  };

  # Networking
  networking = {
    hostName = lib.mkDefault config.system.nixos.distroId; # set this in ./misc/hw/<hardware_name>.nix
    networkmanager.enable = true;
  };

  # Locale stuff
  time.timeZone = lib.mkDefault "Asia/Dhaka";
  i18n = {
    defaultLocale = lib.mkDefault "en_US.UTF-8";
    extraLocales = [
      "en_US.UTF-8/UTF-8"
    ];
  };

  # Fonts stuff
  fonts = {
    enableDefaultPackages = true; # Default unicode fonts
    fontconfig.useEmbeddedBitmaps = true;
    fontDir.enable = true; # symlinks all host fonts to /run/current-system/sw/share/X11/fonts

    packages = with pkgs; [
      # MS Fonts
      corefonts

      # Install Noto fonts
      noto-fonts
      noto-fonts-color-emoji
    ];
  };

  # Hardware stuff
  ## Power Management
  powerManagement.enable = true;

  ## Enable firmware updater
  services.fwupd.enable = true;

  ## Filesystem maintenance
  services.btrfs.autoScrub = {
    enable = true;
  };

  # fish + zsh
  programs = {
    fish.enable = true;
    zsh.enable = true;
  };

  # Extra programs to enable
  environment.systemPackages = [
    pkgs.git
    pkgs.fastfetch
    pkgs.home-manager
  ]

  # Needed for lanzaboot
  ++ [
    pkgs.sbctl
    pkgs.e2fsprogs
  ];
}
