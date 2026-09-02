# nixos-config
**Last edited: 02-09-2026 (git commit e87b13981e63d4e0280a024e4de1e10f2b89fa67)**

Declarative, flake-based NixOS configuration. One flake builds every variant: headless or desktop (GNOME / KDE Plasma / COSMIC), generic or device-specific (currently a Dell Latitude 3530).

- **Channel:** `nixos-26.05`
- **Bootloader:** Limine with Secure Boot signing and automatic sbctl key management
- **Disk:** disko-managed GPT → LUKS → btrfs (`@root`, `@home`, `@nix`), optional TPM2 auto-unlock
- **Flake apps:** Zen Browser and nix-gaming (wine-cachyos), each behind a kill-switch with nixpkgs fallbacks

## Repository layout

```
.
├── flake.nix                       # All composition happens here
├── cp-hwconf.sh                    # Copies the generated hardware-configuration.nix into ./hw
├── apps/                           # User-facing packages & services
│   ├── apps.nix                    #   Main app set, Podman/Flatpak/AppImage, WARP, LocalSend
│   ├── app-extras.nix              #   custom.* toggles + nix-gaming Cachix cache
│   └── app-fixes.nix               #   Overlays/workarounds (e.g. Kdenlive GSettings crash fix)
├── desktop/                        # One module per desktop environment
│   ├── gnome-desktop.nix
│   ├── kde-desktop.nix
│   └── cosmic-desktop.nix
├── hw/                             # Hardware-specific modules
│   ├── hardware-configuration.nix  #   Generated at install time (per machine)
│   ├── device/dell-l3530.nix       #   Dell Latitude 3530 quirks (modprobe, mitigations, hostname)
│   ├── fprint/chipsailing-cs9711.nix # Patched libfprint for the CS9711 fingerprint reader
│   └── gpu/intel.nix               #   Intel VA-API / compute runtime
├── misc/
│   ├── fixes/
│   │   ├── disk-writeback-fix.nix  #   vm.dirty_* tuning against write stalls
│   │   └── usr-fix.nix             #   bindfs /usr/share/{fonts,icons,themes} for Flatpak/distrobox
│   └── lang/bn_BD.nix              # Bangla locale + OpenBangla IME (ibus & fcitx5)
└── system/                         # Everything that makes a bootable base system
    ├── base.nix                    #   Limine + Secure Boot, Nix settings, fonts, locale, OOM, fprintd
    ├── base-desktop.nix            #   Desktop-agnostic layer: PipeWire, Bluetooth, printing, Plymouth
    ├── disko.nix                   #   Declarative partitioning (DESTROYS the target disk)
    ├── tpm2.nix                    #   TPM2 tooling
    ├── users.nix                   #   User accounts (fish for main user, zsh for guest)
    └── zram.nix                    #   zram swap (zstd, 50% of RAM), no disk swap
```

## How the flake is composed

`flake.nix` assembles configurations from layered module lists, then generates every combination automatically.

| Piece | Contents |
|---|---|
| `inputs` | `nixpkgs` (nixos-26.05), `disko`, `nix-flatpak`, `zen-browser`, `nix-gaming` |
| `hwModule` | `hardwareConfiguration` (generated file), `extra` (fingerprint reader), `dell-l3530` (device + Intel GPU) |
| `langModule` | `bn_BD` Bangla locale/IME support |
| `inputsModule` | External NixOS modules: disko, nix-flatpak |
| `baseModule` | hw + inputs + `system/*` → a complete headless system |
| `desktopModule` | `commonDesktopModules` (`base-desktop.nix`, `apps/*`, `usr-fix.nix`) + one DE module. `desktop` is an alias for `gnome`; `nogui` adds nothing |
| `mkSystem` | Thin wrapper over `lib.nixosSystem`, injecting `inputs` via `specialArgs` |

`lib.concatMapAttrs` maps over `desktopModule` and emits two families of configurations:

| Flake output | What you get |
|---|---|
| `base-nogui` | Headless base system |
| `base-desktop` | Base + GNOME (the `desktop` alias) |
| `base-gnome` / `base-kde` / `base-cosmic` | Base + that desktop |
| `dell-l3530-<variant>` | Any of the above, plus Dell Latitude 3530 quirks (hostname `dell-nixos`, i915/iwlwifi tuning) |

Notes on inputs:

- `disko`, `nix-flatpak` and `zen-browser` all `follows` the system `nixpkgs`.
- `nix-gaming` deliberately does **not** follow — it keeps its own nixpkgs pin so its packages come precompiled from its Cachix cache. Adding `follows` forces source builds (see the comment in `flake.nix`).

## App toggles

`apps/app-extras.nix` defines two kill-switches (both default `true`), flipped in `apps/apps.nix`:

| Option | When `true` | When `false` |
|---|---|---|
| `custom.zen-browser.enable` | Zen Browser from its flake | `pkgs.firefox` fallback |
| `custom.nix-gaming.enable` | `wine-cachyos` + `winetricks-git` from nix-gaming, plus the `WINE_BIN` workaround for winetricks arch/WoW64 detection (NixOS/nixpkgs#338367) | `pkgs.wineWow64Packages.staging` + `pkgs.winetricks` |

> **First-boot note (Cachix):** on the very first rebuild with nix-gaming, set `custom.nix-gaming.enable = false`, rebuild and reboot so the Cachix substituter and trusted key from `app-extras.nix` become active, then set it back to `true` and rebuild again. Otherwise the nix-gaming packages compile from source.

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
   sudo nixos-install --flake .#base-gnome --no-root-password
   ```
   Use `base-nogui` for a headless install, `base-kde`/`base-cosmic` for the other desktops, or a `dell-l3530-*` variant on that machine.
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

## Creating new deployments

Iterate and deploy with:

```sh
sudo nixos-rebuild switch --flake path:$PWD#base-desktop
```

For a new machine: add `hw/device/<name>.nix` (plus GPU/fingerprint modules as needed), wire them into `hwModule` in `flake.nix`, and a full `<name>-{nogui,desktop,gnome,kde,cosmic}` family is generated automatically. Set `networking.hostName` in the device module (the default is `nixos`).

## Upgrading to a new NixOS release

1. Point `flake.nix` at the new release: `nixpkgs.url = "github:NixOS/nixpkgs/nixos-YY.MM";`
2. Update all inputs:
   ```sh
   nix flake update
   ```
3. Read the new release's changelog for breaking changes, then rebuild and reboot.
4. Once everything checks out, bump `system.stateVersion` in `system/base.nix` to the new version.
5. Rebuild and reboot again.
