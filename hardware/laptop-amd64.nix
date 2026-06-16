# Dell XPS 14" — placeholder until nixos-generate-config fills in UUIDs.
# After booting the installer, run:
#   sudo nixos-generate-config --root /mnt
# Then copy the relevant hardware bits (UUIDs, filesystems) into this file.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
      ../hosts/configuration.nix
    ];

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "thunderbolt" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  networking.networkmanager = {
    enable = true;
    wifi.powersave = false;
  };

  # TODO: Fill in after nixos-generate-config
  # fileSystems."/" =
  #   { device = "/dev/disk/by-uuid/XXXX";
  #     fsType = "ext4";
  #   };
  #
  # boot.initrd.luks.devices."luks-XXXX".device = "/dev/disk/by-uuid/XXXX";
  # boot.initrd.luks.devices."luks-XXXX".device = "/dev/disk/by-uuid/XXXX";
  #
  # fileSystems."/boot" =
  #   { device = "/dev/disk/by-uuid/XXXX";
  #     fsType = "vfat";
  #     options = [ "fmask=0077" "dmask=0077" ];
  #   };
  #
  # swapDevices =
  #   [ { device = "/dev/disk/by-uuid/XXXX"; } ];

  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  nixpkgs.overlays = [
    (import ../overlays/google-chrome.nix)
  ];

  services.logind.lidSwitch = "suspend";

  services.hardware.bolt.enable = true;

  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = 0;

      SOUND_POWER_SAVE_ON_AC = 0;
      SOUND_POWER_SAVE_ON_BAT = 1;

      START_CHARGE_THRESH_BAT0 = 40;
      STOP_CHARGE_THRESH_BAT0 = 80;

      RUNTIME_PM_ON_AC = "on";
      RUNTIME_PM_ON_BAT = "auto";
    };
  };

  services.xserver = {
    dpi = 160;
  };

  environment.systemPackages = with pkgs; [
    blueman
    google-chrome
    spotify
    slack
    zoom-us
  ];
  environment.variables.BROWSER = "google-chrome";
}
