# apps.nix
## adds a minimal list of apps, use flatpaks, distrobox for extra stuff
## To stay pure nix, use the following instructions
## nix profile add nixpkgs#package_name
## For unfree stuff,
## add --impure flag to nix profile add for unfree stuff
## Also add { allowUnfree = true; } to ~/.config/nixpkgs/config.nix
{
  pkgs,
  inputs,
  config,
  ...
}:

{
  # custom = {
  #   zen-browser.enable = true;
  #   nix-gaming.enable = false;
  # };

  environment.systemPackages =
    # Browser
    (
      if (config.custom.zen-browser.enable or false) then
        [ inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default ]
      else
        [ pkgs.firefox ] # backup if zen breaks
    )

    # Basic apps
    ++ [
      pkgs.qbittorrent
      pkgs.vlc
      pkgs.zed-editor
      pkgs.naps2
      pkgs.pika-backup
      pkgs.foliate
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

    # Wine
    # Installs nix-gaming winetricks if config.custom.nix-gaming.enable is true, otherwise falls back to system wine
    ++ (
      if (config.custom.nix-gaming.enable or false) then
        (with inputs.nix-gaming.packages.${pkgs.stdenv.hostPlatform.system}; [
          wine-cachyos
          winetricks-git
        ])
        ++ [
          # workaround for NixOS/nixpkgs#338367: winetricks looks for wine64 on WoW64 builds
          (pkgs.runCommand "wine64-compat" { } ''
            mkdir -p $out/bin
            ln -s ${
              inputs.nix-gaming.packages.${pkgs.stdenv.hostPlatform.system}.wine-tkg
            }/bin/wine $out/bin/wine64
          '')
        ]
      else
        [
          pkgs.wineWow64Packages.staging
          pkgs.winetricks
        ]
    )

    # slop stuff
    ++ [
      # pkgs.chromium
      # pkgs.tor-browser
      # pkgs.onlyoffice-desktopeditors # Has issues finding fonts even after applying workarounds, use the flatpak
      # pkgs.krita
      # pkgs.gimp-with-plugins
      # pkgs.kdePackages.kdenlive
      # pkgs.blender
    ]

    # Conditional statement to install GTK/Qt variants depending on whether GNOME is installed
    # ++ (
    #   if config.services.desktopManager.gnome.enable then
    #     # Install if GNOME installed
    #     [
    #       pkgs.libreoffice-fresh
    #     ]
    #
    #   else
    #     # Install if GNOME isn't installed
    #     [ pkgs.libreoffice-qt6-fresh ]
    # )

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
    # OCI-container support
    containers = {
      enable = true;
      registries.search = [
        "docker.io"
        "quay.io"
        "ghcr.io"
      ];
    };

    # podman
    podman = {
      enable = true;
      dockerCompat = true;
      # Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings.dns_enabled = true;
    };

    # vmware
    vmware.host.enable = true;
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

  # Appimage support
  programs.appimage = {
    enable = true;
    binfmt = true;
  };

}
