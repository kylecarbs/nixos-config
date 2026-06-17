{ lib, pkgs, ... }:

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
in
{
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.android_sdk.accept_license = true;

  i18n.defaultLocale = "en_CA.UTF-8";

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
    "impure-derivations"
    "ca-derivations"
  ];

  nix.gc = {
    automatic = true;
    randomizedDelaySec = "14m";
    options = lib.mkDefault "--delete-older-than 1d";
  };

  programs.fish.enable = true;
  # See: https://nixos.wiki/wiki/Fish
  # Warning! As noted in the fish documentation, using fish as your *login* shell (referenced in /etc/passwd)
  # may cause issues because fish is not POSIX compliant. In particular, this author found systemd's emergency
  # mode to be completely broken when fish was set as the login shell.
  programs.bash = {
    interactiveShellInit = ''
      if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]
      then
        shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
        exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
      fi
    '';
  };

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc
    zlib
    openssl
  ];

  users.users.kyle = {
    isNormalUser = true;
    description = "Kyle Carberry";
    extraGroups = [ "wheel" "docker" ];
    shell = pkgs.fish;
  };
  security.sudo.wheelNeedsPassword = false;

  services.openssh.enable = true;
  services.chrony.enable = true;

  virtualisation.docker.enable = true;

  services.tailscale = {
    enable = true;
    useRoutingFeatures = "both";
  };

  boot.kernel.sysctl = {
    # BBR plus fq is the main system-wide TCP throughput/latency win.
    "net.ipv4.tcp_congestion_control" = "bbr";
    "net.core.default_qdisc" = "fq";

    # Enable TCP Fast Open for clients and servers.
    "net.ipv4.tcp_fastopen" = 3;

    # Keep warm connections responsive after idle periods.
    "net.ipv4.tcp_slow_start_after_idle" = 0;

    # Avoid blackholed packets on paths with broken MTU discovery.
    "net.ipv4.tcp_mtu_probing" = 1;

    # Lower unsent data threshold for better interactive latency.
    "net.ipv4.tcp_notsent_lowat" = 16384;

    # Raise socket buffer ceilings for high-throughput links.
    "net.core.rmem_max" = 16777216;
    "net.core.wmem_max" = 16777216;
    "net.ipv4.tcp_rmem" = "4096 131072 16777216";
    "net.ipv4.tcp_wmem" = "4096 65536 16777216";
  };

  system.stateVersion = lib.mkDefault "23.05";

  home-manager.useGlobalPkgs = true;
  home-manager.users.kyle = { ... }: {
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
  };
}
