# apps.nix
{
  pkgs,
  inputs,
  config,
  ...
}:

{
  environment.systemPackages = [
    # Basic apps
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    pkgs.qbittorrent
    # pkgs.onlyoffice-desktopeditors # Has issues finding fonts even after applying workarounds, use the flatpak
    pkgs.zed-editor
    pkgs.krita
    pkgs.kdePackages.kdenlive
    pkgs.blender
  ]

  # Conditional statement to install GTK/Qt variants depending on whether GNOME is installed
  ++ [
    (
      if config.services.desktopManager.gnome.enable then
        # Install if GNOME installed
        pkgs.libreoffice-fresh
      else
        # Install if GNOME isn't installed
        pkgs.libreoffice-qt6-fresh
    )
  ]

  # Nix LSP support
  ++ [
    pkgs.nixd
    pkgs.nil
  ]

  # Distrobox and container-stuff
  ++ [
    pkgs.distrobox
    pkgs.podman-compose
    pkgs.docker-compose
  ]

  # Misc CLI
  ++ [
    pkgs.wl-clipboard
  ];

  # Cloudflare WARP
  services.cloudflare-warp.enable = true;

  # LocalSend
  programs.localsend = {
    enable = true;
    openFirewall = true;
  };

  # Podman
  virtualisation = {
    containers = {
      enable = true;
      registries.search = [ "docker.io" ];
    };
    podman = {
      enable = true;
      dockerCompat = true;
      # Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  # Flatpak configuration
  services.flatpak = {
    enable = true;
    remotes = [
      {
        name = "flathub";
        location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
      }
    ];

    # Flatpak apps
    # packages = [ "flathub:app/org.gnome.World.PikaBackup" ];
  };
}
