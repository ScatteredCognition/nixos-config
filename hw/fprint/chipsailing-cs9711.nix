{ pkgs, ... }:

let
  libfprint-cs9711 = pkgs.libfprint.overrideAttrs (oldAttrs: {
    pname = "libfprint-cs9711";
    version = "git";

    src = pkgs.fetchFromGitHub {
      owner = "archeYR";
      repo = "libfprint-CS9711";
      rev = "02b285c9703c38d308fbe47a3c566ef1e7f883ca";
      hash = "sha256-QGrBNqbRNqLZIURI66xkenlQamNW+DQU4WS+CLN4zM8=";
    };

    nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [
      pkgs.opencv
      pkgs.cmake
      pkgs.doctest
    ];
  });
in
{
  services.fprintd = {
    enable = true;
    package = pkgs.fprintd.override { libfprint = libfprint-cs9711; };
  };

  services.udev.packages = [ libfprint-cs9711 ];
}
