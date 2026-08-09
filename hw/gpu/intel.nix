# intel.nix

{ pkgs, ... }:

{
  # Allow older insecure package
  nixpkgs.config.permittedInsecurePackages = [
    "intel-media-sdk-23.2.2"
  ];

  hardware.graphics = {
    enable = true;
    extraPackages = [
      # Intel stuff
      pkgs.intel-media-driver
      pkgs.intel-vaapi-driver
      pkgs.intel-compute-runtime
      pkgs.vpl-gpu-rt
      # pkgs.intel-ocl # needs to be built from source
      # pkgs.intel-media-sdk # marked as insecure
    ];
  };

  # environment.sessionVariables = {
  #   LIBVA_DRIVER_NAME = "iHD";
  # }; # Optionally, set the environment variable
}
