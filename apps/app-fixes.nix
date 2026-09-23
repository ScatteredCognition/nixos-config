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
        cfgBrowser = config.custom.antigravity-nix.browser or "auto";

        browserSpecs = {
          chromium = {
            pkg = pkgs.chromium;
            bin = "chromium";
            devToolsPath = "%h/.config/chromium/DevToolsActivePort";
          };
          ungoogled-chromium = {
            pkg = pkgs.ungoogled-chromium;
            bin = "chromium";
            devToolsPath = "%h/.config/chromium/DevToolsActivePort";
          };
          brave = {
            pkg = pkgs.brave;
            bin = "brave";
            devToolsPath = "%h/.config/BraveSoftware/Brave-Browser/DevToolsActivePort";
          };
          vivaldi = {
            pkg = pkgs.vivaldi;
            bin = "vivaldi";
            devToolsPath = "%h/.config/vivaldi/DevToolsActivePort";
          };
        };

        target = browserSpecs.${cfgBrowser} or browserSpecs.chromium;
      in
      lib.mkIf (cfgBrowser != "google-chrome") {
        # Fallback google-chrome-stable symlink with lowPrio:
        # If native google-chrome is installed in systemPackages, it has higher priority and wins.
        environment.systemPackages = [
          (lib.lowPrio (
            pkgs.runCommand "google-chrome-stable" { } ''
              mkdir -p $out/bin
              ln -s ${target.pkg}/bin/${target.bin} $out/bin/google-chrome-stable
            ''
          ))
        ];

        systemd.user.tmpfiles.rules = [
          "d %h/.config/google-chrome 0700 - - - -"
          "L+ %h/.config/google-chrome/DevToolsActivePort - - - - ${target.devToolsPath}"
        ];
      }
    ))
  ];
}
