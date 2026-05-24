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
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  boot.swraid.enable = true;
  boot.swraid.mdadmConf = ''
    MAILADDR root
    ARRAY /dev/md/md2 metadata=1.2 name=md2 UUID=5cc9078a:426e1dcb:06756778:9c57194d
    ARRAY /dev/md/md3 metadata=1.2 name=md3 UUID=30756e26:dec79c67:dc178d4d:43de828d
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
  networking.useDHCP = false;
  networking.useNetworkd = true;

  systemd.network.enable = true;
  systemd.network.networks."10-ovh-primary" = {
    matchConfig.MACAddress = "a0:42:3f:4d:c1:04";

    networkConfig = {
      DHCP = "ipv4";
      IPv6AcceptRA = false;
    };

    address = [
      "2604:2dc0:100:6389::/64"
    ];

    routes = [
      {
        Gateway = "2604:2dc0:100:63ff:ff:ff:ff:ff";
        GatewayOnLink = true;
      }
    ];
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
