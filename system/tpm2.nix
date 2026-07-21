# tpm2.nix

{
  security.tpm2 = {
    enable = true; # loads tpm2-tools and udev rules
    pkcs11.enable = true; # exposes TPM2 via PKCS#11, used by some enrollment tools
    tctiEnvironment.enable = true; # sets TPM2TOOLS_TCTI env var system-wide
  };
}
