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
  # Set nix-gaming.enable to false during first rebuild after enabling cachix
  # Then do a reboot, set it to true, rebuild once more for the cachix cache to be active
  custom = {
    # zen-browser-flake.enable = true;
    # nix-gaming.enable = false;
    # antigravity-nix.enable = false;
  };

  # workaround for NixOS/nixpkgs#338367: point winetricks at the real
  # (unwrapped) binaries so its arch/WoW64 detection works
  # set wine = to the wine version you are using rn
  environment.sessionVariables =
    if (config.custom.nix-gaming.enable or false) then
      let
        wine = inputs.nix-gaming.packages.${pkgs.stdenv.hostPlatform.system}.wine-tkg;
      in
      {
        WINE_BIN = "${wine}/bin/.wine";
        # WINESERVER_BIN = "${wine}/bin/.wineserver";
      }
    else
      { };

  environment.systemPackages =

    # Main browser
    (
      if (config.custom.zen-browser-flake.enable or false) then
        [ inputs.zen-browser-flake.packages.${pkgs.stdenv.hostPlatform.system}.default ]
      else
        [ pkgs.firefox ] # backup if zen breaks
    )

    # Extra browsers
    ++ [
      (pkgs.chromium.override { enableWideVine = true; })
      pkgs.tor-browser
    ]

    # Creative apps
    ++ [
      pkgs.shotcut
      pkgs.gimp-with-plugins
      pkgs.blender
    ]

    # Essentials + Emulation
    ++ [
      pkgs.zed-editor
      pkgs.onlyoffice-desktopeditors
      pkgs.vlc
      pkgs.qbittorrent
      pkgs.naps2
      pkgs.foliate
      pkgs.pika-backup
      pkgs.retroarch-free
    ]

    # Wine
    # Installs nix-gaming winetricks if config.custom.nix-gaming.enable is true, otherwise falls back to system wine
    ++ (
      if (config.custom.nix-gaming.enable or false) then
        (with inputs.nix-gaming.packages.${pkgs.stdenv.hostPlatform.system}; [
          wine-tkg
          winetricks-git
        ])
      else
        [
          pkgs.wineWow64Packages.staging
          pkgs.winetricks
        ]
    )

    # Python, node and jq for when you need it
    ++ [
      pkgs.python3
      pkgs.nodejs
      pkgs.jq
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

    # Distrobox gui
    ++ (
      if config.services.desktopManager.gnome.enable then
        # For GNOME
        [ pkgs.distroshelf ]
      else
        # Everything else
        [ pkgs.kontainer ]
    )

    # Misc CLI
    ++ [
      pkgs.wl-clipboard
      pkgs.yt-dlp
      pkgs.aria2
      pkgs.android-tools
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
