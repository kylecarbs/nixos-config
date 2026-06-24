{ config, lib, pkgs, ... }:

let
  cfg = config.kyle.gui;

  apple-emoji = pkgs.callPackage ../pkgs/apple-emoji.nix { };
  apple-fonts = pkgs.callPackage ../pkgs/apple-fonts.nix { };
  flameshotWayland = pkgs.flameshot.overrideAttrs (oldAttrs: {
    # Flameshot's grim path needs explicit output-scale handling on Wayland so
    # HiDPI screenshots crop the selected monitor instead of physical pixels.
    patches = (oldAttrs.patches or [ ]) ++ [
      ../pkgs/flameshot-grim-device-pixel-ratio.patch
    ];
  });

  cursorMainline = pkgs.code-cursor.overrideAttrs (oldAttrs: rec {
    version = "3.3.30";
    src = pkgs.appimageTools.extract {
      inherit (oldAttrs) pname;
      inherit version;
      src =
        if pkgs.stdenv.hostPlatform.system == "x86_64-linux" then
          pkgs.fetchurl
            {
              # https://www.cursor.com/api/download?platform=linux-x64&releaseTrack=latest
              url = "https://downloads.cursor.com/production/3dc559280adc5f931ade8e25c7b85393842acf34/linux/x64/Cursor-3.3.30-x86_64.AppImage";
              hash = "sha256-dx/ddEBUK6lHn98nP/k907M8inOvjOUHUzyJFLFmCRs=";
            }
        else if pkgs.stdenv.hostPlatform.system == "aarch64-linux" then
          pkgs.fetchurl
            {
              # https://www.cursor.com/api/download?platform=linux-arm64&releaseTrack=latest
              url = "https://downloads.cursor.com/production/031e7e0ff1e2eda9c1a0f5df67d44053b059c5df/linux/arm64/Cursor-1.2.1-aarch64.AppImage";
              hash = "sha256-Otg+NyW1DmrqIb0xqZCfJ4ys61/DBOQNgaAR8PMOCfg=";
            }
        else (throw "Unsupported system: ${pkgs.stdenv.hostPlatform.system}");
    };
    sourceRoot = "${oldAttrs.pname}-${version}-extracted/usr/share/cursor";
  });

  swayConfig = builtins.readFile ./config/sway;

  configWithHeight =
    if cfg.swayBarHeight != null
    then
      builtins.replaceStrings [ "# height replacer" ]
        [ "height ${toString cfg.swayBarHeight}" ]
        swayConfig
    else swayConfig;
  configWithExtra = builtins.replaceStrings [ "# extra config replacer" ]
    [ cfg.swayExtraConfig ]
    configWithHeight;
  configuredSwayConfig = builtins.replaceStrings [ "set $mod Mod4" ]
    [ "set $mod ${cfg.swayModKey}" ]
    configWithExtra;
in
{
  imports = [
    ./base.nix
  ];

  options.kyle.gui = {
    swayBarHeight = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      default = null;
      description = "Optional Sway bar height override for this GUI host.";
    };

    swayModKey = lib.mkOption {
      type = lib.types.str;
      default = "Mod4";
      description = "Sway modifier key for this GUI host.";
    };

    swayExtraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Additional Sway config for this GUI host.";
    };

    pointerCursorSize = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      default = null;
      description = "Optional pointer cursor size override for this GUI host.";
    };
  };

  config = {
    nixpkgs.config.cudaSupport = true;

    boot.loader.efi.efiSysMountPoint = "/boot";

    networking.networkmanager.enable = true;
    networking.networkmanager.settings = {
      device = {
        "wifi.scan-rand-mac-address" = "no";
      };
      connection = {
        "wifi.cloned-mac-address" = "permanent";
      };
    };
    environment.etc."NetworkManager/conf.d/10-wifi.conf".text = ''
      [connection]
      wifi.powersave=2
    '';

    time.timeZone = null;
    services.automatic-timezoned.enable = true;

    services.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    hardware.graphics = {
      enable = true;
    };

    users.users.kyle.extraGroups = [ "networkmanager" "adbusers" ];

    # Workaround for GNOME autologin: https://github.com/NixOS/nixpkgs/issues/103746#issuecomment-945091229
    systemd.services."getty@tty1".enable = false;
    systemd.services."autovt@tty1".enable = false;

    # Useful for VS Code storing credentials.
    services.gnome.gnome-keyring.enable = true;

    location.provider = "geoclue2";

    services.displayManager = {
      autoLogin.enable = true;
      autoLogin.user = "kyle";
      defaultSession = "sway";
    };

    programs.sway = {
      enable = true;
      xwayland.enable = true;
      extraOptions = [ "--unsupported-gpu" ];
      extraPackages = with pkgs; [
        dunst
        brightnessctl
        flameshotWayland
        gammastep
        grim
        i3status
        libnotify
        networkmanagerapplet
        rofi
        slurp
        swayidle
        swaylock
        wdisplays
        wf-recorder
        wl-clipboard

        # Required for py3status to work.
        (python3.withPackages (p: with p; [
          google-api-python-client
          httplib2
          py3status
          python-dateutil
        ]))
      ];
    };

    xdg.portal = {
      enable = true;
      wlr.enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      config.common.default = [ "wlr" "gtk" ];
    };

    environment.sessionVariables = {
      NIXOS_OZONE_WL = "1";
      MOZ_ENABLE_WAYLAND = "1";
      QT_QPA_PLATFORM = "wayland";
      XDG_CURRENT_DESKTOP = "sway";
      XDG_SESSION_DESKTOP = "sway";
    };

    # Keep X enabled for LightDM and Xwayland compatibility.
    services.xserver = {
      enable = true;

      xkb = {
        variant = "";
        layout = "us";
      };

      desktopManager = {
        xterm.enable = false;
      };
    };

    # Touchpad configuration for Framework laptop and Sway sessions.
    services.libinput = {
      enable = true;
      touchpad = {
        tapping = true;
        clickMethod = "clickfinger";
      };
    };

    services.postgresql = {
      enable = false;
      ensureDatabases = [ "coder" ];
      enableTCPIP = true;
      authentication = pkgs.lib.mkOverride 10 ''
        #type database  DBuser  auth-method
        local all       all     trust
      '';
      settings = {
        unix_socket_directories = "/var/run/postgresql";
      };
    };

    # Makes Chrome use dark mode by default.
    environment.etc."xdg/gtk-3.0/settings.ini".text = ''
      [Settings]
      gtk-application-prefer-dark-theme=1
    '';
    environment.localBinInPath = true;

    fonts.packages = with pkgs; [ apple-emoji apple-fonts fira-code ];
    # Replace the gross Linux emojis with pretty Apple ones.
    fonts.fontconfig.defaultFonts.emoji = [ "Apple Color Emoji" ];

    home-manager.users.kyle = { ... }: {
      home.packages = with pkgs; [
        cursorMainline
        mesa-demos
        libnotify
        ghostty
        pavucontrol
        signal-desktop
      ];

      programs.fish.interactiveShellInit = lib.mkAfter ''

        alias code="cursor"
      '';

      programs.git.settings.core.editor = lib.mkForce "cursor --wait";

      programs.rofi = {
        enable = true;
        package = pkgs.rofi;
        theme = "Arc-Dark";
        font = "Fira Code 14";
      };

      dconf = {
        enable = true;
        settings."org/gnome/desktop/interface" = {
          color-scheme = "prefer-dark";
          gtk-theme = "Adwaita-dark";
        };
      };

      gtk = {
        enable = true;
        theme = {
          package = pkgs.gnome-themes-extra;
          name = "Adwaita-dark";
        };
        gtk3.extraConfig = {
          gtk-application-prefer-dark-theme = 1;
        };
        gtk4.theme = {
          package = pkgs.gnome-themes-extra;
          name = "Adwaita-dark";
        };
        gtk4.extraConfig = {
          gtk-application-prefer-dark-theme = 1;
        };
      };

      xdg.configFile."sway/config".text = configuredSwayConfig;
      xdg.configFile."py3status/config".text = builtins.readFile ./config/py3status;
      xdg.configFile."flameshot/flameshot.ini" = {
        force = true;
        text = ''
          [General]
          disabledGrimWarning=true
          drawThickness=18
          savePath=/home/kyle/Downloads
          useGrimAdapter=true
        '';
      };

      home.pointerCursor = {
        x11.enable = true;
        gtk.enable = true;
        package = pkgs.vanilla-dmz;
        name = "Vanilla-DMZ";
      } // lib.optionalAttrs (cfg.pointerCursorSize != null) {
        size = cfg.pointerCursorSize;
      };

      xresources.extraConfig = ''
        Xft.autohint: false
        Xft.antialias: true
        Xft.hinting: true
        Xft.hintstyle: hintfull
        Xft.rgba: rgb
        Xft.lcdfilter: lcddefault
      '';

      home.file.".local/bin/rd".source = ../bin/rd;
      home.file.".local/bin/rmux".source = ../bin/rmux;
      home.file.".local/bin/lmux".source = ../bin/lmux;
      home.file.".local/bin/chat".source = ../bin/chat;
      home.file.".local/bin/dmenu_emoji".source = ../bin/dmenu_emoji;
      home.file.".local/bin/sway_focused_flameshot".source = ../bin/sway_focused_flameshot;
      home.file.".local/bin/sway_workspace_next_output".source = ../bin/sway_workspace_next_output;
      home.file.".local/bin/notion".source = ../bin/notion;
      home.file.".local/bin/superautopets".source = ../bin/superautopets;
      home.file.".config/ghostty/config".source = ./config/ghostty;
    };
  };
}
