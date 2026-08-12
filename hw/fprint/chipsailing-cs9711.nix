# chipsailing-cs9711.nix

{
  services.fprintd.enable = true;
  nixpkgs.overlays = [
    (final: prev: {
      libfprint = prev.libfprint.overrideAttrs (oldAttrs: {
        version = "git";
        src = final.fetchFromGitHub {
          owner = "archeYR";
          repo = "libfprint-CS9711";
          rev = "02b285c9703c38d308fbe47a3c566ef1e7f883ca";
          sha256 = "sha256-QGrBNqbRNqLZIURI66xkenlQamNW+DQU4WS+CLN4zM8=";
        };
        nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [
          final.opencv
          final.cmake
          final.doctest
        ];
      });
    })
  ];
}
