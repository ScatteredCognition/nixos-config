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
      pkgs.intel-ocl
      pkgs.vpl-gpu-rt
      # pkgs.intel-media-sdk # marked as insecure
    ];
  };
}
