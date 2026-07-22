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
  ]

  # Install Resources
  ++ [ pkgs.resources ];

  # Some from flatpak
  # services.flatpak.packages = [
  #   "flathub:app/net.nokyan.Resources"
  # ];

  # Enable the GNOME extensions ootb
  programs.dconf.profiles.user.databases = [
    {
      settings = {
        # gnome-shell stuff
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

        # App drawer stuff
        "org/gnome/desktop/app-folders" = {
          # No "Utilities" or "System app grouping"
          folder-children =
            [ ]
            # LibreOffice group for apps
            ++ [ "LibreOffice" ];
        };

        # Defines the properties of the new LibreOffice folder
        "org/gnome/desktop/app-folders/folders/LibreOffice" = {
          name = "LibreOffice";
          translate = false;
          # Groups all system-installed LibreOffice applications
          apps = [
            "startcenter.desktop"
            "writer.desktop"
            "calc.desktop"
            "impress.desktop"
            "draw.desktop"
            "base.desktop"
            "math.desktop"
          ];
        };
      };
    }
  ];

}
