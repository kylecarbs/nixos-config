{ pkgs, swayBarHeight ? null, swayModKey ? "Mod4", swayExtraConfig ? "", ... }:

let
  coderMainline = (pkgs.coder.override {
    # Stay on the edge!
    channel = "mainline";
  }).overrideAttrs (oldAttrs: {
    postInstall = ":";
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
            } else if pkgs.stdenv.hostPlatform.system == "aarch64-linux" then
          pkgs.fetchurl
            {
              # https://www.cursor.com/api/download?platform=linux-arm64&releaseTrack=latest
              url = "https://downloads.cursor.com/production/031e7e0ff1e2eda9c1a0f5df67d44053b059c5df/linux/arm64/Cursor-1.2.1-aarch64.AppImage";
              hash = "sha256-Otg+NyW1DmrqIb0xqZCfJ4ys61/DBOQNgaAR8PMOCfg=";
            } else (throw "Unsupported system: ${pkgs.stdenv.hostPlatform.system}");
    };
    sourceRoot = "${oldAttrs.pname}-${version}-extracted/usr/share/cursor";
  });
  rustcMainline = pkgs.rustc.overrideAttrs (oldAttrs: {
    version = "1.93.0";
  });
  devcontainer-cli = pkgs.callPackage ../pkgs/devcontainer-cli.nix { };
  jetbrains-gateway = pkgs.callPackage ../pkgs/jetbrains-gateway.nix { };

  vscodeExtensions = builtins.fromJSON (builtins.readFile ./vscode-extensions.json);
  vscodeSettings = builtins.fromJSON (builtins.readFile ./vscode-settings.json);

  swayConfig = builtins.readFile ./config/sway;
in
{
  home.stateVersion = "22.05";

  home.packages = with pkgs; [
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
    mesa-demos
    gnumake
    go_1_25
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
    nodejs_24
    openssl.dev
    portaudio
    pkg-config
    postgresql
    rustcMainline
    screen
    skopeo
    sqlc
    stripe-cli
    tailscale
    terraform
    unzip
    vim
    vsce
    whois
    yarn

    signal-desktop

    # Language servers
    (pkgs.lib.hiPrio gopls)
    typescript-language-server
  ];

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

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings."*" = {
      ControlMaster = "auto";
      ControlPath = "~/.ssh/sockets/%r@%h-%p";
      ControlPersist = "10m";
    };
  };

  programs.fish = {
    enable = true;

    interactiveShellInit = builtins.readFile ./config/config.fish;
  };

  programs.neovim = {
    enable = true;
    withPython3 = true;
    withRuby = true;
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

    settings = {
      user = {
        name = "Kyle Carberry";
        email = "kyle@carberry.com";
      };
      alias = {
        p = "push -u origin HEAD";
        c = "checkout";
      };
      push.autoSetupRemote = true;
      init.defaultBranch = "main";
      core.editor = "cursor --wait";
    };
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

  xdg.enable = true;
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

  # Add all of our binaries!
  home.file.".local/bin/rd".source = ../bin/rd;
  home.file.".local/bin/ams".source = ../bin/ams;
  home.file.".local/bin/rmux".source = ../bin/rmux;
  home.file.".local/bin/lmux".source = ../bin/lmux;
  home.file.".local/bin/chat".source = ../bin/chat;
  home.file.".local/bin/dmenu_emoji".source = ../bin/dmenu_emoji;
  home.file.".local/bin/sway_focused_flameshot".source = ../bin/sway_focused_flameshot;
  home.file.".local/bin/sway_workspace_next_output".source = ../bin/sway_workspace_next_output;
  home.file.".local/bin/git-hf".source = ../bin/git-hf;
  home.file.".local/bin/mypulls".source = ../bin/mypulls;
  home.file.".local/bin/notion".source = ../bin/notion;
  home.file.".local/bin/superautopets".source = ../bin/superautopets;
  home.file.".local/bin/nix-vscode-extensions".source = ../bin/nix-vscode-extensions;
  home.file.".config/ghostty/config".source = ./config/ghostty;
  home.file.".codex/AGENTS.md".source = ./config/AGENTS.md;
  home.file.".claude/CLAUDE.md".source = ./config/AGENTS.md;
  home.file.".codex/skills/code-review".source = ./config/skills/code-review;
  home.file.".codex/skills/code-style".source = ./config/skills/code-style;
  home.file.".codex/skills/update-docs".source = ./config/skills/update-docs;
  home.file.".claude/skills/code-review".source = ./config/skills/code-review;
  home.file.".claude/skills/code-style".source = ./config/skills/code-style;
  home.file.".claude/skills/update-docs".source = ./config/skills/update-docs;
}
