# nixos-config
**Last edited: 08-10-2026 (git commit afd2b878b677deb7e52e5037cf474f01abd06628)**

Declarative, flake-driven NixOS configuration. One flake builds every variant: headless or desktop (GNOME / KDE Plasma / COSMIC), generic or device-specific (currently a Dell Latitude 3530).

- **Channel:** `nixos-26.05`
- **Bootloader:** Limine with Secure Boot signing and automatic sbctl key management
- **Disk:** disko-managed GPT → LUKS → btrfs (`@root`, `@home`, `@nix`), optional TPM2 auto-unlock
- **Flake apps:** Zen Browser, nix-gaming (wine-tkg), Google Antigravity, and OpenCode, each behind a kill-switch with nixpkgs fallbacks

## Repository layout

```
.
├── flake.nix                       # Flake inputs and Cartesian matrix composition
├── cp-hwconf.sh                    # Copies the generated hardware-configuration.nix into ./hw
├── apps/                           # User-facing packages & services
│   ├── apps.nix                    #   Main app set, Podman/Flatpak/AppImage, WARP, LocalSend, AI agents
│   ├── app-extras.nix              #   custom.* toggles + nix-gaming Cachix cache
│   └── app-fixes.nix               #   Overlays/workarounds (Kdenlive GSettings crash, OnlyOffice font bind)
├── desktop/                        # One module per desktop environment
│   ├── gnome-desktop.nix           #   GNOME + extensions, adw-gtk3, Mission Center
│   ├── kde-desktop.nix             #   KDE Plasma 6, fcitx5, ksshaskpass
│   └── cosmic-desktop.nix          #   COSMIC desktop and greeter
├── hw/                             # Hardware-specific modules
│   ├── hardware-configuration.nix  #   Generated at install time (per machine)
│   ├── device/dell-l3530.nix       #   Dell Latitude 3530 device module (hostname)
│   ├── fprint/chipsailing-cs9711.nix # Patched libfprint for the CS9711 fingerprint reader
│   └── gpu/
│       ├── intel.nix               #   Intel VA-API / compute runtime
│       └── nvidia/
│           ├── nvidia.nix          #   Unified NVIDIA driver (Turing+, legacy, PRIME auto-offload)
│           └── nvidia-cuda.nix     #   CUDA acceleration + cache.nixos-cuda.org
├── misc/
│   ├── fixes/
│   │   ├── disk-writeback-fix.nix  #   vm.dirty_* tuning against write stalls
│   │   └── usr-fix.nix             #   bindfs /usr/share/{fonts,icons,themes} for Flatpak/distrobox
│   ├── karg-tweaks.nix             #   Global kernel params (mitigations off, i915/iwlwifi power tuning)
│   └── lang/bn_BD.nix              # Bangla locale + OpenBangla IME (ibus & fcitx5)
└── system/                         # Core system configurations
    ├── base.nix                    #   Limine + Secure Boot, Nix settings, fonts, locale, OOM, fprintd, packages
    ├── base-desktop.nix            #   Desktop-agnostic layer: PipeWire, Bluetooth, printing, Plymouth, input-remapper
    ├── disko.nix                   #   Declarative partitioning (DESTROYS the target disk)
    ├── tpm2.nix                    #   TPM2 tooling
    ├── users.nix                   #   User accounts (fish for main user, zsh for guest)
    └── zram.nix                    #   zram swap (zstd, 50% of RAM), no disk swap
```

## How the flake is composed

`flake.nix` assembles configurations by combining layered module lists and generating every combination via `lib.mapCartesianProduct`.

| Piece | Contents |
|---|---|
| `inputs` | `nixpkgs` (nixos-26.05), `disko`, `nix-flatpak`, `zen-browser-flake`, `nix-gaming`, `antigravity-nix`, `opencode` |
| `hwModule` | `hardwareConfiguration` (machine-generated), `extra` (CS9711 fingerprint reader), `dell-l3530` (device + Intel GPU) |
| `hostModule` | `generic` (`hardwareConfiguration` only), `dell-l3530` (`hardwareConfiguration` + `dell-l3530` + `extra`) |
| `langModule` | `bn_BD` Bangla locale/IME support |
| `inputsModule` | External NixOS modules: disko, nix-flatpak |
| `baseModule` | `inputsModule` + `system/*` + `disk-writeback-fix.nix` + `karg-tweaks.nix` |
| `baseSystem` | `baseModule` + `langModule.bn_BD` |
| `desktopModule` | `commonDesktopModules` (`base-desktop.nix`, `apps/*`, `usr-fix.nix`) + one DE module (`gnome`, `kde`, `cosmic`). `desktop` is an alias for `gnome`; `nogui` adds nothing |
| `nixosConfigurations` | Generated via `lib.mapCartesianProduct` over `host` × `desktop` pairs |

Cartesian product outputs (`<host>-<variant>`):

| Flake output | What you get |
|---|---|
| `generic-nogui` | Headless generic system |
| `generic-desktop` | generic + GNOME (default desktop alias) |
| `generic-gnome` / `generic-kde` / `generic-cosmic` | generic + that desktop environment |
| `dell-l3530-<variant>` | Any of the above, plus Dell Latitude 3530 device module (hostname `dell-nixos`, CS9711 fprint). i915/iwlwifi tuning is global via `misc/karg-tweaks.nix` |

Notes on inputs:

- `disko`, `nix-flatpak`, `zen-browser-flake`, `antigravity-nix`, and `opencode` all follow the system `nixpkgs`.
- `nix-gaming` deliberately does **not** follow — it keeps its own nixpkgs pin so its packages come precompiled from its Cachix cache. Adding `follows` forces source builds (see the comment in `flake.nix`).

## App toggles

`apps/app-extras.nix` defines custom kill-switches (all default `true`), evaluated in `apps/apps.nix`:

| Option | When `true` | When `false` |
|---|---|---|
| `custom.zen-browser-flake.enable` | Zen Browser from its flake (`inputs.zen-browser-flake`) | `pkgs.firefox` fallback |
| `custom.nix-gaming.enable` | `wine-tkg` + `winetricks-git` from nix-gaming, plus the `WINE_BIN` workaround for winetricks arch/WoW64 detection (NixOS/nixpkgs#338367) | `pkgs.wineWow64Packages.staging` + `pkgs.winetricks` |
| `custom.antigravity-nix.enable` | `google-antigravity-no-fhs` (with `browserPkg = pkgs.chromium`) + `google-antigravity-cli` from `inputs.antigravity-nix` | No fallback — OpenCode covers the terminal-agent case |
| `custom.opencode.enable` | `opencode` + `opencode-desktop` from upstream flake (`inputs.opencode`, follows `nixpkgs` but ships no binary cache, so it builds from source) | `pkgs.opencode` + `pkgs.opencode-desktop` fallback |

> **First-boot note (Cachix):** on the very first rebuild with nix-gaming, set `custom.nix-gaming.enable = false`, rebuild and reboot so the Cachix substituter and trusted key from `app-extras.nix` become active, then set it back to `true` and rebuild again. Otherwise the nix-gaming packages compile from source.

## NVIDIA GPU Support

NVIDIA drivers are organized under `hw/gpu/nvidia/` with modular support for modern desktop cards, legacy pre-Turing architectures, hybrid laptops (PRIME), and CUDA.

### 1. Modern Turing+ Hardware (Default)
Importing `./hw/gpu/nvidia/nvidia.nix` automatically configures:
- Open-source kernel modules (`hardware.nvidia.open = true`) for Turing (RTX 20xx / GTX 16xx) and newer GPUs.
- Modesetting enabled (`modesetting.enable = true`), ensuring Wayland compositors (GNOME, KDE Plasma 6, COSMIC) work smoothly.
- Systemd power management (`powerManagement.enable = true`) to prevent black screens after sleep/suspend.
- Full 32-bit graphics libraries (`hardware.graphics.enable32Bit = true`) for Steam and Wine/Proton.
- Hardware video decoding via `pkgs.nvidia-vaapi-driver` in `hardware.graphics.extraPackages`.

### 2. Pre-Turing Legacy Hardware Switches
Older architectures cannot run the open-source kernel modules. Simply set these options in your device module (e.g. `hw/device/<machine>.nix`):

- **Pascal (GTX 10xx, MX150–MX350) & Maxwell (GTX 9xx, GTX 750/750Ti)**:
  ```nix
  hardware.nvidia.open = false; # Use proprietary closed kernel driver
  ```
- **Kepler (GTX 6xx / 7xx)**:
  ```nix
  hardware.nvidia.open = false;
  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.legacy_470;
  # Pin to LTS kernel if legacy drivers fail to compile on bleeding-edge kernels:
  boot.kernelPackages = pkgs.linuxPackages_6_6;
  ```
- **Fermi (GTX 4xx / 5xx)**:
  ```nix
  hardware.nvidia.open = false;
  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.legacy_390;
  boot.kernelPackages = pkgs.linuxPackages_6_1;
  ```

### 3. Dual-GPU Hybrid Laptops (Optimus / PRIME)
For dual-GPU laptops (Intel/AMD iGPU + NVIDIA dGPU), the module automatically activates PRIME offload and power management once you supply your PCI Bus IDs:

1. Locate your GPU Bus IDs:
   ```sh
   lspci | grep -E "VGA|3D"
   ```
   Example output:
   ```
   00:02.0 VGA compatible controller: Intel Corporation ...
   01:00.0 3D controller: NVIDIA Corporation ...
   ```
2. Convert hex bus numbers to decimal (`00:02.0` → `PCI:0:2:0`, `01:00.0` → `PCI:1:0:0`, `0a:00.0` → `PCI:10:0:0`).
3. Add them to your `hw/device/<machine>.nix`:
   ```nix
   hardware.nvidia.prime = {
     intelBusId = "PCI:0:2:0";  # Or amdgpuBusId = "PCI:4:0:0";
     nvidiaBusId = "PCI:1:0:0";
   };
   ```
   - **Auto-Offload:** When `nvidiaBusId` is set, `prime.offload.enable = true` is activated automatically.
   - **`prime-run`:** Heavy 3D or compute workloads can be dispatched on demand via `prime-run <command>` (e.g. `prime-run steam`).
   - **Power Savings:** The dGPU is powered down via PCIe Runtime D3 (`finegrained = true`) when idle.
   - **Sync Mode Override:** If display outputs are wired directly to the dGPU, switch to always-on sync mode by adding `hardware.nvidia.prime.sync.enable = true;`.

### 4. CUDA Acceleration & Binary Cache
To enable CUDA acceleration without triggering widespread local compilations of uncached packages, import `./hw/gpu/nvidia/nvidia-cuda.nix`. This configures:
- Binary cache substituter: `https://cache.nixos-cuda.org`
- Public trusted key: `cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M=`
- `nixpkgs.config.cudaSupport = true;`

## Adding New Hardware & Hosts

Adding a new machine to this repository is fully modular. Follow these steps to generate hardware definitions, configure device quirks, and expose the machine in `flake.nix`:

### Step 1: Generate `hardware-configuration.nix`
On the target machine (either from the LiveISO or an installed system):
```sh
# Filesystems are handled declaratively by disko, so omit filesystems:
sudo nixos-generate-config --no-filesystems --show-hardware-config > hw/hardware-configuration.nix
```
*(If managing multiple distinct machines, you can name it per-machine, e.g. `hw/hwconf-<name>.nix`).*

### Step 2: Create the Device Module (`hw/device/<name>.nix`)
Create `hw/device/<name>.nix` to house machine-specific quirks, hostname, kernel parameters, and hardware overrides:

```nix
# hw/device/thinkpad-x1.nix
{ config, pkgs, ... }:

{
  # 1. Hostname
  networking.hostName = "thinkpad-nixos";

  # 2. Kernel parameters and hardware mitigations
  boot.kernelParams = [ "mitigations=off" ];

  # 3. Hardware-specific modprobe optimizations
  boot.extraModprobeConfig = ''
    options iwlwifi power_save=Y power_level=5
  '';

  # 4. Hybrid GPU Bus IDs (if equipped with dual-GPU / PRIME)
  # hardware.nvidia.prime = {
  #   intelBusId = "PCI:0:2:0";
  #   nvidiaBusId = "PCI:1:0:0";
  # };
}
```

### Step 3: Wire into `flake.nix`
Open `flake.nix` and connect your new device module and hardware components:

1. **Add to `hwModule`**:
   Group your device module with its required GPU or peripheral definitions:
   ```nix
   hwModule = {
     hardwareConfiguration = [ ./hw/hardware-configuration.nix ];
     extra = [ ./hw/fprint/chipsailing-cs9711.nix ];

     # Existing Dell Latitude 3530
     dell-l3530 = [
       ./hw/device/dell-l3530.nix
       ./hw/gpu/intel.nix
     ];

     # New machine (e.g. ThinkPad with NVIDIA)
     thinkpad-x1 = [
       ./hw/device/thinkpad-x1.nix
       ./hw/gpu/nvidia/nvidia.nix # Attach the NVIDIA driver module
     ];
   };
   ```

2. **Add to `hostModule`**:
   Define the complete host profile by combining the hardware configuration with the device modules:
   ```nix
   hostModule = {
     generic = hwModule.hardwareConfiguration;
     dell-l3530 = hwModule.hardwareConfiguration ++ hwModule.dell-l3530 ++ hwModule.extra;
     thinkpad-x1 = hwModule.hardwareConfiguration ++ hwModule.thinkpad-x1;
   };
   ```

### Step 4: Automatic Cartesian Matrix Output
Because `flake.nix` uses `lib.mapCartesianProduct` over `host` × `desktop`, adding `thinkpad-x1` to `hostModule` automatically generates the complete family of install targets:
- `thinkpad-x1-nogui` (headless)
- `thinkpad-x1-desktop` (GNOME default alias)
- `thinkpad-x1-gnome`
- `thinkpad-x1-kde`
- `thinkpad-x1-cosmic`

### Step 5: Test and Deploy
Verify configuration evaluation non-destructively:
```sh
nix flake check path:.
nixos-rebuild build --flake path:$PWD#thinkpad-x1-desktop
```
Deploy to the target machine:
```sh
sudo nixos-rebuild switch --flake path:$PWD#thinkpad-x1-desktop
```

## Installation

> ⚠️ The disko step **irreversibly erases** the target disk.

1. Copy this repo to a USB stick (paths below assume the repo root as `./`).
2. Boot the NixOS LiveISO and `cd` into the repo.
3. Edit `system/disko.nix` → `device = "/dev/nvme0n1";` to the disk you want to nuke (`lsblk` to find it).
4. Partition, format and mount:
   ```sh
   sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko/latest -- --mode destroy,format,mount ./system/disko.nix
   ```
   The disk is now cleansed and mounted under `/mnt` (LUKS container `cryptroot` with btrfs subvolumes `@root`, `@home`, `@nix`).
5. Generate the hardware config (filesystems are handled by disko, hence `--no-filesystems`):
   ```sh
   sudo nixos-generate-config --root /mnt --no-filesystems
   ```
6. Copy it into the flake:
   ```sh
   ./cp-hwconf.sh
   ```
7. Install the variant you want, e.g.:
   ```sh
   sudo nixos-install --flake .#generic-gnome --no-root-password
   ```
   Use `generic-nogui` for a headless install, `generic-kde`/`generic-cosmic` for the other desktops, or a `dell-l3530-*` variant on that machine.
8. Reboot into the new system and set passwords — `users.nix` ships with blank password hashes:
   ```sh
   sudo passwd faeizmahrus
   ```
9. Continue to **Secure Boot** below.

## Secure Boot (Limine + sbctl)

`system/base.nix` enables Limine with `secureBoot.enable`, `autoGenerateKeys` and `autoEnrollKeys` (with `--microsoft --firmware-builtin`), plus config-checksum enrollment (`enrollConfig`, `validateChecksums`, `panicOnChecksumMismatch`). Keys are created and enrolled automatically — no manual `sbctl create-keys` / `enroll-keys` step, and no separate unsigned `-install` configuration is needed anymore.

One-time setup:

1. In the UEFI firmware, reset Secure Boot to **Setup Mode** (usually named "Erase/Clear all Secure Boot keys") and leave Secure Boot itself **disabled** for now.
2. Boot into NixOS and rebuild:
   ```sh
   sudo nixos-rebuild switch --flake path:$PWD#<config>
   ```
   Bootloader installation generates keys under `/var/lib/sbctl` if none exist, signs the Limine EFI binary, and enrolls your keys together with the Microsoft and firmware-builtin certificates.
3. Reboot into the firmware and **enable Secure Boot**.
4. Verify after boot:
   ```sh
   sudo sbctl status
   ```

## TPM2 LUKS auto-unlock

Skip the passphrase prompt on boot by sealing the LUKS key against TPM2 PCRs 5+7:

1. In the installed system, run (replace with your LUKS partition):
   ```sh
   sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=5+7 /dev/nvme0n1p2
   ```
2. Follow the prompts and reboot.

Note: PCR 7 binds to the Secure Boot state and keys. If you ever re-enroll or rotate Secure Boot keys, auto-unlock will fail once — unlock with the passphrase and re-enroll (`systemd-cryptenroll --wipe-slot=tpm2` first, then repeat the command above).

## Verification and Deployment

### Non-destructive checks (CI / Development / Agents)
Verify configuration evaluation without switching or altering system state:
```sh
nix flake check path:.
```
Or build a specific configuration non-destructively:
```sh
nixos-rebuild build --flake path:$PWD#<config>
```

### Deploying changes
Deploy active configuration to the system:
```sh
sudo nixos-rebuild switch --flake path:$PWD#generic-desktop
```
> Note: We use `path:$PWD` (or `path:.`) so Nix can read files not tracked by Git (such as `hw/hardware-configuration.nix`).

## Upgrading to a new NixOS release

1. Point `flake.nix` at the new release: `nixpkgs.url = "github:NixOS/nixpkgs/nixos-YY.MM";`
2. Update all inputs:
   ```sh
   nix flake update
   ```
3. Read the new release's changelog for breaking changes, then rebuild and reboot.
4. Once everything checks out, bump `system.stateVersion` in `system/base.nix` to the new version.
5. Rebuild and reboot again.
