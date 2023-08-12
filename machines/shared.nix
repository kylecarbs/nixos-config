# Shared dependencies and system configuration for all machines.
{ config, pkgs, home-manager, ... }:

let
  apple-emoji = pkgs.callPackage ../pkgs/apple-emoji.nix { };
  apple-fonts = pkgs.callPackage ../pkgs/apple-fonts.nix { };
  coder = pkgs.callPackage ../pkgs/coder.nix { };
  jetbrains-gateway = pkgs.callPackage ../pkgs/jetbrains-gateway.nix { };
in
{
  imports =
    [
      ../pkgs/sysbox.nix
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  i18n.defaultLocale = "en_CA.UTF-8";
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" "impure-derivations" "ca-derivations" ];
  time.timeZone = "America/Chicago";

  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Enable graphics virtualization.
  hardware.opengl.enable = true;

  # Add my user!
  users.users.kyle = {
    isNormalUser = true;
    description = "Kyle Carberry";
    # Wheel allows sudo without password.
    extraGroups = [ "networkmanager" "wheel" "docker" ];
    shell = pkgs.fish;
  };
  security.sudo.wheelNeedsPassword = false;

  # Workaround for GNOME autologin: https://github.com/NixOS/nixpkgs/issues/103746#issuecomment-945091229
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
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
    gotools
    libnotify
    xorg.libxcvt

    (vscode-with-extensions.override {
      vscodeExtensions = with vscode-extensions; [
        streetsidesoftware.code-spell-checker
        golang.go
        vscode-extensions.zxh404.vscode-proto3
        vscode-extensions.ms-azuretools.vscode-docker
        vscode-extensions.usernamehw.errorlens
        vscode-extensions.eamodio.gitlens
        vscode-extensions.dbaeumer.vscode-eslint
        vscode-extensions.github.copilot
        vscode-extensions.github.vscode-pull-request-github
        vscode-extensions.hashicorp.terraform
        vscode-extensions.yzhang.markdown-all-in-one
        vscode-extensions.github.vscode-pull-request-github
        vscode-extensions.jnoortheen.nix-ide
        vscode-extensions.esbenp.prettier-vscode
        vscode-extensions.ms-vscode-remote.remote-ssh
        vscode-extensions.coder.coder-remote
        vscode-extensions.foxundermoon.shell-format
      ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
        {
          name = "min-theme";
          publisher = "miguelsolorio";
          version = "1.5.0";
          sha256 = "sha256-DF/9OlWmjmnZNRBs2hk0qEWN38RcgacdVl9e75N8ZMY=";
        }
      ];
    })
  ];

  programs.fish.enable = true;
  # Docker
  virtualisation.docker.enable = true;
  # services.sysbox.enable = true;
  services.tailscale.enable = true;
  # Useful for VS Code storing credentials.
  services.gnome.gnome-keyring.enable = true;

  # Change the display manager to i3.
  services.xserver = {
    enable = true;
    layout = "us";
    xkbVariant = "";
    videoDrivers = [ "nvidia" ];

    desktopManager = {
      xterm.enable = false;
    };

    displayManager = {
      autoLogin.enable = true;
      autoLogin.user = "kyle";
      defaultSession = "none+i3";
    };

    windowManager.i3 = {
      enable = true;
      extraPackages = with pkgs; [
        dmenu
        rofi
        i3status
        i3lock
        i3blocks
        xclip
        xorg.libXcursor
        xorg.libXi
        dunst

        # Required for py3status to work!
        (python3.withPackages (p: with p; [
          python-dateutil
          google-api-python-client
          httplib2
          py3status
        ]))
      ];
    };
  };

  # Adjusts the scaling of the display.
  environment.variables = {
    GDK_SCALE = "2";
    GDK_DPI_SCALE = "0.5";
  };
  # Makes Chrome use dark mode by default!
  environment.etc = {
    "xdg/gtk-3.0/settings.ini".text = ''
      [Settings]
      gtk-application-prefer-dark-theme = true
    '';
  };

  fonts.packages = with pkgs; [ apple-emoji apple-fonts fira-code ];
  fonts.fontconfig.defaultFonts.emoji = [ "Apple Color Emoji" ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.htm
  system.stateVersion = "23.05";
}
