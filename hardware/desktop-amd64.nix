{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [
      (modulesPath + "/installer/scan/not-detected.nix")
      ../hosts/configuration.nix
    ];

  boot.initrd.availableKernelModules = [ "nvme" "ahci" "xhci_pci" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.kernel.sysctl."net.ipv4.ip_forward" = 1;
  boot.kernel.sysctl."net.ipv6.conf.all.forwarding" = 1;
  boot.extraModulePackages = [ ];
  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
    efiSupport = true;
    efiInstallAsRemovable = true;
    # Required for scanning my dual-boot Windows!
    useOSProber = true;
    # Fixes lagginess because of 4K Grub!
    gfxmodeEfi = "1920x1080x32";
  };

  fileSystems."/" =
    {
      device = "/dev/disk/by-uuid/2957ec93-22c6-4f3a-97b5-a653f06d2b05";
      fsType = "ext4";
    };

  boot.initrd.luks.devices."luks-0804677f-9cdb-401d-8faa-63c59ba0b063".device = "/dev/disk/by-uuid/0804677f-9cdb-401d-8faa-63c59ba0b063";

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-uuid/2439-CDD3";
      fsType = "vfat";
    };

  swapDevices = [ ];

  networking.useDHCP = false;
  networking.interfaces.wlp41s0.useDHCP = true;
  networking.hostName = "desktop";

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # Makes the scaling look nice on my display!
  services.xserver.dpi = 125;
  services.xserver.videoDrivers = [ "nvidia" ];
  # This is necessary for 144fps in Chrome!
  services.xserver.screenSection = ''
    Option         "nvidiaXineramaInfoOrder" "DFP-1"
  '';
  # Required for Cuda!
  systemd.services.nvidia-control-devices = {
    wantedBy = [ "multi-user.target" ];
    serviceConfig.ExecStart = "${pkgs.linuxPackages.nvidia_x11.bin}/bin/nvidia-smi";
  };

  nixpkgs.overlays = [
    (import ../overlays/google-chrome.nix)
  ];

  hardware.nvidia = {
    # Fixes screen tearing!
    modesetting.enable = true;
    open = false;
    nvidiaSettings = true;
  };

  # DHCP was adding a local nameserver which was causing DNS issues.
  environment.etc = {
    "resolv.conf".text = ''
      nameserver 8.8.8.8
      nameserver 1.1.1.1
    '';
  };

  # These packages are only available on amd64.
  environment.systemPackages = with pkgs; [
    figma-linux
    google-chrome
    spotify
    slack
    zoom-us
  ];
  environment.variables.BROWSER = "google-chrome";
}
