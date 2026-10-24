# lang-bangla.nix
{ pkgs, ... }:

{
  # OpenaBangla (autoselects based on whether fcitx5 or ibus is used)
  i18n.inputMethod = {
    fcitx5.addons = with pkgs; [ fcitx5-openbangla-keyboard ];
    ibus.engines = with pkgs; [ openbangla-keyboard ];
  };

  # Add Bengali to default fontconfig fonts
  fonts.fontconfig.defaultFonts = {
    serif = [
      "Noto Serif Bengali"
    ];
    sansSerif = [
      "Noto Sans Bengali"
    ];
    monospace = [
      # No monospace fonts for Bengali
    ];
    emoji = [
      # Not applicable
    ];
  };
}
