# lang-bangla.nix
{ pkgs, ... }:

{
  i18n = {
    extraLocales = [
      "bn_BD/UTF-8"
    ];
    extraLocaleSettings = {
      LC_ADDRESS = "bn_BD";
      LC_IDENTIFICATION = "bn_BD";
      LC_MEASUREMENT = "bn_BD";
      LC_MONETARY = "bn_BD";
      LC_NAME = "bn_BD";
      LC_NUMERIC = "bn_BD";
      LC_PAPER = "bn_BD";
      LC_TELEPHONE = "bn_BD";
      LC_TIME = "bn_BD";
      LC_COLLATE = "bn_BD";
      # LC_MESSAGES = "bn_BD"; # Use whatever is the default for UI language
    };
  };

  # OpenaBangla (autoselects based on whether fcitx5 or ibus is used)
  i18n.inputMethod = {
    fcitx5.addons = with pkgs; [ fcitx5-openbangla-keyboard ];
    ibus.engines = with pkgs; [ openbangla-keyboard ];
  };

}
