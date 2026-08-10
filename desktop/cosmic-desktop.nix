# cosmic-desktop.nix
{
  # config,
  # lib,
  pkgs,
  ...
}:

{

  # Enable cosmic-greeter and cosmic
  services = {
    displayManager.cosmic-greeter.enable = true;
    desktopManager.cosmic.enable = true;
  };

  # Enable ibus for IME
  i18n.inputMethod = {
    enable = true;
    type = "ibus";
  };
}
