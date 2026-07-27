# kargs.nix

{
  # Set hostname
  networking.hostName = "dell-nixos";

  # Disable mitigations
  boot.kernelParams = [
    "mitigations=off"
  ];

  # Additional modprobe stuff (Mostly optimization)
  boot.extraModprobeConfig = ''
    options i915 mitigations=off
    options iwlwifi power_save=Y power_level=5
  '';
}
