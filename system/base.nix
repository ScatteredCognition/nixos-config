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
    keep-outputs = true; # keeps compiler etc build pre-requisites
    keep-derivations = true;
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
      # timeout = 0; # Hides boot selector
      efi.canTouchEfiVariables = true; # Allow adding EFI boot entries, modifying NVRAM

      limine = {
        enable = true; # Enables limine
        enableEditor = false; # Disables the boot entry editor
        maxGenerations = 16; # Maximum generations to keep in /boot

        # EFI/BIOS support is handled automatically

        # Secureboot pre-req
        validateChecksums = true; # Validate boot-file checksums before booting.
        panicOnChecksumMismatch = true; # Treats a checksum mismatch as fatal.
        enrollConfig = true; # Enrolls/hashes the generated Limine configuration

        # Secureboot
        secureBoot = {
          enable = true; # Enables secureboot support
          # Create/Enroll keys if missing
          autoGenerateKeys = true;
          autoEnrollKeys = {
            enable = true;
            extraArgs = [
              "--microsoft"
              "--firmware-builtin"
            ];
          };
        };
      };
    };

    # Add ntsync support
    kernelModules = [ "ntsync" ];
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

    packages = [
      # MS Fonts
      pkgs.corefonts

      # Install Noto fonts
      pkgs.noto-fonts
      pkgs.noto-fonts-color-emoji
    ];
  };

  # Hardware stuff
  # ## Power Management stuff
  # ### Already auto enabled
  # https://github.com/NixOS/nixpkgs/blob/4fa4fdfc61c7a026bda9bb5de3f579114028e008/nixos/modules/config/power-management.nix#L18-L19
  powerManagement.enable = true;

  # Fingerprint auth
  services.fprintd = {
    enable = true;
    # tod.enable = true;
  };

  ## Enable firmware updater
  services.fwupd.enable = true;

  ## Filesystem maintenance
  services.btrfs.autoScrub = {
    enable = true;
  };

  ## Clean /tmp on boot
  boot.tmp.cleanOnBoot = true;

  ## OOM shi
  ### Enable systemd-oomd
  ### Works via PSI pressure, which updates every 10s, can't handle forkbombs etc
  systemd.oomd = {
    enable = true; # default since 24.05
    enableRootSlice = true;
    enableSystemSlice = true;
    enableUserSlices = true;
  };

  ### Enable earlyoom
  ### Works based on sole memory availability, more faster and reacctive
  ### can solve forkbombs
  services.earlyoom = {
    enable = true;
    enableNotifications = true; # Notification whenever it kills something
  };

  # ENABLE in 26.11
  # replace sudo with run0
  # security.sudo.enable = false;
  # security.run0 = {
  #   enable = true;
  #   sudo-shim.enable = true;
  #   persistentAuth.enable = true;
  #   # persistentAuth.enableRemote = true;
  # };

  # fish + zsh
  programs = {
    fish.enable = true;
    zsh.enable = true;
  };

  # Extra programs to enable
  environment.systemPackages = [
    pkgs.git
    pkgs.fastfetch
    pkgs.tree
    pkgs.nix-tree
    pkgs.home-manager
  ]

  # Needed for lanzaboot
  ++ [
    pkgs.sbctl
    pkgs.e2fsprogs
  ];
}
