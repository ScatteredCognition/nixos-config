#!/usr/bin/env sh

if [ -f /etc/nixos/hardware-configuration.nix ]; then
  cp /etc/nixos/hardware-configuration.nix ./hw/hardware-configuration.nix
elif [ -f /mnt/etc/nixos/hardware-configuration.nix ]; then
  cp /mnt/etc/nixos/hardware-configuration.nix ./hw/hardware-configuration.nix
else
  echo "Error: hardware-configuration.nix not found in /etc/nixos/ or /mnt/etc/nixos/" >&2
  echo "Please run sudo nixos-generate-config --root /mnt --no-filesystems"
  echo "Alternatively, run sudo nixos-generate-config --root / --no-filesystems"
  exit 1
fi
