# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running `nixos-help`).

{ config, pkgs, ... }: {
  imports = [
    ./shared.nix
  ];

  services.xserver.dpi = 125;
  services.xserver.videoDrivers = [ "nvidia" ];
  services.xserver.serverLayoutSection = ''
  Option         "Xinerama" "0"
  '';
  services.xserver.monitorSection = ''
  HorizSync       250.0 - 250.0
  VertRefresh     48.0 - 144.0
  Option         "DPMS"
  '';
  services.xserver.screenSection = ''
  Option         "nvidiaXineramaInfoOrder" "DFP-1"
  Option         "metamodes" "3840x1600_144 +0+0"
  Option         "SLI" "Off"
  Option         "MultiGPU" "Off"
  Option         "BaseMosaic" "off"
  '';
  environment.etc."X11/xorg.conf".source = ./dev-xorg.conf;

  nixpkgs.overlays = [
    (import ../pkgs/google-chrome.nix)
  ];

  hardware.nvidia = {
    modesetting.enable = true;
    open = false;
    nvidiaSettings = true;
  };
  hardware.opengl.driSupport = true;

  environment.variables = {
    CLUTTER_DEFAULT_FPS = "144";
    __GL_SYNC_DISPLAY_DEVICE = "DP-0";
    __GL_SYNC_TO_VBLANK = "0";
  };

  environment.systemPackages = with pkgs; [
    zoom-us
    spotify
    slack
    google-chrome
  ];
}
