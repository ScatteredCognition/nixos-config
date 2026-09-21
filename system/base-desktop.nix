# base-desktop.nix

# base.nix
{
  pkgs,
  config,
  lib,
  ...
}:

{
  # Plymouth bling
  boot = {
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

  # Disable firewall
  networking = {
    firewall.enable = false; # Disable firewall coz too many issues

  };

  # Fonts stuff handled in base.nix
  # Timezone and locale stuff handled in base.nix

  # Hardware stuff
  ## Graphics stuff
  ### Enables Mesa etc, intel/AMD/nvidia stuff
  ### in ./hw/gpu/<vendor>.nix
  hardware.graphics.enable = true;

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

  # Desktop stuff
  ## rtkit helps pipewire latency
  security.rtkit.enable = true;
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
      # alsa.support32Bit = true; # pulls in alot of 32bit deps
    };
    # Input remapper
    input-remapper = {
      enable = true;
      enableUdevRules = true; # re-applies on hotplug
    };
  };
}
