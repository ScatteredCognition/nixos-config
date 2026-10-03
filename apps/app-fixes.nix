# app-fixes.nix

{
  nixpkgs.overlays = [
    # fix for Kdenlive crash under GNOME
    # ## https://github.com/NixOS/nixpkgs/issues/469503
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

    # OnlyOffice font fix
    (final: prev: {
      onlyoffice-desktopeditors = prev.buildFHSEnv (
        prev.onlyoffice-desktopeditors.passthru.args
        // {
          extraBwrapArgs = (prev.onlyoffice-desktopeditors.passthru.args.extraBwrapArgs or [ ]) ++ [
            "--ro-bind"
            "/usr/share/fonts" # If you only enabled fontDir.enable = true; add /run/current-system/sw/share/X11/fonts instead
            "/usr/share/fonts"
          ];
        }
      );
    })
  ];
}
