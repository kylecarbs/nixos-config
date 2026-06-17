{
  description = "kylecarbs' NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager";
    vscode-server.url = "github:nix-community/nixos-vscode-server";
  };

  outputs = { self, nixpkgs, home-manager, vscode-server }: {
    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;
    formatter.aarch64-linux = nixpkgs.legacyPackages.aarch64-linux.nixpkgs-fmt;

    # A UTM VM on my M2 Macbook used when traveling or at coffee shops.
    nixosConfigurations.vm-aarch64 = nixpkgs.lib.nixosSystem rec {
      system = "aarch64-linux";
      modules = [
        ./hardware/vm-aarch64.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.users.kyle =
            let
              pkgs = import nixpkgs {
                inherit system;
                config.allowUnfree = true;
              };
              homeConfig = import ./hosts/home-gui.nix {
                inherit pkgs;
                swayBarHeight = 37;
              };
            in
            nixpkgs.lib.recursiveUpdate homeConfig {
              home.pointerCursor.size = 30;
            };
        }
      ];
    };
    nixosConfigurations.laptop-framework = nixpkgs.lib.nixosSystem rec {
      system = "x86_64-linux";
      modules = [
        ./hardware/laptop-framework.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.users.kyle =
            let
              pkgs = import nixpkgs {
                system = "x86_64-linux";
                config.allowUnfree = true;
              };
              homeConfig = import ./hosts/home-gui.nix {
                inherit pkgs;
                swayModKey = "Mod1"; # Use Alt key for laptop
              };
            in
            nixpkgs.lib.recursiveUpdate homeConfig { };
        }
      ];
    };
    # Dell XPS 14"
    nixosConfigurations.laptop-amd64 = nixpkgs.lib.nixosSystem rec {
      system = "x86_64-linux";
      modules = [
        ./hardware/laptop-amd64.nix
        home-manager.nixosModules.home-manager
        {
          system.stateVersion = nixpkgs.lib.mkForce "26.11";
          home-manager.useGlobalPkgs = true;
          home-manager.users.kyle =
            let
              pkgs = import nixpkgs {
                system = "x86_64-linux";
                config.allowUnfree = true;
              };
              homeConfig = import ./hosts/home-gui.nix {
                inherit pkgs;
                swayModKey = "Mod1"; # Use Alt key for laptop
                swayExtraConfig = ''
                  output eDP-1 mode 2880x1800@120Hz scale 1.5 position 0 0
                  output DP-1 mode 5120x2160@165.06Hz scale 1.5 position 1920 0
                '';
              };
            in
            nixpkgs.lib.recursiveUpdate homeConfig { };
        }
      ];
    };
    # My dual-booted desktop.
    nixosConfigurations.desktop-amd64 = nixpkgs.lib.nixosSystem rec {
      system = "x86_64-linux";
      modules = [
        ./hardware/desktop-amd64.nix
        home-manager.nixosModules.home-manager
        vscode-server.nixosModules.default
        {
          services.vscode-server = {
            enable = true;
            installPath = "$HOME/.cursor-server";
          };
          home-manager.useGlobalPkgs = true;
          home-manager.users.kyle =
            let
              pkgs = import nixpkgs {
                system = "x86_64-linux";
                config.allowUnfree = true;
                config.cudaSupport = true;
              };
              homeConfig = import ./hosts/home-gui.nix { inherit pkgs; };
            in
            nixpkgs.lib.recursiveUpdate homeConfig {
              # 
            };
        }
      ];
    };
    nixosConfigurations.server-amd64 = nixpkgs.lib.nixosSystem rec {
      system = "x86_64-linux";
      modules = [
        ./hardware/server-amd64.nix
        home-manager.nixosModules.home-manager
        vscode-server.nixosModules.default
        {
          services.vscode-server = {
            enable = true;
            installPath = "$HOME/.cursor-server";
          };

          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;

          home-manager.users.kyle =
            let
              pkgs = import nixpkgs {
                system = "x86_64-linux";
                config.allowUnfree = true;
              };
              homeConfig = import ./hosts/home.nix { inherit pkgs; };
            in
            nixpkgs.lib.recursiveUpdate homeConfig {
              # Server-specific overrides can go here.
            };
        }
      ];
    };
  };
}
