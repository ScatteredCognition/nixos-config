# tweaks.nix
{
  # Disable mitigations
  boot.kernelParams = [
    "mitigations=off"
    "i915.mitigations=off"
    "iwlwifi.power_save=Y" # or "iwlwifi.power_save=1"
    "iwlwifi.power_level=5"
  ];
}
