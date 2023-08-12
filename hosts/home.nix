{ pkgs, ... }:

let
  coder = pkgs.callPackage ../pkgs/coder.nix { };
  jetbrains-gateway = pkgs.callPackage ../pkgs/jetbrains-gateway.nix { };

  vscodeExtensions = builtins.fromJSON (builtins.readFile ./vscode-extensions.json);
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
    mutableExtensionsDir = false;
    # To add new extensions, add them to the vscode-extensions.json file and
    # then run `make update-vscode-extensions`.
    extensions = pkgs.vscode-utils.extensionsFromVscodeMarketplace vscodeExtensions;
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
