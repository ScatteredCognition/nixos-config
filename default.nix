# default.nix
{ pkgs, ... }:

{
  # NixOS Version + allow unfree
  system.stateVersion = "26.05";
  nixpkgs.config.allowUnfree = true;
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  ## For per-user normal nix
  environment.etc."nix/nixpkgs-config.nix".text = ''
    { allowUnfree = true; }
  '';

  # Boot stuff
  boot = {
    loader = {
      systemd-boot.enable = true; # systemd-boot
      timeout = 0; # Hides boot selector
      efi.canTouchEfiVariables = true;
    };
    plymouth.enable = true; # fancy shi
    # Hides kernel spam during boot for nice plymouth menu
    consoleLogLevel = 3;
    initrd.verbose = false;
    kernelParams = [
      "quiet"
      "rd.udev.log_level=3"
      "rd.systemd.show_status=auto"
    ];
  };

  # Networking
  networking = {
    hostName = "dell-nixos";
    networkmanager.enable = true;
    firewall.enable = false; # Disable firewall coz too many issues

  };

  # Locale stuff
  time.timeZone = "Asia/Dhaka";
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocales = [
      "en_US.UTF-8/UTF-8"
    ];
  };

  # Fonts stuff
  fonts = {
    enableDefaultPackages = true; # Default unicode fonts
    fontconfig.useEmbeddedBitmaps = true;
    fontDir.enable = true; # symlinks all host fonts to /run/current-system/sw/share/X11/fonts
  };

  # Hardware stuff
  ## Power Management
  powerManagement.enable = true;

  ## Enable all firmwares incl. proprietary
  hardware.enableAllFirmware = true;

  ## Bluetooth stuff
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        # Shows battery charge of connected devices on supported Bluetooth adapters.
        # Defaults to 'false'.
        Experimental = true;
        # When enabled other devices can connect faster to us, however the tradeoff is increased power consumption.
        # Defaults to 'false'.
        FastConnectable = true;
      };
      Policy = {
        # Enable all controllers when they are found. This includes adapters present on start as well as adapters that are plugged in later on.
        # Defaults to 'true'.
        AutoEnable = true;
      };
    };
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
  ]

  # Needed for lanzaboot
  # Run `sudo sbctl create-keys` and `sudo sbctl enroll-keys -m` before uncommenting lanzaboot.nix
  ++ [
    pkgs.sbctl
    pkgs.e2fsprogs
  ];

  # Desktop stuff
  services = {
    # xserver.enable = true; # X11
    libinput.enable = true; # Input stack
    printing.enable = true; # Printing stack
    # Audio stack
    pipewire = {
      enable = true;
      pulse.enable = true;
      jack.enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
    };
  };
}
