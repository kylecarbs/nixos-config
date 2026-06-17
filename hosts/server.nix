{ config, lib, pkgs, ... }:

let
  publicInterface = "eno1";

  sshKeys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCsaay9uprFzsnYG308Ule9vLDdKRJ1cf15ac5SBw3aeRp1bBsEbQaybyTGkFIA2JC2Na1EJS5gi+Y7LOdVGpLJ+JeMrhvVM+wu2tZoS7LdnzhZgtYSNCoCcJsr1P5gSx/1ydJzxUHu/t8DPmN7gUmF4pslAvBZAhwFFlcncgMgwXnLhSl6L4EQrULM+dNYeqRkNg/pl5ilh3rgSpswOd3Dn11EI4dTBwittFBXtV6XvXScK24BRGQKyEun9bun8hANCbgxKTZ/WAXSSChfEGrBBVgY86IoKZiwC7WaiMvd8OtNS6iNnlN0TJOZyyYF1a+m4rJgcLT/M+Q+orBoVYPzPBqY46E5ZGMKNNo3PovdTeT9/uD/NXlQziuwdxURfXWX/7ZSidVpYPHtVdukd9qYUWUyQDE97CNk88JpvBBWQfee3m/2OOOm5yjzwtF27Th65N7NtKMtDNitzg2vurEqbxLTWR69TckOjhOKswA76vps8TAQjigpUSkHBDj8xds= kyle@desktop"
  ];

  tailscaleServeServices = {
    polydex = {
      endpoints = {
        "tcp:8123" = "tcp://127.0.0.1:8123";
        "tcp:9000" = "tcp://127.0.0.1:9000";
      };
      after = [ "docker.service" ];
      wants = [ "docker.service" ];
    };
    codex = {
      endpoints = {
        "tcp:80" = "tcp://127.0.0.1:18081";
      };
    };
  };

  mkTailscaleServeConfig = service: {
    version = "0.0.1";
    inherit (service) endpoints;
  };

  mkTailscaleServeService = name: service: {
    description = "Publish ${name} through Tailscale Service";
    after = [ "network-online.target" "tailscaled.service" ] ++ (service.after or [ ]);
    wants = [ "network-online.target" "tailscaled.service" ] ++ (service.wants or [ ]);
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.tailscale ];
    script = ''
      tailscale serve set-config --service=svc:${name} /etc/tailscale/${name}-service.json
      tailscale serve advertise svc:${name}
    '';
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecReload = "${pkgs.writeShellScript "tailscale-${name}-reload" ''
        set -euo pipefail
        ${pkgs.tailscale}/bin/tailscale serve set-config --service=svc:${name} /etc/tailscale/${name}-service.json
        ${pkgs.tailscale}/bin/tailscale serve advertise svc:${name}
      ''}";
      ExecStop = "${pkgs.writeShellScript "tailscale-${name}-stop" ''
        ${pkgs.tailscale}/bin/tailscale serve drain svc:${name} || true
      ''}";
    };
  };
in
{
  imports = [
    ./base.nix
  ];

  time.timeZone = "America/New_York";

  nix.gc.options = "--delete-older-than 7d";

  users.groups.kyle = {
    gid = 1000;
  };

  users.users.kyle = {
    isNormalUser = true;
    uid = 1000;
    group = "kyle";
    description = "Kyle Carberry";
    home = "/home/kyle";
    openssh.authorizedKeys.keys = sshKeys;
  };

  users.users.root.openssh.authorizedKeys.keys = sshKeys;

  services.openssh = {
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };

  home-manager.useUserPackages = true;

  environment.etc = lib.mapAttrs'
    (name: service:
      lib.nameValuePair "tailscale/${name}-service.json" {
        text = builtins.toJSON (mkTailscaleServeConfig service);
      })
    tailscaleServeServices;

  systemd.services = lib.mapAttrs'
    (name: service:
      lib.nameValuePair "tailscale-${name}" (mkTailscaleServeService name service))
    tailscaleServeServices;

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 22 ];
    extraCommands = ''
      iptables -w -I nixos-fw 1 -i ${publicInterface} -p tcp -m conntrack --ctstate NEW -m tcp ! --dport 22 -j DROP
      ip6tables -w -I nixos-fw 1 -i ${publicInterface} -p tcp -m conntrack --ctstate NEW -m tcp ! --dport 22 -j DROP

      iptables -w -N DOCKER-USER 2>/dev/null || true
      iptables -w -C FORWARD -j DOCKER-USER 2>/dev/null || iptables -w -I FORWARD 1 -j DOCKER-USER
      iptables -w -C DOCKER-USER -i ${publicInterface} -p tcp -m conntrack --ctstate NEW -j DROP 2>/dev/null || iptables -w -I DOCKER-USER 1 -i ${publicInterface} -p tcp -m conntrack --ctstate NEW -j DROP

      ip6tables -w -N DOCKER-USER 2>/dev/null || true
      ip6tables -w -C FORWARD -j DOCKER-USER 2>/dev/null || ip6tables -w -I FORWARD 1 -j DOCKER-USER
      ip6tables -w -C DOCKER-USER -i ${publicInterface} -p tcp -m conntrack --ctstate NEW -j DROP 2>/dev/null || ip6tables -w -I DOCKER-USER 1 -i ${publicInterface} -p tcp -m conntrack --ctstate NEW -j DROP
    '';
    extraStopCommands = ''
      iptables -w -D nixos-fw -i ${publicInterface} -p tcp -m conntrack --ctstate NEW -m tcp ! --dport 22 -j DROP 2>/dev/null || true
      ip6tables -w -D nixos-fw -i ${publicInterface} -p tcp -m conntrack --ctstate NEW -m tcp ! --dport 22 -j DROP 2>/dev/null || true
    '';
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
