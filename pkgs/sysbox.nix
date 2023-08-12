{ stdenv, config, pkgs, lib, ... }:

let
  cfg = config.services.sysbox;
  sysboxDeb = pkgs.stdenv.mkDerivation rec {
    pname = "sysbox-ce";
    version = "0.6.2";

    src = pkgs.fetchurl {
      url = "https://downloads.nestybox.com/sysbox/releases/v${version}/${pname}_${version}-0.linux_${{
      "x86_64-linux"  = "amd64";
      "aarch64-linux" = "arm64";
    }.${pkgs.stdenv.system}}.deb";
      sha256 = {
        "x86_64-linux" = "sha256-/Sh/LztaBytiw3j54e7uqizK0iu0jLOB0w2MhVxRtAE=";
        "aarch64-linux" = "sha256-ZENsEgJAmKLjsM0WR3Mss6GxQVkXRY9vPgpW27TC5zc=";
      }.${pkgs.stdenv.system};
    };

    buildInputs = [ pkgs.dpkg pkgs.xz pkgs.lsb-release ];

    unpackPhase = ''
      ar x $src
      mkdir $out
      tar -xvf ./data.tar.xz -C $out
    '';

    installPhase = "true";
  };
in
{
  options.services.sysbox = {
    enable = lib.mkEnableOption "sysbox service";
  };

  config = lib.mkIf cfg.enable {
    boot.kernel.sysctl."kernel.unprivileged_userns_clone" = "1";

    virtualisation.docker = {
      enable = true;
      extraOptions = "--add-runtime sysbox-runc=${sysboxDeb}/usr/bin/sysbox-runc";
    };

    systemd.services.sysbox-mgr = {
      description = "sysbox manager service";
      path = [ pkgs.rsync pkgs.kmod pkgs.iptables ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${sysboxDeb}/usr/bin/sysbox-mgr";
        Type = "simple";
        NotifyAccess = "main";
        TimeoutStartSec = 45;
        TimeoutStopSec = 90;
        OOMScoreAdjust = "-500";
        LimitNOFILE = "infinity";
        LimitNPROC = "infinity";
      };
    };

    systemd.services.sysbox-fs = {
      description = "sysbox-fs (part of the Sysbox container runtime)";
      wantedBy = [ "multi-user.target" ];
      after = [ "sysbox-mgr.service" ];
      path = [ pkgs.fuse ];
      serviceConfig = {
        ExecStart = "${sysboxDeb}/usr/bin/sysbox-fs";
        Type = "simple";
        NotifyAccess = "main";
        TimeoutStartSec = 10;
        TimeoutStopSec = 10;
        OOMScoreAdjust = "-500";
        LimitNOFILE = "infinity";
        LimitNPROC = "infinity";
      };
    };
  };
}
