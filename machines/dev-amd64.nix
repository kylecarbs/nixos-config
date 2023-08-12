# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running `nixos-help`).

{ config, pkgs, ... }: {
  imports = [
    ./shared.nix
  ];

  services.xserver.dpi = 125;
  services.xserver.videoDrivers = [ "nvidia" ];
  services.xserver.monitorSection = ''
  VertRefresh     48.0 - 144.0
  '';
  services.xserver.screenSection = ''
  Option         "nvidiaXineramaInfoOrder" "DFP-1"
  Option         "metamodes" "3840x1600_144 +0+0"
  Option         "BaseMosaic" "off"
  '';
  environment.etc."X11/xorg.conf".source = ./dev-xorg.conf;

  nixpkgs.overlays = [
    (import ../pkgs/google-chrome.nix)
  ];

  hardware.nvidia = {
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
