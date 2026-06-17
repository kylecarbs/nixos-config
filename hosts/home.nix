{ pkgs, ... }:

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
  rustcMainline = pkgs.rustc.overrideAttrs (oldAttrs: {
    version = "1.93.0";
  });
  devcontainer-cli = pkgs.callPackage ../pkgs/devcontainer-cli.nix { };
in
{
  home.stateVersion = "22.05";

  home.packages = with pkgs; [
    bat
    bunMainline
    cargo
    coderMainline
    deno
    dig
    fish
    gcc
    git
    git-lfs
    gnumake
    go_1_25
    goreleaser
    (google-cloud-sdk.withExtraComponents
      ([ google-cloud-sdk.components.gke-gcloud-auth-plugin ]))
    gotools
    graphviz
    htmlq
    htop
    jq
    kubectl
    lld
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

    # Language servers
    (pkgs.lib.hiPrio gopls)
    typescript-language-server
  ];

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
      core.editor = "vim";
    };
  };

  xdg.enable = true;

  # Add all of our binaries!
  home.file.".local/bin/ams".source = ../bin/ams;
  home.file.".local/bin/git-hf".source = ../bin/git-hf;
  home.file.".local/bin/mypulls".source = ../bin/mypulls;
  home.file.".codex/AGENTS.md".source = ./config/AGENTS.md;
  home.file.".claude/CLAUDE.md".source = ./config/AGENTS.md;
  home.file.".codex/skills/code-review".source = ./config/skills/code-review;
  home.file.".codex/skills/code-style".source = ./config/skills/code-style;
  home.file.".codex/skills/update-docs".source = ./config/skills/update-docs;
  home.file.".claude/skills/code-review".source = ./config/skills/code-review;
  home.file.".claude/skills/code-style".source = ./config/skills/code-style;
  home.file.".claude/skills/update-docs".source = ./config/skills/update-docs;
}
