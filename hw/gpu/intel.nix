# intel.nix

{ pkgs, ... }:

{
  hardware.graphics = {
    enable = true;
    extraPackages = [
      # Intel stuff
      pkgs.intel-media-driver
      pkgs.intel-vaapi-driver
      pkgs.intel-compute-runtime
      pkgs.intel-ocl
      pkgs.vpl-gpu-rt
      pkgs.intel-media-sdk
    ];
  };
}
