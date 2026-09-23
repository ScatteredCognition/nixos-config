# app-fixes.nix
{
  config,
  lib,
  pkgs,
  ...
}:

{
  config = lib.mkMerge [
    # fix for Kdenlive crash under GNOME
    # ## https://github.com/NixOS/nixpkgs/issues/469503
    {
      nixpkgs.overlays = [
        (final: prev: {
          kdePackages = prev.kdePackages.overrideScope (
            kfinal: kprev: {
              kdenlive = prev.symlinkJoin {
                inherit (kprev.kdenlive)
                  pname
                  version
                  meta
                  passthru
                  ;
                name = "kdenlive-crashfix";
                paths = [ kprev.kdenlive ];
                nativeBuildInputs = [ prev.makeWrapper ];
                postBuild = ''
                  wrapProgram $out/bin/kdenlive \
                    --prefix XDG_DATA_DIRS : "${prev.gtk3}/share/gsettings-schemas/${prev.gtk3.name}"
                '';
              };
            }
          );
        })
      ];
    }

    # Antigravity: browser shim & DevToolsActivePort symlink
    (lib.mkIf (config.custom.antigravity-nix.enable or false) (
      let
        browserPkg = config.custom.antigravity-nix.browserPackage;
        devToolsPath = config.custom.antigravity-nix.devToolsActivePort;
        isGoogleChrome = (lib.getName browserPkg) == "google-chrome";
      in
      lib.mkIf (!isGoogleChrome) {
        # Fallback google-chrome-stable symlink pointing to the configured browser package
        environment.systemPackages = [
          (lib.lowPrio (
            pkgs.runCommand "google-chrome-stable" { } ''
              mkdir -p $out/bin
              ln -s ${lib.getExe browserPkg} $out/bin/google-chrome-stable
            ''
          ))
        ];

        # Symlink DevToolsActivePort to the configured browser's active port file
        systemd.user.tmpfiles.rules = [
          "d %h/.config/google-chrome 0700 - - - -"
          "L+ %h/.config/google-chrome/DevToolsActivePort - - - - ${devToolsPath}"
        ];
      }
    ))
  ];
}
