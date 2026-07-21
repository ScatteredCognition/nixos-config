# font-fix.nix
{ pkgs, ... }:

{
  # Bind mount fonts.fontDir path to FHS paths
  # Such as /usr/share/fonts and /run/host/usr/share/fonts
  # Fixes flatpak and distrobox font issues, maybe even more

  fonts.fontDir.enable = true;
  system.fsPackages = [ pkgs.bindfs ];

  # Flatpak: Bind mounts /usr/share/fonts
  fileSystems."/usr/share/fonts" = {
    device = "/run/current-system/sw/share/X11/fonts";
    fsType = "fuse.bindfs";
    options = [
      "ro"
      "resolve-symlinks"
      "x-gvfs-hide"
    ];
  };

  # Distrobox: Bind mounts /usr/share/fonts
  fileSystems."/run/host/usr/share/fonts" = {
    device = "/run/current-system/sw/share/X11/fonts";
    fsType = "fuse.bindfs";
    options = [
      "ro"
      "resolve-symlinks"
      "x-gvfs-hide"
    ];
  };
}
