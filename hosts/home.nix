{ pkgs, ... }:

let
  coder = pkgs.callPackage ../pkgs/coder.nix { };
  jetbrains-gateway = pkgs.callPackage ../pkgs/jetbrains-gateway.nix { };
in
{
  nixpkgs.config.allowUnfree = true;

  home.stateVersion = "22.05";

  home.packages = with pkgs; [
    bat
    betterbird-unwrapped
    bintools
    coder
    deno
    fish
    flameshot
    gh
    git
    glxinfo
    gnumake
    go_1_20
    google-cloud-sdk
    gotools
    graphviz
    htmlq
    htop
    jetbrains-gateway
    jq
    libnotify
    nixpkgs-fmt
    nodejs-18_x
    tailscale
    unzip
    vim
    whois
    xorg.libxcvt
    yarn
  ];

  programs.alacritty.enable = true;

  programs.vscode = {
    enable = true;
    extensions = with pkgs.vscode-extensions; [
      dbaeumer.vscode-eslint
      eamodio.gitlens
      esbenp.prettier-vscode
      foxundermoon.shell-format
      github.copilot
      github.vscode-pull-request-github
      github.vscode-pull-request-github
      golang.go
      hashicorp.terraform
      jnoortheen.nix-ide
      ms-azuretools.vscode-docker
      ms-vscode-remote.remote-ssh
      streetsidesoftware.code-spell-checker
      usernamehw.errorlens
      yzhang.markdown-all-in-one
      zxh404.vscode-proto3
    ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
      {
        name = "coder-remote";
        publisher = "coder";
        version = "0.1.19";
        sha256 = "sha256-Saw+D1haSGAq2bdlYjEjM/GF95eQmJEDXXB8VGQkXiE=";
      }
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

    interactiveShellInit = builtins.readFile ./config/config.fish;
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
  };

  xdg.enable = true;
  xdg.configFile."i3/config".text = builtins.readFile ./config/i3;
  xdg.configFile."i3status/config".text = builtins.readFile ./config/i3status;

  # Add all of our binaries!
  home.file.".local/bin/dmenu_emoji".source = ../bin/dmenu_emoji;
  home.file.".local/bin/git-hf".source = ../bin/git-hf;
  home.file.".local/bin/mypulls".source = ../bin/mypulls;
  home.file.".local/bin/notion".source = ../bin/notion;
  home.file.".local/bin/superautopets".source = ../bin/superautopets;
}
