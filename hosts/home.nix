{ pkgs, i3BarHeight ? null, i3ModKey ? "Mod4", ... }:

let
  coderMainline = (pkgs.coder.override {
    # Stay on the edge!
    channel = "mainline";
  }).overrideAttrs (oldAttrs: {
    postInstall = ":";
  });
  cursorMainline = pkgs.code-cursor.overrideAttrs (oldAttrs: rec {
    version = "1.7.28";
    src = pkgs.appimageTools.wrapType2 {
      inherit (oldAttrs) pname;
      inherit version;
      src = if pkgs.stdenv.hostPlatform.system == "x86_64-linux" then pkgs.fetchurl {
        # https://www.cursor.com/api/download?platform=linux-x64&releaseTrack=latest
        url = "https://downloads.cursor.com/production/60d42bed27e5775c43ec0428d8c653c49e58e26a/linux/x64/Cursor-2.1.39-x86_64.AppImage";
        hash = "sha256-SsKhW8q/AzOn1HqykhwaVHyTVm+OqTUiFtda7XDiAho=";
      } else if pkgs.stdenv.hostPlatform.system == "aarch64-linux" then pkgs.fetchurl {
        # https://www.cursor.com/api/download?platform=linux-arm64&releaseTrack=latest
        url = "https://downloads.cursor.com/production/031e7e0ff1e2eda9c1a0f5df67d44053b059c5df/linux/arm64/Cursor-1.2.1-aarch64.AppImage";
        hash = "sha256-Otg+NyW1DmrqIb0xqZCfJ4ys61/DBOQNgaAR8PMOCfg=";
      } else (throw "Unsupported system: ${pkgs.stdenv.hostPlatform.system}");
    };
  });
  bunMainline = (pkgs.bun.overrideAttrs rec {
    version = "1.3.2";
    passthru.sources = {
      "aarch64-linux" = pkgs.fetchurl {
        url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-linux-aarch64.zip";
        hash = "sha256-/P1HHNvVp4/Uo5DinMzSu3AEpJ01K6A3rzth1P1dC4M=";
      };
      "x86_64-linux" = pkgs.fetchurl {
        url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-linux-x64.zip";
        hash = "sha256-DLVqRIS9d2Sj7vm55nq0V4QJgSh7RnlJdNHmYSy/Zwk=";
      };
    };
    src = passthru.sources.${pkgs.stdenv.hostPlatform.system};
  });
  rustcMainline = pkgs.rustc.overrideAttrs (oldAttrs: {
    version = "1.88.0";
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
    arandr
    bat
    bunMainline
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
    lld
    ghostty
    nixpkgs-fmt
    nix-prefetch-docker
    nixos-generators
    nodejs_23
    openssl.dev
    portaudio
    pkg-config
    postgresql
    rustcMainline
    simplescreenrecorder
    skopeo
    sqlc
    stripe-cli
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
    let
      configWithHeight = if i3BarHeight != null
        then builtins.replaceStrings [ "# height replacer" ]
               [ "height ${toString i3BarHeight}" ]
               i3config 
        else i3config;
    in
      builtins.replaceStrings [ "set $mod Mod4" ]
        [ "set $mod ${i3ModKey}" ]
        configWithHeight;
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
  home.file.".local/bin/rmux".source = ../bin/rmux;
  home.file.".local/bin/chat".source = ../bin/chat;
  home.file.".local/bin/dmenu_emoji".source = ../bin/dmenu_emoji;
  home.file.".local/bin/git-hf".source = ../bin/git-hf;
  home.file.".local/bin/mypulls".source = ../bin/mypulls;
  home.file.".local/bin/notion".source = ../bin/notion;
  home.file.".local/bin/superautopets".source = ../bin/superautopets;
  home.file.".local/bin/nix-vscode-extensions".source = ../bin/nix-vscode-extensions;
  home.file.".config/ghostty/config".source = ./config/ghostty;
}
