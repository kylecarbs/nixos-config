# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running `nixos-help`).

{ config, pkgs, ... }: {
  imports = [
    ./shared.nix
  ];

  services.xserver.dpi = 125;
  services.xserver.videoDrivers = [ "nvidia" ];
  # This is necessary for 144fps in Chrome!
  services.xserver.screenSection = ''
  Option         "nvidiaXineramaInfoOrder" "DFP-1"
  '';

  nixpkgs.overlays = [
    (import ../pkgs/google-chrome.nix)
  ];

  hardware.nvidia = {
    # helps with screen tearing
    modesetting.enable = true;
    open = false;
    nvidiaSettings = true;
  };

  environment.systemPackages = with pkgs; [
    zoom-us
    spotify
    slack
    google-chrome
  ];
}
