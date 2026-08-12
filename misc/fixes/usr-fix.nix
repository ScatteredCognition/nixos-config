# usr-fix.nix
{ pkgs, ... }:

let
  # Mount options for the bind mounts
  mountOptions = [
    "ro"
    "resolve-symlinks"
    "x-gvfs-hide"
  ];
in
{
  # Bind mount /run/current-system/sw/share/ to FHS /usr/share paths
  # Such as /usr/share/icons etc
  # Fixes flatpak and distrobox font issues, maybe even more

  # Exposes all host fonts under /run/current-system/sw/share/X11/fonts
  fonts.fontDir.enable = true;

  # Bind mounts
  system.fsPackages = [ pkgs.bindfs ];

  ## Fonts
  fileSystems."/usr/share/fonts" = {
    device = "/run/current-system/sw/share/X11/fonts";
    fsType = "fuse.bindfs";
    options = mountOptions;
  };

  ## Icons
  fileSystems."/usr/share/icons" = {
    device = "/run/current-system/sw/share/icons";
    fsType = "fuse.bindfs";
    options = mountOptions;
  };

  ## Themes
  fileSystems."/usr/share/themes" = {
    device = "/run/current-system/sw/share/themes";
    fsType = "fuse.bindfs";
    options = mountOptions;
  };
}
