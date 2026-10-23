# tpm2.nix
{ lib, ... }:

{
  security.tpm2 = {
    enable = lib.mkDefault true; # loads tpm2-tools and udev rules
    pkcs11.enable = lib.mkDefault true; # exposes TPM2 via PKCS#11, used by some enrollment tools
    tctiEnvironment.enable = lib.mkDefault true; # sets TPM2TOOLS_TCTI env var system-wide
  };
}
