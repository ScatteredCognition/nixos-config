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
  lib,
  ...
}:

{
  environment.systemPackages =

    # Extra browsers
    [
      pkgs.firefox
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
      pkgs.cine # VLC is glitchy and buggy
      pkgs.gpu-screen-recorder-gtk # reqires programs.gpu-screen-recorder.enable = true;
      pkgs.qbittorrent
      pkgs.naps2
      pkgs.foliate
      pkgs.pika-backup
      pkgs.retroarch-free
    ]

    # Wine
    ++ [
      pkgs.wineWow64Packages.stable
      pkgs.winetricks
    ]

    # Python, node and jq for when you need it
    ++ [
      pkgs.python3
      pkgs.pipx
      pkgs.uv
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

    # Distrobox/podman/appimage gui
    ++ [ pkgs.pods pkgs.gearlever ]
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

  # GPU Screen Recorder
  programs.gpu-screen-recorder.enable = true;

  # Cloudflare WARP
  services.cloudflare-warp = {
    enable = true;
    openFirewall = true;
  };

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
  imports = [ inputs.nix-flatpak.nixosModules.nix-flatpak ];
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

  # Firewall config for apps
  networking.firewall = {
    # Fixes Cloudflare WARP and multi-routing drops
    # https://github.com/NixOS/nixpkgs/issues/504119
    checkReversePath = lib.mkIf config.services.cloudflare-warp.enable "loose";

    # These interfaces will bypass the firewall entirely
    trustedInterfaces =
      # For Cloudflare WARP (unnecessary, still kept for easy revert)
      # (lib.optionals config.services.cloudflare-warp.enable [ "CloudflareWARP" ])
      # For VMWare
      (lib.optionals config.virtualisation.vmware.host.enable [
        "vmnet1"
        "vmnet8"
      ]);

    # Set 6769 in qBittorrent
    # ports 22000 and 21027 for syncthing
    allowedTCPPorts = [ 6769 22000 ];
    allowedUDPPorts = [ 6769 22000 21027 ];
  };

}
