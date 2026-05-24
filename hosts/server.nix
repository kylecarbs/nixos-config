{ config, lib, pkgs, ... }:

let
  sshKeys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCsaay9uprFzsnYG308Ule9vLDdKRJ1cf15ac5SBw3aeRp1bBsEbQaybyTGkFIA2JC2Na1EJS5gi+Y7LOdVGpLJ+JeMrhvVM+wu2tZoS7LdnzhZgtYSNCoCcJsr1P5gSx/1ydJzxUHu/t8DPmN7gUmF4pslAvBZAhwFFlcncgMgwXnLhSl6L4EQrULM+dNYeqRkNg/pl5ilh3rgSpswOd3Dn11EI4dTBwittFBXtV6XvXScK24BRGQKyEun9bun8hANCbgxKTZ/WAXSSChfEGrBBVgY86IoKZiwC7WaiMvd8OtNS6iNnlN0TJOZyyYF1a+m4rJgcLT/M+Q+orBoVYPzPBqY46E5ZGMKNNo3PovdTeT9/uD/NXlQziuwdxURfXWX/7ZSidVpYPHtVdukd9qYUWUyQDE97CNk88JpvBBWQfee3m/2OOOm5yjzwtF27Th65N7NtKMtDNitzg2vurEqbxLTWR69TckOjhOKswA76vps8TAQjigpUSkHBDj8xds= kyle@desktop"
  ];

  polydexTailscaleServeConfig = {
    version = "0.0.1";
    endpoints = {
      "tcp:8123" = "tcp://127.0.0.1:8123";
      "tcp:9000" = "tcp://127.0.0.1:9000";
    };
  };
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

  users.groups.kyle = {
    gid = 1000;
  };

  users.users.kyle = {
    isNormalUser = true;
    uid = 1000;
    group = "kyle";
    description = "Kyle Carberry";
    extraGroups = [ "wheel" "docker" ];
    home = "/home/kyle";
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

  environment.etc."tailscale/polydex-service.json".text =
    builtins.toJSON polydexTailscaleServeConfig;

  systemd.services.tailscale-polydex = {
    description = "Publish Polydex ClickHouse through Tailscale Service";
    after = [ "network-online.target" "tailscaled.service" "docker.service" ];
    wants = [ "network-online.target" "tailscaled.service" "docker.service" ];
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.tailscale ];
    script = ''
      tailscale serve set-config --service=svc:polydex /etc/tailscale/polydex-service.json
      tailscale serve advertise svc:polydex
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecReload = "${pkgs.writeShellScript "tailscale-polydex-reload" ''
        set -euo pipefail
        ${pkgs.tailscale}/bin/tailscale serve set-config --service=svc:polydex /etc/tailscale/polydex-service.json
        ${pkgs.tailscale}/bin/tailscale serve advertise svc:polydex
      ''}";
      ExecStop = "${pkgs.writeShellScript "tailscale-polydex-stop" ''
        ${pkgs.tailscale}/bin/tailscale serve drain svc:polydex || true
      ''}";
    };
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
