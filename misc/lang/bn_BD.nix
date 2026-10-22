# lang-bangla.nix
{ pkgs, ... }:

{
  # OpenaBangla (autoselects based on whether fcitx5 or ibus is used)
  i18n.inputMethod = {
    fcitx5.addons = with pkgs; [ fcitx5-openbangla-keyboard ];
    ibus.engines = with pkgs; [ openbangla-keyboard ];
  };

}
