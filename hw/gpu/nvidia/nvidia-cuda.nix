# hw/gpu/nvidia/nvidia-cuda.nix
# CUDA acceleration and binary cache configuration.
#
# References:
# - NixOS Wiki: https://wiki.nixos.org/wiki/CUDA
# - Nixpkgs CUDA guidelines: https://nixos.org/manual/nixpkgs/stable/#cuda
# - NixOS CUDA Cache: https://cache.nixos-cuda.org

{ ... }:

{
  # 1. CUDA Community Binary Cache
  # Official NixOS Hydra caches exclude most CUDA-enabled packages due to unfree licensing
  # and heavy compilation requirements. The cache.nixos-cuda.org binary cache hosts
  # pre-built CUDA packages for Nixpkgs to avoid lengthy local source compilations.
  # Wiki: https://wiki.nixos.org/wiki/CUDA#Binary_cache
  nix.settings = {
    substituters = [
      "https://cache.nixos-cuda.org"
    ];
    trusted-public-keys = [
      "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
    ];
  };

  # 2. Global CUDA Support
  # Enables CUDA compute capabilities across packages in Nixpkgs (e.g. PyTorch, TensorFlow, FFmpeg, OpenCV).
  #
  # NOTE ON COMPILATION:
  # Setting cudaSupport = true globally applies to all supported packages. Any package or version
  # combination not cached on cache.nixos-cuda.org will be built locally from source.
  #
  # If you prefer to avoid potential large builds, consider keeping cudaSupport false globally
  # and overriding specific packages in your configuration or devShell instead:
  #   environment.systemPackages = [
  #     (pkgs.blender.override { cudaSupport = true; })
  #   ];
  nixpkgs.config.cudaSupport = true;
}
