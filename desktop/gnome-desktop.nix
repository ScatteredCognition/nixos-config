# gnome-desktop.nix
{
  # config,
  # lib,
  pkgs,
  ...
}:

{

  # Enable GDM and GNOME
  services = {
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
  };

  # Enable ibus for IME
  i18n.inputMethod = {
    enable = true;
    type = "ibus";
  };

  # Configure Qt/GTK theming
  qt = {
    enable = true;
    platformTheme = "gnome";
    style = "breeze";
  };

  # Remove some stuff
  environment.gnome.excludePackages = [
    pkgs.epiphany
    pkgs.gnome-characters
  ];

  # Install some crucial GNOME extensions
  environment.systemPackages = [
    pkgs.gnomeExtensions.alphabetical-app-grid
    pkgs.gnomeExtensions.appindicator
    pkgs.gnomeExtensions.caffeine
  ];

  # Some from flatpak
  # services.flatpak.packages = [
  #   "flathub:app/net.nokyan.Resources"
  # ];

  # Enable the GNOME extensions ootb
  programs.dconf.profiles.user.databases = [
    {
      settings = {
        "org/gnome/shell" = {
          # Show logout button at all times
          always-show-log-out = true;
          # Enable user extension support
          disable-user-extensions = false;

          # Enable the extensions via their UUIDs
          enabled-extensions = with pkgs.gnomeExtensions; [
            alphabetical-app-grid.extensionUuid
            appindicator.extensionUuid
            caffeine.extensionUuid
          ];
        };
      };
    }
  ];

}
