{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ../hosts/server.nix
  ];

  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "ahci"
    "usbhid"
    "usb_storage"
    "sd_mod"
  ];

  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  boot.swraid.enable = true;
  boot.swraid.mdadmConf = ''
    MAILADDR root
    # Append ARRAY lines from:
    #   mdadm --detail --scan
  '';

  boot.loader.grub = {
    enable = true;
    device = "nodev";
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  boot.loader.efi = {
    canTouchEfiVariables = false;
    efiSysMountPoint = "/boot/efi";
  };

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/218a8524-a52b-47ed-88f8-ca3daa355f7f";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/24ce6a00-3fa2-4d7b-b470-2717ef486068";
    fsType = "ext4";
  };

  fileSystems."/boot/efi" = {
    device = "/dev/disk/by-uuid/F919-4153";
    fsType = "vfat";
    options = [ "umask=0077" ];
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/b1ef58dc-bc65-4349-96c6-17d1d6fd3620"; }
    { device = "/dev/disk/by-uuid/68867b6d-3cf2-431f-b1ef-6e5c410621d5"; }
  ];

  networking.hostName = "dev";

  # Replace this with explicit OVH network config if the audit shows static networking.
  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
