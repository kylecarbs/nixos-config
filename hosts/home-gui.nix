{ pkgs, swayBarHeight ? null, swayModKey ? "Mod4", swayExtraConfig ? "", ... }:

let
  base = import ./home.nix { inherit pkgs; };

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

  vscodeExtensions = builtins.fromJSON (builtins.readFile ./vscode-extensions.json);
  swayConfig = builtins.readFile ./config/sway;
in
pkgs.lib.recursiveUpdate base {
  home.packages = base.home.packages ++ (with pkgs; [
    cursorMainline
    mesa-demos
    libnotify
    ghostty
    signal-desktop
  ]);

  programs.fish.interactiveShellInit = base.programs.fish.interactiveShellInit + ''

    alias code="cursor"
  '';

  programs.git.settings.core.editor = "cursor --wait";

  programs.vscode = {
    enable = false;
    # To add new extensions, add them to the vscode-extensions.json file and
    # then run `make update-vscode-extensions`.
    profiles.default.extensions =
      (pkgs.vscode-utils.extensionsFromVscodeMarketplace vscodeExtensions) ++ [
        # Terraform has a custom build script!
        pkgs.vscode-extensions.hashicorp.terraform
      ];
  };

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

  xdg.configFile."sway/config".text =
    let
      configWithHeight =
        if swayBarHeight != null
        then
          builtins.replaceStrings [ "# height replacer" ]
            [ "height ${toString swayBarHeight}" ]
            swayConfig
        else swayConfig;
      configWithExtra = builtins.replaceStrings [ "# extra config replacer" ]
        [ swayExtraConfig ]
        configWithHeight;
    in
    builtins.replaceStrings [ "set $mod Mod4" ]
      [ "set $mod ${swayModKey}" ]
      configWithExtra;
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
  home.file.".local/bin/nix-vscode-extensions".source = ../bin/nix-vscode-extensions;
  home.file.".config/ghostty/config".source = ./config/ghostty;
}
