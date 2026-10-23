# nixos-config
**Last edited: 23-10-2026**
**Last update commit:** `796ec42`

Declarative, flake-driven NixOS configuration built with a **"Fork & Adapt"** architecture. One flake builds every variant: headless (`nogui`) or desktop (GNOME / KDE Plasma 6 / COSMIC), tailored for daily-driver hardware (currently a Dell Latitude 3530) while providing clean, modular templates for adding any PC, laptop, or virtual machine.

- **Channel:** `nixos-26.05`
- **Kernel:** Linux LTS (`pkgs.linuxPackages`) by default
- **Bootloader:** Limine with Secure Boot signing and automatic `sbctl` key management
- **Disk:** disko-managed GPT → LUKS → btrfs (`@root`, `@home`, `@nix`), optional TPM2 auto-unlock
- **Maintenance:** Automatic weekly `fstrim` and btrfs scrub
- **Flake apps:** Zen Browser, nix-gaming (wine-tkg), Google Antigravity, and nixos-hardware (Dell Latitude 3530)

---

## AI Agent Directives & Architecture Conventions

> [!IMPORTANT]
> **Guidelines for AI Coding Assistants modifying this repository:**
> This repository uses a strict modular architecture composed via Cartesian matrix multiplication in `flake.nix`. All agents generating, modifying, or refactoring code must adhere to the boundaries and conventions below.

### 1. Strict Layer Separation & Boundary Rules
The codebase is partitioned into strictly decoupled layers. Never breach these architectural boundaries:
- **`hw/device/<name>/` (Hardware Layer)**:
  - Strictly limited to hardware definitions (`hardware-configuration.nix`), hostname (`networking.hostName`), GPU driver imports (`../../gpu/<vendor>`), kernel module tweaks, and the Disko target drive declaration (`disko.devices.disk.main.device`).
  - **Never** import desktop environments, user accounts, or application packages inside `hw/`.
- **`desktop/` (Desktop & Graphical Baseline)**:
  - Contains desktop environments (`gnome-desktop.nix`, `kde-desktop.nix`, `cosmic-desktop.nix`), regional input methods (`lang-extra/`), and the hardware-agnostic GUI baseline (`base-desktop.nix`).
  - **Never** introduce hardware-specific assumptions (e.g. GPU drivers, Wi-Fi quirks) inside `desktop/`.
- **`apps/` (User Applications & Services)**:
  - Houses user-facing packages, container/VM tooling (Podman, Distrobox), background services (WARP, LocalSend), and custom feature toggles (`app-extras.nix`).
- **`system/` (Core System Baseline)**:
  - Defines the core operating system baseline (Limine bootloader, Secure Boot, zram, TPM2, and Disko partition schema).
  - Must remain completely **host-agnostic, desktop-agnostic, and user-agnostic**.
- **`users/` (Declarative Identity Layer)**:
  - Manages declarative user accounts (`services.userborn.enable = true;`, `users.mutableUsers = false;`). User profiles belong exclusively in `users/`.

### 2. Module & Option Conventions
- **Feature Toggles**: Any optional feature, package group, or flake integration must be gated behind a `custom.*` option defined in [`apps/app-extras.nix`](file:///home/faeizmahrus/Projects/nixos-config/apps/app-extras.nix) using `lib.mkEnableOption` with sensible defaults.
- **Priority Management**: When setting baseline values in `system/` or `desktop/`, always wrap defaults with `lib.mkDefault` so device modules (`hw/device/<name>/default.nix`) can cleanly override options without triggering `conflicting definition values` errors.
- **Storage / Disko Conventions**: Do not hardcode target block devices in [`system/disko.nix`](file:///home/faeizmahrus/Projects/nixos-config/system/disko.nix). The shared partition layout lives in `system/disko.nix`, while the target drive (`disko.devices.disk.main.device = "/dev/...";` or persistent `/dev/disk/by-id/...`) must always be declared in the per-device file `hw/device/<name>/default.nix`.

### 3. Cartesian Flake Matrix Integrity
- **No Standalone Configurations**: Do **not** hardcode standalone `nixosConfigurations.<name>` definitions in `flake.nix`. All deployable targets are generated dynamically through `lib.mapCartesianProduct` over `host` × `desktop`.
- **Adding Hosts**: When adding a new machine, define its hardware module in `hwModule.<name>` and register it in `hostModule.<name>`. It will automatically inherit all desktop variants (`<name>-desktop`, `<name>-kde`, `<name>-cosmic`, `<name>-nogui`).
- **Preserve `specialArgs`**: Never remove or alter `specialArgs = { inherit inputs; };` in `lib.nixosSystem`. All modules throughout the repository depend on `inputs` being universally injected via `specialArgs`.

---

## Repository Layout

```
.
├── flake.nix                       # Flake inputs and Cartesian matrix composition
├── cp-hwconf.sh                    # Helper to copy hardware-configuration.nix into target device
├── apps/                           # User-facing packages & services
│   ├── default.nix                 #   Bundles apps.nix, app-fixes.nix, and app-extras.nix
│   ├── apps.nix                    #   App suite, Podman/Flatpak/AppImage, WARP, LocalSend, dev tools
│   ├── app-extras.nix              #   custom.* toggles + nix-gaming Cachix cache
│   └── app-fixes.nix               #   Overlays/workarounds (Kdenlive crash fix, OnlyOffice font bind)
├── desktop/                        # Desktop environments & desktop baseline
│   ├── base-desktop.nix            #   Desktop-agnostic stack: PipeWire, Bluetooth, printing, Plymouth
│   ├── gnome-desktop.nix           #   GNOME 48 + extensions, adw-gtk3, Mission Center, PeaZip
│   ├── kde-desktop.nix             #   KDE Plasma 6, fcitx5, ksshaskpass
│   ├── cosmic-desktop.nix          #   COSMIC desktop and greeter
│   └── lang-extra/                 #   Extra language engines (Bangla IME / OpenBangla)
│       ├── default.nix
│       └── bn_BD.nix
├── hw/                             # Hardware-specific modules
│   ├── device/
│   │   ├── generic/                #   TEMPLATE: Reference device template for adding new machines
│   │   │   ├── default.nix         #     Template hostname, GPU imports, and disk declarations
│   │   │   └── hardware-configuration.nix # Template hardware definitions
│   │   └── dell-l3530/             #   Dell Latitude 3530 device profile (production daily driver)
│   │       ├── default.nix
│   │       └── hardware-configuration.nix
│   ├── extra/
│   │   ├── default.nix             #   Bundles extra hardware modules
│   │   └── chipsailing-cs9711/     #   Patched libfprint for the CS9711 fingerprint reader
│   └── gpu/
│       ├── intel/                  #   Intel VA-API / compute runtime (iHD, OpenCL, compute-runtime)
│       └── nvidia/
│           ├── nvidia.nix          #   Unified NVIDIA driver (Turing+, legacy, PRIME auto-offload)
│           └── nvidia-cuda.nix     #   CUDA acceleration + cache.nixos-cuda.org
├── misc/
│   ├── fixes/
│   │   ├── disk-writeback-fix.nix  #   vm.dirty_* tuning against write stalls
│   │   └── usr-fix.nix             #   bindfs /usr/share/{fonts,icons,themes} for Flatpak/distrobox
│   └── tweaks/
│       └── karg-tweaks.nix         #   Global kernel params (mitigations off, i915/iwlwifi power tuning)
├── system/                         # Core system configurations
│   ├── default.nix                 #   Bundles base, disko, tpm2, and zram
│   ├── base.nix                    #   Limine + Secure Boot, LTS kernel, Nix settings, fonts, scrub/trim
│   ├── disko.nix                   #   Declarative LUKS+Btrfs partition layout (DESTROYS target disk)
│   ├── tpm2.nix                    #   TPM2 tooling & PKCS#11 environment
│   └── zram.nix                    #   zram swap (zstd, 50% of RAM), no disk swap
└── users/                          # User accounts & environment
    ├── default.nix                 #   Immutable user enforcement (services.userborn) & user imports
    ├── faeizmahrus.nix             #   Primary workstation user (fish, CLI dev tools, Antigravity)
    └── guest.nix                   #   Unprivileged guest account (empty password)
```

---

## How the Flake is Composed

`flake.nix` dynamically generates all installable configurations using `lib.mapCartesianProduct` over `host` × `desktop` pairs.

| Component | Contents |
|---|---|
| `inputs` | `nixpkgs` (nixos-26.05), `nixos-hardware`, `disko`, `nix-flatpak`, `zen-browser-flake`, `nix-gaming`, `antigravity-nix` |
| `hwModule` | Device modules (`generic`, `dell-l3530`, extra hardware modules like `extra`) |
| `hostModule` | Complete host definitions combining `hwModule` components |
| `baseModule` | Flake inputs + `system/` + `users/` + `misc/fixes/disk-writeback-fix.nix` + `misc/tweaks/karg-tweaks.nix` |
| `desktopModule` | `commonDesktopModules` (`base-desktop.nix`, `lang-extra`, `apps/`, `usr-fix.nix`) + one DE module (`gnome`, `kde`, `cosmic`). `desktop` is an alias for `gnome`; `nogui` adds no desktop layer |
| `nixosConfigurations` | Cartesian output generated across every `host` × `desktop` permutation |

### Cartesian Output Matrix (`<host>-<variant>`)

| Output | Description |
|---|---|
| `dell-l3530-desktop` | Dell Latitude 3530 + GNOME (Default desktop workstation) |
| `dell-l3530-kde` | Dell Latitude 3530 + KDE Plasma 6 |
| `dell-l3530-cosmic` | Dell Latitude 3530 + COSMIC Desktop |
| `dell-l3530-nogui` | Headless Dell Latitude 3530 (Server / recovery profile) |
| `generic-desktop` | Generic reference host + GNOME |
| `generic-gnome` / `kde` / `cosmic` | Generic reference host + selected desktop |
| `generic-nogui` | Headless generic base (minimal installation target) |
| `<custom-host>-<variant>` | Any new machine you add to `hostModule` automatically gains all desktop variants |

---

## Fork & Adapt Guide

If you are forking this repository for your own machines, follow these two essential customization steps:

### 1. Adapting & Adding Users

User management is centralized under [`users/`](file:///home/faeizmahrus/Projects/nixos-config/users).

> [!IMPORTANT]
> [`users/default.nix`](file:///home/faeizmahrus/Projects/nixos-config/users/default.nix) sets `users.mutableUsers = false;`. This means user accounts, passwords, and groups are managed **strictly declaratively**. You cannot change passwords persistently with `passwd` unless you declare a password hash.

To create your own user:

1. **Create your user file** (e.g. `users/<yourname>.nix`):
   ```nix
   # users/alice.nix
   { pkgs, lib, config, inputs, ... }:

   {
     users.users.alice = {
       isNormalUser = true;
       extraGroups = [ "wheel" "networkmanager" ];
       shell = pkgs.fish;

       # Generate your hash with: mkpasswd -m yescrypt (or -m argon2id)
       initialHashedPassword = "$6$exampleHashHere...";

       # Personal package overrides:
       packages = [
         pkgs.python3
         pkgs.nodejs
         pkgs.jq
       ];
     };
   }
   ```

2. **Register the user in `users/default.nix`**:
   Replace `./faeizmahrus.nix` with `./<yourname>.nix`:
   ```nix
   # users/default.nix
   { ... }:

   {
     users.mutableUsers = false;
     services.userborn.enable = true;

     imports = [
       ./alice.nix    # Your new user profile
       ./guest.nix    # Optional guest account
     ];
   }
   ```

3. **Generating Passwords Declaratively**:
   Generate an encrypted password hash without leaving plain text in git:
   ```sh
   nix shell nixpkgs#mkpasswd -c mkpasswd -m yescrypt
   ```
   Paste the output into `initialHashedPassword`.

---

### 2. Adding a New Device (Hardware & Storage)

> [!NOTE]
> **Disclaimer on `hw/device/generic`**:
> The [`hw/device/generic/`](file:///home/faeizmahrus/Projects/nixos-config/hw/device/generic) folder is a **reference template**, not an actively running machine. Do not overwrite it directly unless you only intend to build a temporary generic profile. Instead, create a dedicated device directory for each physical or virtual machine.

#### Step 1: Create Your Device Folder
Copy the generic template to your new device name:
```sh
cp -r hw/device/generic hw/device/thinkpad-x1
```

#### Step 2: Generate Hardware Definitions
On the target machine (either booted into the NixOS LiveISO or on an already running system):
```sh
# Generate config without filesystems (filesystems are handled by Disko):
sudo nixos-generate-config --no-filesystems --show-hardware-config > hw/device/thinkpad-x1/hardware-configuration.nix
```

#### Step 3: Configure Device Module (`hw/device/<name>/default.nix`)
Open `hw/device/thinkpad-x1/default.nix` and customize:
1. **Host Name**
2. **GPU Driver Modules** (attach Intel or NVIDIA from `../../gpu/`)
3. **Disko Target Device** (specify the drive to install on)

```nix
# hw/device/thinkpad-x1/default.nix
{ config, lib, pkgs, ... }:

{
  # 1. System Hostname
  networking.hostName = "thinkpad-nixos";

  # 2. Storage: Declare the target disk for Disko
  # Use lsblk or /dev/disk/by-id to find your persistent disk identifier:
  disko.devices.disk.main.device = "/dev/nvme0n1";
  # Or persistent ID (recommended):
  # disko.devices.disk.main.device = "/dev/disk/by-id/nvme-Samsung_SSD_980_PRO_1TB_...";

  # 3. Imports
  imports = [
    ./hardware-configuration.nix

    # Attach GPU driver if needed:
    # ../../gpu/intel              # For Intel iGPU / compute
    # ../../gpu/nvidia/nvidia.nix  # For discrete NVIDIA / PRIME
  ];

  # 4. Optional device-specific kernel tweaks:
  # boot.kernelParams = [ "mem_sleep_default=deep" ];
}
```

#### Step 4: Wire the Device into `flake.nix`
Open [`flake.nix`](file:///home/faeizmahrus/Projects/nixos-config/flake.nix) and register your device:

```nix
hwModule = {
  generic = [ ./hw/device/generic ];
  dell-l3530 = [
    inputs.nixos-hardware.nixosModules.dell-latitude-3530
    ./hw/device/dell-l3530
  ];
  extra = [ ./hw/extra ];

  # Add your new hardware module:
  thinkpad-x1 = [
    # Optional nixos-hardware module if your model exists:
    # inputs.nixos-hardware.nixosModules.lenovo-thinkpad-x1-extreme-gen4
    ./hw/device/thinkpad-x1
  ];
};

hostModule = {
  generic = hwModule.generic;
  dell-l3530 = hwModule.dell-l3530 ++ hwModule.extra;

  # Expose as a host:
  thinkpad-x1 = hwModule.thinkpad-x1;
};
```

Your new machine immediately inherits the entire Cartesian desktop family:
* `thinkpad-x1-desktop` (GNOME)
* `thinkpad-x1-kde` (KDE Plasma 6)
* `thinkpad-x1-cosmic` (COSMIC)
* `thinkpad-x1-nogui` (Headless)

---

## App Toggles & Extras

[`apps/app-extras.nix`](file:///home/faeizmahrus/Projects/nixos-config/apps/app-extras.nix) defines custom kill-switches (all default `true`), evaluated in `apps/apps.nix` and `users/`:

| Option | When `true` | When `false` |
|---|---|---|
| `custom.zen-browser-flake.enable` | Zen Browser from upstream flake | `pkgs.firefox` fallback |
| `custom.nix-gaming.enable` | `wine-tkg` + `winetricks-git` from nix-gaming, plus the `WINE_BIN` WoW64 detection fix | `pkgs.wineWow64Packages.staging` + `pkgs.winetricks` |
| `custom.antigravity-nix.enable` | `google-antigravity-no-fhs` (with Chromium browser package) + `google-antigravity-cli` | Antigravity suite omitted |

> [!NOTE]
> **First-boot note (Cachix)**: On the very first rebuild with `nix-gaming`, set `custom.nix-gaming.enable = false`, rebuild and reboot so the Cachix substituter and public key from `apps/app-extras.nix` become active, then re-enable `true` and rebuild again. This prevents compiling `wine-tkg` locally from source.

---

## NVIDIA GPU Support

NVIDIA drivers are organized under [`hw/gpu/nvidia/`](file:///home/faeizmahrus/Projects/nixos-config/hw/gpu/nvidia) with modular support for modern desktop cards, legacy pre-Turing architectures, hybrid laptops (PRIME), and CUDA.

### 1. Modern Turing+ Hardware (Default)
Importing `./hw/gpu/nvidia/nvidia.nix` automatically configures:
- Open-source kernel modules (`hardware.nvidia.open = true`) for Turing (RTX 20xx / GTX 16xx) and newer GPUs.
- Modesetting enabled (`modesetting.enable = true`) for Wayland (GNOME, Plasma 6, COSMIC).
- Systemd power management (`powerManagement.enable = true`) to prevent black screens after suspend.
- 32-bit graphics libraries (`hardware.graphics.enable32Bit = true`) for Steam and Wine/Proton.
- Hardware video decoding via `pkgs.nvidia-vaapi-driver`.

### 2. Pre-Turing Legacy Hardware Switches
Older architectures cannot run the open-source kernel modules. Override in your device module:

- **Pascal (GTX 10xx, MX150–MX350) & Maxwell (GTX 9xx, GTX 750/750Ti)**:
  ```nix
  hardware.nvidia.open = false; # Proprietary closed driver
  ```
- **Kepler (GTX 6xx / 7xx)**:
  ```nix
  hardware.nvidia.open = false;
  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.legacy_470;
  boot.kernelPackages = pkgs.linuxPackages_6_6; # Pin LTS kernel if 470 fails on new kernels
  ```

### 3. Dual-GPU Hybrid Laptops (Optimus / PRIME)
For dual-GPU laptops (Intel/AMD iGPU + NVIDIA dGPU), supply your PCI Bus IDs:
1. Locate your GPU Bus IDs:
   ```sh
   lspci | grep -E "VGA|3D"
   ```
2. Convert hex bus numbers to decimal (`00:02.0` → `PCI:0:2:0`, `01:00.0` → `PCI:1:0:0`).
3. Add to your device module:
   ```nix
   hardware.nvidia.prime = {
     intelBusId = "PCI:0:2:0";  # Or amdgpuBusId = "PCI:4:0:0";
     nvidiaBusId = "PCI:1:0:0";
   };
   ```
   - **Auto-Offload:** When `nvidiaBusId` is set, `prime.offload.enable = true` activates automatically.
   - **`prime-run`:** Workloads can be dispatched on demand via `prime-run <command>` (e.g. `prime-run steam`).
   - **Power Savings:** The dGPU is powered down via PCIe Runtime D3 (`finegrained = true`) when idle.

### 4. CUDA Acceleration & Binary Cache
To enable CUDA without compiling packages locally, import `./hw/gpu/nvidia/nvidia-cuda.nix`. This attaches the `https://cache.nixos-cuda.org` binary cache and activates `nixpkgs.config.cudaSupport = true;`.

---

## Installation & Deployment

> [!CAUTION]
> The Disko step **irreversibly erases** the target disk specified in your device configuration. Always verify disk identifiers before executing.

1. **Boot LiveISO**: Boot the target machine using the official NixOS graphical or minimal LiveISO.
2. **Clone Configuration**:
   ```sh
   git clone https://gitlab.com/ScatteredCognition/nixos-config.git
   cd nixos-config
   ```
3. **Prepare Device & Target Disk**:
   Create your device folder from the generic template (or use an existing profile like `dell-l3530`):
   ```sh
   cp -r hw/device/generic hw/device/<your-device>
   ```
   In `hw/device/<your-device>/default.nix`, declare your persistent target disk (use `lsblk` or `ls -l /dev/disk/by-id`):
   ```nix
   disko.devices.disk.main.device = "/dev/nvme0n1";
   ```
   *(And register `<your-device>` in `flake.nix` under `hwModule` and `hostModule`).*

4. **Partition, Format & Mount with Disko**:
   Execute Disko against your flake configuration:
   ```sh
   sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko/latest -- \
     --mode destroy,format,mount \
     --flake .#<your-device>-desktop
   ```
   > **CLI Override Tip:** You can also override the target disk on-the-fly directly from the CLI without editing files by appending `--disk main /dev/...`:
   > ```sh
   > sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko/latest -- \
   >   --mode destroy,format,mount \
   >   --flake .#<your-device>-desktop \
   >   --disk main /dev/nvme0n1
   > ```

5. **Generate Hardware Configuration**:
   Generate hardware definitions for the machine into your device folder:
   ```sh
   sudo nixos-generate-config --root /mnt --no-filesystems --show-hardware-config > hw/device/<your-device>/hardware-configuration.nix
   ```
6. **Install System**:
   ```sh
   sudo nixos-install --flake .#<your-device>-desktop --no-root-password
   ```
7. **Reboot**:
   ```sh
   reboot
   ```
8. **Set Password**:
   Login to your new system and verify authentication.

---

## Secure Boot (Limine + sbctl)

[`system/base.nix`](file:///home/faeizmahrus/Projects/nixos-config/system/base.nix) configures Limine with `secureBoot.enable = true`, `autoGenerateKeys = true`, and `autoEnrollKeys = true` (enrolling Microsoft and firmware-builtin certificates alongside your keys).

### One-Time Activation:
1. In UEFI firmware settings, put the system into **Setup Mode** (typically via "Clear / Erase Secure Boot Keys" or "Reset to Setup Mode").
   > By UEFI specification (Section 32), entering Setup Mode deletes the Platform Key (`PK`), which unblocks unsigned binaries from loading and permits `sbctl` / Limine to write new custom keys to NVRAM.
2. Boot into NixOS and switch to your configuration:
   ```sh
   sudo nixos-rebuild switch --flake .#<host>-desktop
   ```
   Limine will generate keys under `/var/lib/sbctl`, sign the bootloader binaries, hash the config, and enroll your certificates into NVRAM. Enrolling the keys automatically transitions firmware back to **User Mode**.
3. If your firmware did not automatically re-arm Secure Boot upon key enrollment, enter UEFI settings and toggle Secure Boot to **Enabled**.
4. Verify status after booting:
   ```sh
   sudo sbctl status
   ```

---

## TPM2 LUKS Auto-Unlock

Eliminate passphrase prompts on boot by sealing your LUKS encryption key to TPM2 PCRs 5 and 7 (firmware & Secure Boot state):

```sh
# Replace /dev/nvme0n1p2 with your LUKS partition:
sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=5+7 /dev/nvme0n1p2
```

> [!NOTE]
> PCR 7 binds to your Secure Boot state and keys. If you ever regenerate or re-enroll Secure Boot keys, clear the slot (`sudo systemd-cryptenroll --wipe-slot=tpm2 /dev/nvme0n1p2`) and re-enroll.

---

## Verification & Routine Maintenance

### Non-destructive Evaluation (CI / Local Testing)
Verify configuration evaluation across all flake outputs without altering system state:
```sh
nix flake check path:.
```

Build a specific configuration non-destructively into `./result`:
```sh
nixos-rebuild build --flake .#dell-l3530-desktop
```

### Deploying Changes
Deploy active configuration to the current system:
```sh
sudo nixos-rebuild switch --flake .#dell-l3530-desktop
```
*(Note: If you have untracked or uncommitted changes, use `--flake path:.#<target>` so Nix can read them).*

### Upgrading to a New NixOS Release
1. Update `flake.nix`: `nixpkgs.url = "github:NixOS/nixpkgs/nixos-YY.MM";`
2. Update flake inputs:
   ```sh
   nix flake update
   ```
3. Test evaluation:
   ```sh
   nix flake check path:.
   ```
4. Rebuild, verify, and bump `system.stateVersion` in `system/base.nix`.
