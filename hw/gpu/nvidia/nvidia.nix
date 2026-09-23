# hw/gpu/nvidia/nvidia.nix
# Comprehensive NVIDIA GPU module with support for:
# - Modern architectures (Turing, Ampere, Ada Lovelace, Blackwell)
# - Legacy / Pre-Turing architectures (Pascal, Maxwell, Kepler)
# - Dual-GPU hybrid laptops (Optimus / PRIME Offload & Sync modes)
#
# References:
# - Official NixOS Wiki: https://wiki.nixos.org/wiki/NVIDIA
# - Nixpkgs module source: https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/hardware/video/nvidia.nix
# - NVIDIA Linux Driver Downloads: https://www.nvidia.com/en-us/drivers/unix/
#
# ==============================================================================
# HARDWARE GENERATION SWITCHING CHEATSHEET
# ==============================================================================
#
# 1. MODERN (RTX 20xx / GTX 16xx and newer: Ampere, Ada Lovelace, Blackwell)
#    - Already configured by default below!
#    - Open kernel module: hardware.nvidia.open = true (Default)
#    - Driver package:     hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.stable (Default)
#    - Power management:   hardware.nvidia.powerManagement.enable = true (Default)
#
# 2. PASCAL (GTX 10xx, MX150/MX250/MX350) & MAXWELL (GTX 9xx, GTX 750/750Ti)
#    - Pre-Turing cards DO NOT support open-source kernel modules.
#    - In your device configuration (e.g., hw/device/<machine>.nix), override:
#        hardware.nvidia.open = false;
#        # (package remains config.boot.kernelPackages.nvidiaPackages.stable)
#        # (powerManagement.finegrained is automatically disabled when open = false)
#
# 3. KEPLER (GTX 6xx, GTX 7xx desktop/mobile except 750/750Ti)
#    - Kepler support was dropped in the 515+ driver branch; requires the 470 legacy driver.
#    - In your device configuration, override:
#        hardware.nvidia.open = false;
#        hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.legacy_470;
#    - Note on Kernel Compatibility: Legacy 470 drivers may fail to compile on
#      bleeding-edge Linux kernels (e.g. 6.12+). If compile errors occur, pin to an LTS kernel:
#        boot.kernelPackages = pkgs.linuxPackages_6_6;
#
# 4. FERMI (GTX 4xx, GTX 5xx)
#    - Requires the 390 legacy driver:
#        hardware.nvidia.open = false;
#        hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.legacy_390;
#        boot.kernelPackages = pkgs.linuxPackages_6_1; # Requires older LTS kernel
#
# ==============================================================================
# HYBRID GRAPHICS / OPTIMUS / PRIME (DUAL-GPU LAPTOPS)
# ==============================================================================
#
# To enable PRIME offload on laptops with an integrated GPU (Intel or AMD)
# and a discrete NVIDIA GPU, simply declare the PCI Bus IDs in your device file:
#
# Step 1: Discover your PCI Bus IDs:
#   lspci | grep -E "VGA|3D"
# Example output:
#   00:02.0 VGA compatible controller: Intel Corporation Alder Lake-UP3 GT2 [Iris Xe Graphics]
#   01:00.0 3D controller: NVIDIA Corporation GA107M [GeForce RTX 3050 Mobile]
#
# Step 2: Format IDs as decimal "PCI:X:Y:Z":
#   Notice: lspci is in hexadecimal. If bus number exceeds 9 (e.g. 0a:00.0), convert hex to dec (0a = 10 -> "PCI:10:0:0").
#
# Step 3: Add to your hw/device/<machine>.nix:
#   hardware.nvidia.prime = {
#     # For Intel iGPU:
#     intelBusId = "PCI:0:2:0";
#     # Or for AMD APU:
#     # amdgpuBusId = "PCI:4:0:0";
#
#     # For discrete NVIDIA GPU:
#     nvidiaBusId = "PCI:1:0:0";
#   };
#
# Once `nvidiaBusId` is defined, this module automatically activates PRIME offload
# and provides the `prime-run` command (e.g. `prime-run steam`, `prime-run vkcube`).
#
# Sync Mode (Alternative to Offload):
# If your external monitor ports (HDMI/DisplayPort) are wired directly to the dGPU
# and do not output in offload mode, you can switch to always-on Sync mode instead:
#   hardware.nvidia.prime.sync.enable = true;

{ config, lib, pkgs, ... }:

let
  # Checks if PRIME bus IDs have been supplied by the host device
  hasPrimeBusIds =
    config.hardware.nvidia.prime.nvidiaBusId != ""
    && (config.hardware.nvidia.prime.intelBusId != "" || config.hardware.nvidia.prime.amdgpuBusId != "");
in
{
  # 1. Video Drivers
  # Instructs X11 and Wayland compositors to load the proprietary/open NVIDIA driver.
  # Nixpkgs source: nixos/modules/hardware/video/nvidia.nix (services.xserver.videoDrivers)
  # Wiki: https://wiki.nixos.org/wiki/NVIDIA#Enabling
  services.xserver.videoDrivers = [ "nvidia" ];

  # 2. Graphics Driver Stack & Hardware Video Acceleration (VA-API)
  # hardware.graphics replaced hardware.opengl in NixOS 24.11.
  # enable32Bit is critical for running 32-bit applications such as Steam and Wine/Proton.
  # nvidia-vaapi-driver provides NVDEC-based hardware video decoding (VA-API) in Firefox and media players.
  # Wiki: https://wiki.nixos.org/wiki/NVIDIA#Hardware_video_acceleration
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = [
      pkgs.nvidia-vaapi-driver
    ];
    extraPackages32 = [
      pkgs.pkgsi686Linux.nvidia-vaapi-driver
    ];
  };

  # 3. NVIDIA Driver Options
  # Wiki: https://wiki.nixos.org/wiki/NVIDIA#Configuring
  hardware.nvidia = {
    # Modesetting enables the nvidia-drm kernel module with modeset=1.
    # Essential for modern desktop environments, Wayland compositors (GNOME, KDE Plasma 6, COSMIC),
    # and preventing display tearing on hybrid / PRIME systems.
    modesetting.enable = true;

    # Power Management:
    # Enables experimental systemd sleep/suspend/resume integration (nvidia-suspend.service, etc.).
    # Saves and restores video memory across suspend/resume cycles to prevent black screens and corruption.
    # Wiki: https://wiki.nixos.org/wiki/NVIDIA#Power_management
    powerManagement.enable = true;

    # Fine-grained power management (PCIe Runtime D3 / RTD3):
    # Automatically powers down the discrete GPU when idle in offload mode.
    # Note: Only supported on Turing (RTX 20xx / GTX 16xx) or newer GPUs in offload mode.
    # On pre-Turing architectures (Pascal, Maxwell, Kepler), this should remain false.
    powerManagement.finegrained = lib.mkDefault (hasPrimeBusIds && config.hardware.nvidia.open);

    # Open Kernel Modules:
    # Uses the open-source kernel modules (nvidia-open).
    # Supported on Turing (RTX 20xx / GTX 16xx) and newer GPUs (Ada Lovelace, Blackwell, Hopper).
    # On driver 560+, Nixpkgs requires this option to be explicitly set.
    # For older architectures (Pascal GTX 10xx, Maxwell, Kepler), override `open = false;` in device config.
    open = lib.mkDefault true;

    # Installs the nvidia-settings GUI configuration tool.
    nvidiaSettings = true;

    # Driver package selection:
    # Defaults to the stable production driver branch matching the current kernel.
    # For Kepler cards (GTX 6xx/7xx), override to `config.boot.kernelPackages.nvidiaPackages.legacy_470;`
    package = lib.mkDefault config.boot.kernelPackages.nvidiaPackages.stable;

    # 4. PRIME Hybrid Graphics Configuration
    # Automatically activates on-demand offload when the host provides PCI Bus IDs,
    # unless the host explicitly enables Sync or Reverse Sync mode.
    prime = lib.mkIf hasPrimeBusIds {
      offload = {
        # Priority 990 overrides Nixpkgs's default priority 1000 without overriding explicit user settings
        enable = lib.mkOverride 990 (
          !config.hardware.nvidia.prime.sync.enable
          && !config.hardware.nvidia.prime.reverseSync.enable
        );
        enableOffloadCmd = lib.mkDefault true;
        offloadCmdMainProgram = lib.mkDefault "prime-run";
      };
    };
  };
}
