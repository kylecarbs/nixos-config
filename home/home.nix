{ pkgs, ... }:

let
  coder = pkgs.callPackage ../pkgs/coder.nix { };
  jetbrains-gateway = pkgs.callPackage ../pkgs/jetbrains-gateway.nix { };
in
{
  nixpkgs.config.allowUnfree = true;

  home.stateVersion = "22.05";

  home.packages = with pkgs; [
    alacritty
    betterbird-unwrapped
    go_1_20
    fish
    flameshot
    yarn
    htop
    nixpkgs-fmt
    bintools
    coder
    google-cloud-sdk
    graphviz
    nodejs-18_x
    tailscale
    bat
    jetbrains-gateway
    unzip
    git
    whois
    deno
    gnumake
    jq
    gh
    glxinfo
    vim
    htmlq
    gotools
    libnotify
    xorg.libxcvt
  ];

  programs.vscode = {
    enable = true;
    extensions = with pkgs.vscode-extensions; [
      streetsidesoftware.code-spell-checker
      golang.go
      zxh404.vscode-proto3
      ms-azuretools.vscode-docker
      usernamehw.errorlens
      eamodio.gitlens
      dbaeumer.vscode-eslint
      github.copilot
      github.vscode-pull-request-github
      hashicorp.terraform
      yzhang.markdown-all-in-one
      github.vscode-pull-request-github
      jnoortheen.nix-ide
      esbenp.prettier-vscode
      ms-vscode-remote.remote-ssh
      # coder.coder-remote
      foxundermoon.shell-format
    ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
      {
        name = "min-theme";
        publisher = "miguelsolorio";
        version = "1.5.0";
        sha256 = "sha256-DF/9OlWmjmnZNRBs2hk0qEWN38RcgacdVl9e75N8ZMY=";
      }
    ];
  };

  programs.fish = {
    enable = true;

    interactiveShellInit = builtins.readFile ./config.fish;
  };

  programs.rofi = {
    enable = true;
    theme = "Arc-Dark";
    extraConfig = {
      width = "20%";
    };
  };

  xdg.enable = true;
  xdg.configFile."i3/config".text = builtins.readFile ./i3;
  xdg.configFile."i3status/config".text = builtins.readFile ./i3status;

  # Add all of our binaries!
  home.file."bin" = {
    source = ../bin;
    target = ".bin";
  };
  home.sessionVariables = {
    PATH = "$HOME/.bin:$PATH";
  };
}
