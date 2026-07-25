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

  # Grab Gst plugins (must be babysitted after each major upgrade)
  ++ (with pkgs.gst_all_1; [
    gstreamer
    gst-plugins-base
    gst-plugins-good
    gst-plugins-bad
    gst-plugins-ugly
    gst-libav
    gst-vaapi
    gst-plugins-rs
  ])

  # Thumbnailing support (must be babysitted after each major upgrade)
  ++ [
    # Video thumbnailers
    pkgs.gst-thumbnailers

    # Image thumbnailers
    # gdj-pixbuf (old shi)
    pkgs.gdk-pixbuf
    pkgs.webp-pixbuf-loader
    # glycin (new shi)
    pkgs.libglycin
    pkgs.glycin-loaders
    # For heic/avif/jxl support
    pkgs.libheif
    pkgs.libjxl
    pkgs.libavif

    # Exe thumbnailers
    pkgs.icoextract

    # Epub/Mobi thumbnailers
    pkgs.gnome-epub-thumbnailer

    # Krita/ORA thumbnails
    pkgs.gnome-kra-ora-thumbnailer
  ]

  # Needed for Qt app theming
  # Got this info from NixOS Matrix
  ++ [
    # Fixes the titlebars
    pkgs.qadwaitadecorations
    pkgs.qadwaitadecorations-qt6
    # Themes the app
    pkgs.qgnomeplatform
    pkgs.qgnomeplatform-qt6
  ]

  # Install extra apps
  ++ [
    pkgs.resources
    pkgs.refine
  ];

  # workaround for NixOS not setting GST PATH variable
  environment.sessionVariables = {
    GST_PLUGIN_PATH = "/run/current-system/sw/lib/gstreamer-1.0/";
  };

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
          folder-children =
            # No "Utilities" or "System" app grouping, blank list
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
