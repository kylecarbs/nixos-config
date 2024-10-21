# Shared dependencies and system configuration for all machines.
{ config, pkgs, home-manager, ... }:

let
  apple-emoji = pkgs.callPackage ../pkgs/apple-emoji.nix { };
  apple-fonts = pkgs.callPackage ../pkgs/apple-fonts.nix { };
in
{
  imports =
    [
      ../pkgs/sysbox.nix
      (fetchTarball {
        url = "https://github.com/nix-community/nixos-vscode-server/tarball/master";
        sha256 = "sha256:09j4kvsxw1d5dvnhbsgih0icbrxqv90nzf0b589rb5z6gnzwjnqf";
      })
    ];
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.cudaSupport = true;
  nixpkgs.config.android_sdk.accept_license = true;
  boot.loader.efi.efiSysMountPoint = "/boot";
  i18n.defaultLocale = "en_CA.UTF-8";
  networking.networkmanager.enable = true;
  services.chrony.enable = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" "impure-derivations" "ca-derivations" ];
  time.timeZone = "America/New_York";

  nix.gc = {
    automatic = true;
    randomizedDelaySec = "14m";
    options = "--delete-older-than 1d";
  };

  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Add my user!
  users.users.kyle = {
    isNormalUser = true;
    description = "Kyle Carberry";
    # Wheel allows sudo without password.
    extraGroups = [ "networkmanager" "wheel" "docker" "adbusers" ];
    shell = pkgs.fish;
  };
  security.sudo.wheelNeedsPassword = false;

  # Workaround for GNOME autologin: https://github.com/NixOS/nixpkgs/issues/103746#issuecomment-945091229
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  # The NodeJS in VS Code by default fails to link!
  services.vscode-server.enable = true;
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
  programs.adb.enable = true;
  virtualisation.docker = {
    enable = true;
    enableNvidia = true;
  };
  services.openssh.enable = true;
  services.sysbox.enable = true;
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "both";
  };
  # Useful for VS Code storing credentials.
  services.gnome.gnome-keyring.enable = true;

  location.provider = "geoclue2";
  services.redshift = {
    enable = true;
    brightness = {
      # Note the string values below.
      day = "1";
      night = "1";
    };
    temperature = {
      day = 5500;
      night = 4000;
    };
  };

  services.displayManager = {
      autoLogin.enable = true;
      autoLogin.user = "kyle";
      defaultSession = "none+i3";
  };

  # Change the display manager to i3.
  services.xserver = {
    enable = true;

    xkb = {
      variant = "";
      layout = "us";
    };

    desktopManager = {
      xterm.enable = false;
    };

    windowManager.i3 = {
      enable = true;
      extraPackages = with pkgs; [
        dmenu
        dunst
        i3blocks
        i3lock
        i3status
        rofi
        xclip
        xorg.libXcursor
        xorg.libXi

        # Required for py3status to work!
        (python3.withPackages (p: with p; [
          google-api-python-client
          httplib2
          py3status
          python-dateutil
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
      gtk-application-prefer-dark-theme=1
    '';
  };
  environment.localBinInPath = true;

  fonts.packages = with pkgs; [ apple-emoji apple-fonts fira-code ];
  # Replace the gross Linux emojis with pretty Apple ones!
  fonts.fontconfig.defaultFonts.emoji = [ "Apple Color Emoji" ];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.htm
  system.stateVersion = "23.05";
}
