{ config, lib, pkgs, ... }:

let
  sshKeys = [
    # Replace with your real public SSH key before installing.
    "ssh-ed25519 REPLACE_ME"
  ];
in
{
  nixpkgs.config.allowUnfree = true;

  i18n.defaultLocale = "en_CA.UTF-8";
  time.timeZone = "America/New_York";

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
    "impure-derivations"
    "ca-derivations"
  ];

  nix.gc = {
    automatic = true;
    randomizedDelaySec = "14m";
    options = "--delete-older-than 7d";
  };

  programs.fish.enable = true;

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc
    zlib
    openssl
  ];

  users.users.ubuntu = {
    isNormalUser = true;
    uid = 1000;
    description = "Kyle Carberry";
    extraGroups = [ "wheel" "docker" ];
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = sshKeys;
  };

  users.users.root.openssh.authorizedKeys.keys = sshKeys;

  security.sudo.wheelNeedsPassword = false;

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };

  services.chrony.enable = true;

  virtualisation.docker.enable = true;

  services.tailscale = {
    enable = true;
    useRoutingFeatures = "both";
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
  };

  environment.systemPackages = with pkgs; [
    curl
    git
    gnumake
    htop
    jq
    mdadm
    ripgrep
    vim
    wget
  ];

  system.stateVersion = "25.11";
}
