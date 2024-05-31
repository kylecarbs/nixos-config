{ pkgs, ... }:

let
  coder = pkgs.coder.override {
    # Stay on the edge!
    channel = "mainline";
  };
  devcontainer-cli = pkgs.callPackage ../pkgs/devcontainer-cli.nix { };
  jetbrains-gateway = pkgs.callPackage ../pkgs/jetbrains-gateway.nix { };

  vscodeExtensions = builtins.fromJSON (builtins.readFile ./vscode-extensions.json);
  vscodeSettings = builtins.fromJSON (builtins.readFile ./vscode-settings.json);
in
{
  home.stateVersion = "22.05";

  home.packages = with pkgs; [
    bat
    betterbird-unwrapped
    bun
    coder
    deno
    dig
    fish
    gcc
    git
    glxinfo
    gnumake
    go_1_22
    goreleaser
    google-cloud-sdk
    gotools
    graphviz
    htmlq
    htop
    jetbrains-gateway
    jq
    libnotify
    mitmproxy
    nixpkgs-fmt
    nix-prefetch-docker
    nodejs-18_x
    portaudio
    pkg-config
    devpod-desktop
    simplescreenrecorder
    skopeo
    sqlc
    sqlite-vss
    tailscale
    tesseract
    terraform
    unzip
    vim
    wails
    whois
    xorg.libxcvt
    yarn
  ];

  programs.alacritty = {
    enable = true;
    settings = {
      font = {
        size = 16;
      };
    };
  };

  programs.vscode = {
    enable = true;
    # To add new extensions, add them to the vscode-extensions.json file and
    # then run `make update-vscode-extensions`.
    extensions = (pkgs.vscode-utils.extensionsFromVscodeMarketplace vscodeExtensions) ++ [
      # Terraform has a custom build script!
      pkgs.vscode-extensions.hashicorp.terraform
    ];
  };

  programs.fish = {
    enable = true;

    interactiveShellInit = builtins.readFile ./config/config.fish;
  };

  programs.gh = {
    enable = true;
    gitCredentialHelper = {
      enable = true;
    };
  };

  programs.git = {
    enable = true;

    userName = "Kyle Carberry";
    userEmail = "kyle@carberry.com";

    aliases = {
      p = "push -u origin HEAD";
      c = "checkout";
    };

    extraConfig = {
      push.autoSetupRemote = true;
      init.defaultBranch = "main";
      core.editor = "code --wait";
    };
  };

  programs.rofi = {
    enable = true;
    theme = "Arc-Dark";
    font = "Fira Code 14";
  };

  services.flameshot = {
    enable = true;
  };

  xdg.enable = true;
  xdg.configFile."i3/config".text = builtins.readFile ./config/i3;
  xdg.configFile."i3status/config".text = builtins.readFile ./config/i3status;

  home.pointerCursor = {
    x11.enable = true;
    package = pkgs.vanilla-dmz;
    name = "Vanilla-DMZ";
  };

  xresources.extraConfig = ''
    Xft.autohint: true
    Xft.antialias: true
    Xft.hinting: true
    Xft.hintstyle: hintslight
    Xft.rgba: rgb
    Xft.lcdfilter: lcddefault
  '';

  # Add all of our binaries!
  home.file.".local/bin/chatgpt".source = ../bin/chatgpt;
  home.file.".local/bin/dmenu_emoji".source = ../bin/dmenu_emoji;
  home.file.".local/bin/git-hf".source = ../bin/git-hf;
  home.file.".local/bin/mypulls".source = ../bin/mypulls;
  home.file.".local/bin/notion".source = ../bin/notion;
  home.file.".local/bin/superautopets".source = ../bin/superautopets;
  home.file.".local/bin/nix-vscode-extensions".source = ../bin/nix-vscode-extensions;
}
