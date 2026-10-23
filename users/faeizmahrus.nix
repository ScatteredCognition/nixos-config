# faeizmahrus.nix
{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:

{
  users.users.faeizmahrus = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    initialHashedPassword = "$6$eYzqbH8iKuFk5PMT$ZRm33dU3TxgD0IX7UcAqYuzFj3PTXLHtt9wm795gW3pkV9hhnJhvTNAhtSRtJ.REKRfeIaWOhOM9KWiK4jmch1";

    # User shell
    shell = pkgs.fish;

    # Extra programs and shi
    packages =
      # AI Agent shi
      [
        pkgs.python3
        pkgs.nodejs
        pkgs.jq
      ]
      # Antigravity
      ++ lib.optionals (config.custom.antigravity-nix.enable or false) (
        with inputs.antigravity-nix.packages.${pkgs.stdenv.hostPlatform.system};
        [
          (google-antigravity-no-fhs.override {
            browserPkg = pkgs.chromium;
          })
          google-antigravity-cli
        ]
      );
  };
}
