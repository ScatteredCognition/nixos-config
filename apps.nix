# apps.nix
{ pkgs, inputs, ... }:

{
  environment.systemPackages = [
    # Basic apps
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    pkgs.qbittorrent
    # pkgs.onlyoffice-desktopeditors # Has issues finding fonts even after applying workarounds, use the flatpak
    pkgs.libreoffice-qt6-fresh
    pkgs.zed-editor
    pkgs.krita
    pkgs.kdePackages.kdenlive
    pkgs.blender
    pkgs.git
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
      defaultNetwork.settings.dns_enabled = true; # Required for containers under podman-compose to be able to talk to each other.
    };
  };

  # Flatpak
  services.flatpak = {
    enable = true;
    remotes = [
      {
        name = "flathub";
        location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
      }
    ];
  };

  # MS Corefonts
  fonts.packages = [ pkgs.corefonts ];
}
