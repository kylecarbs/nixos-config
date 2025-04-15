{ pkgs, i3BarHeight ? null, ... }:

let
  coderMainline = (pkgs.coder.override {
    # Stay on the edge!
    channel = "mainline";
  }).overrideAttrs (oldAttrs: {
    postInstall = ":";
  });
  cursorMainline = pkgs.code-cursor.overrideAttrs (oldAttrs: rec {
    version = "0.48.9";
    src = pkgs.appimageTools.wrapType2 {
      inherit (oldAttrs) pname;
      inherit version;
      src = if pkgs.stdenv.hostPlatform.system == "x86_64-linux" then pkgs.fetchurl {
        # https://www.cursor.com/api/download?platform=linux-x64&releaseTrack=latest
        url = "https://downloads.cursor.com/production/7d6318dfcfbf7c12a87e33c06978f23167a6de3c/linux/x64/Cursor-0.48.2-x86_64.AppImage";
        hash = "sha256-OXL9C+Gnq8nrjCjvZxcHLKkyoK1BRsE+0J61j92HFok=";
      } else if pkgs.stdenv.hostPlatform.system == "aarch64-linux" then pkgs.fetchurl {
        # https://www.cursor.com/api/download?platform=linux-arm64&releaseTrack=latest
        url = "https://downloads.cursor.com/production/61e99179e4080fecf9d8b92c6e2e3e00fbfb53f4/linux/arm64/Cursor-0.48.9-aarch64.AppImage";
        hash = "sha256-RMDYoQSIO0jukhC5j1TjpwCcK0tEnvoVpXbFOxp/K8o=";
      } else (throw "Unsupported system: ${pkgs.stdenv.hostPlatform.system}");
    };
  });
  devcontainer-cli = pkgs.callPackage ../pkgs/devcontainer-cli.nix { };
  jetbrains-gateway = pkgs.callPackage ../pkgs/jetbrains-gateway.nix { };

  vscodeExtensions = builtins.fromJSON (builtins.readFile ./vscode-extensions.json);
  vscodeSettings = builtins.fromJSON (builtins.readFile ./vscode-settings.json);

  i3config = builtins.readFile ./config/i3;
in
{
  home.stateVersion = "22.05";

  home.packages = with pkgs; [
    bat
    bun
    cargo
    coderMainline
    cursorMainline
    deno
    dig
    fish
    gcc
    git
    git-lfs
    glxinfo
    gnumake
    go_1_23
    goreleaser
    (google-cloud-sdk.withExtraComponents
      ([ google-cloud-sdk.components.gke-gcloud-auth-plugin ]))
    gotools
    graphviz
    htmlq
    htop
    # jetbrains-gateway
    jq
    kubectl
    libnotify
    ghostty
    nixpkgs-fmt
    nix-prefetch-docker
    nixos-generators
    nodejs_23
    openssl.dev
    portaudio
    pkg-config

    rustc
    simplescreenrecorder
    skopeo
    sqlc
    tailscale
    terraform
    unzip
    vim
    vsce
    whois
    xorg.libxcvt
    yarn

    signal-desktop

    # Language servers
    gopls
    nodePackages.typescript-language-server
  ];

  programs.vscode = {
    enable = false;
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

  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    extraConfig = ''
      set number
      set relativenumber
      set expandtab
      set tabstop=2
      set shiftwidth=2
      set smartindent
      set termguicolors
      
      " Set leader key to space
      let mapleader = " "
      
      " Enable mouse support
      set mouse=a
      
      " Enable clipboard support
      set clipboard+=unnamedplus
    '';
    plugins = with pkgs.vimPlugins; [
      tokyonight-nvim
      nvim-tree-lua
      nvim-lspconfig
      nvim-cmp
      cmp-nvim-lsp
      copilot-vim
      (nvim-treesitter.withPlugins (plugins: with plugins; [
        tree-sitter-go
        tree-sitter-typescript
        tree-sitter-javascript
        tree-sitter-html
        tree-sitter-json
        tree-sitter-nix
      ]))
      vim-fugitive
      telescope-nvim
    ];
  };

  programs.gh = {
    enable = true;
    gitCredentialHelper = {
      enable = true;
    };
  };

  programs.git = {
    enable = true;
    lfs.enable = true;

    userName = "Kyle Carberry";
    userEmail = "kyle@carberry.com";

    aliases = {
      p = "push -u origin HEAD";
      c = "checkout";
    };

    extraConfig = {
      push.autoSetupRemote = true;
      init.defaultBranch = "main";
      core.editor = "cursor --wait";
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
  xdg.configFile."i3/config".text =
    if i3BarHeight != null
    then
      builtins.replaceStrings [ "# height replacer" ]
        [ "height ${toString i3BarHeight}" ]
        i3config else i3config;
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
  home.file.".local/bin/ams".source = ../bin/ams;
  home.file.".local/bin/chat".source = ../bin/chat;
  home.file.".local/bin/dmenu_emoji".source = ../bin/dmenu_emoji;
  home.file.".local/bin/git-hf".source = ../bin/git-hf;
  home.file.".local/bin/mypulls".source = ../bin/mypulls;
  home.file.".local/bin/notion".source = ../bin/notion;
  home.file.".local/bin/superautopets".source = ../bin/superautopets;
  home.file.".local/bin/nix-vscode-extensions".source = ../bin/nix-vscode-extensions;
  home.file.".config/ghostty/config".source = ./config/ghostty;
}
