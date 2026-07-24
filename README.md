# nixos-config

## Installation
1. Copy this repo into a USB stick or smth (path to the base of this repo is referred to as `./`)
2. Boot into NixOS LiveISO  
  2.1. `cd` into wherever you copied this repo
3. Change `disko.nix`:`device = "/dev/nvme0n1";` to whatever disk you wanna nuke
4. Run `sudo nix --experimental-features "nix-command flakes" run github:nix-community/disko/latest -- --mode destroy,format,mount ./disko.nix`
5. Now the sacrifice disk has been thoroughly cleansed for the new soul to possess it  
  5.1. It is mounted under `/mnt`
6. Run `sudo nixos-generate-config --root /mnt --no-filesystems`
7. Run `cp /mnt/etc/nixos/hardware-configuration.nix ./system/hardware-configuration.nix`  
  7.1. Run `rm ./system/hardware-configuration.nix` to remove any pre-existing hardware-specific config
8. Comment out `flake.nix`:`./system/lanzaboot.nix` line  
  8.1. If you don't need or want SecureBoot, you can just keep it commented out  
  8.2. Optionally, comment out `flake.nix`:`./misc/lang-bangla.nix`,`./system/tpm2.nix` lines if you don't need the Bangla-specific stuff or TPM2 support  
9. Comment/Uncomment the DE(s) you want to use such as `flake.nix`:`./desktop/gnome-desktop.nix`
10. Finally, run `sudo nixos-install --flake .#myhost --no-root-password`

## Creating new deployments
Run `sudo nixos-rebuild switch --flake
 path:$PWD#myhost` to interate and deploy new derivations

## Enabling secureboot
1. From the UEFI firmware, enable user-defined keys and set secureboot to disabled or unenforced (Google/use AI)
2. In the installed system, run `sudo sbctl create-keys` to create secureboot keys
3. Run `sudo sbctl enroll-keys -m` to enroll secureboot keys with the MS keys
4. Uncomment the `flake.nix`:`./system/lanzaboot.nix` line
5. Rebuild your NixOS derivation and reboot

## TPM2 LUKS auto-unlock
1. In the installed system, run `sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=5+7 /dev/nvme0n1p2` (Replace `/dev/nvme0n1p2` with the partition you want to decrypt)
2. Follow whatever steps the CLI leads you into and reboot afterwards
