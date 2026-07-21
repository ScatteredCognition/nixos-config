# kde-desktop.nix
{ pkgs, ... }:

{
  services = {
    desktopManager.plasma6.enable = true;
    displayManager = {
      plasma-login-manager.enable = true;
      defaultSession = "plasma";
    };
  };

  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      waylandFrontend = true;
      addons = with pkgs; [
        qt6Packages.fcitx5-configtool
        kdePackages.fcitx5-qt
        fcitx5-gtk
      ];
    };
  };

  # Fancy GUI SSH auth
  programs.ssh = {
    startAgent = true; # starts ssh-agent as a systemd user service
    enableAskPassword = true; # sets SSH_ASKPASS to ksshaskpass automatically
  };

  environment.variables = {
    SSH_ASKPASS_REQUIRE = "prefer"; # use GUI askpass even when a terminal is present
  };
}
