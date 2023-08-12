# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running `nixos-help`).

{ config, pkgs, ... }: {
  imports = [
    ./shared.nix
  ];

  # Required for automating resizing with UTM.
  services.spice-vdagentd.enable = true;
  # The DPI has to be bigger for the smaller screen!
  services.xserver.dpi = 180;

  environment.systemPackages = with pkgs; [
    # Google Chrome isn't available on arm64
    chromium
  ];
}
