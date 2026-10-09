# users.nix
{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:

{
  users.users = {
    faeizmahrus = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      hashedPassword = "";

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

    guest = {
      isNormalUser = true;
      hashedPassword = "";

      # User shell
      shell = pkgs.zsh;
    };
  };
}
