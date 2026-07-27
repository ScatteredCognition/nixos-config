# nixos-config

## Installation
1. Copy this repo into a USB stick or smth (path to the base of this repo is referred to as `./`)
2. Boot into NixOS LiveISO  
  2.1. `cd` into wherever you copied this repo
3. Change `./system/disko.nix`:`device = "/dev/nvme0n1";` to whatever disk you wanna nuke
4. Run `sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko/latest -- --mode destroy,format,mount ./system/disko.nix`
5. Now the sacrifice disk has been thoroughly cleansed for the new soul to possess it  
  5.1. It is mounted under `/mnt`
6. Run `sudo nixos-generate-config --root /mnt --no-filesystems`
7. Run `cp /mnt/etc/nixos/hardware-configuration.nix ./hw/hardware-configuration.nix`  
  7.1. Run `rm ./hw/hardware-configuration.nix` to remove any pre-existing hardware-specific config
8. Comment out `flake.nix`:`./system/lanzaboot.nix` line  
  8.1. If you don't need or want SecureBoot, you can just keep it commented out  
  8.2. Optionally, comment out `flake.nix`:`./misc/lang-bangla.nix`,`./system/tpm2.nix` lines if you don't need the Bangla-specific stuff or TPM2 support  
9. Comment/Uncomment the DE(s) you want to use such as `flake.nix`:`./desktop/gnome-desktop.nix`
10. Finally, run `sudo nixos-install --flake .#base-desktop-install --no-root-password`

## Creating new deployments
Run `sudo nixos-rebuild switch --flake
 path:$PWD#base-desktop (or #base-desktop-install if you don't have lanzaboot)` to interate and deploy new derivations  
For specialized, per-device configs, create files under `./hw/` for your device and add it to the `flake.nix`
Like: `sudo nixos-rebuild switch --flake
 path:$PWD#dell-l3530-nixos`

## Enabling secureboot
1. From the UEFI firmware, enable user-defined keys and set secureboot to disabled or unenforced (Google/use AI)
2. In the installed system, run `sudo sbctl create-keys` to create secureboot keys
3. Run `sudo sbctl enroll-keys -m` to enroll secureboot keys with the MS keys
4. Rebuild your NixOS deployment with `sudo nixos-rebuild switch --flake
 path:$PWD#base-desktop` and reboot

## TPM2 LUKS auto-unlock
1. In the installed system, run `sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=5+7 /dev/nvme0n1p2` (Replace `/dev/nvme0n1p2` with the partition you want to decrypt)
2. Follow whatever steps the CLI leads you into and reboot afterwards

## Upgrading
1. Change `flake.nix`:`nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";` to the URL of the new release
2. Run `nix update flake`
3. Rebuild your NixOS deployment and reboot
4. Carefully read through the changelogs for the new release for any breaking changes that might impact you and after you are sure everything is alright, edit `./system/base.nix`:`system.stateVersion = "26.05";` to the new version's version number.
5. Rebuild your NixOS deployment again and reboot
