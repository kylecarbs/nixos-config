{
  description = "kylecarbs' NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager";
    vscode-server.url = "github:nix-community/nixos-vscode-server";
  };

  outputs = { self, nixpkgs, home-manager, vscode-server }: {
    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;

    # Dell XPS 14"
    nixosConfigurations.laptop-amd64 = nixpkgs.lib.nixosSystem rec {
      system = "x86_64-linux";
      modules = [
        home-manager.nixosModules.home-manager
        ./hosts/gui.nix
        ./hardware/laptop-amd64.nix
        {
          kyle.gui = {
            swayModKey = "Mod1";
            swayExtraConfig = ''
              output eDP-1 mode 2880x1800@120Hz scale 1.5 position 0 0
              output DP-1 mode 5120x2160@165.06Hz scale 1.5 position 1920 0
            '';
          };
          system.stateVersion = nixpkgs.lib.mkForce "26.11";
        }
      ];
    };
    # My dual-booted desktop.
    nixosConfigurations.desktop-amd64 = nixpkgs.lib.nixosSystem rec {
      system = "x86_64-linux";
      modules = [
        home-manager.nixosModules.home-manager
        vscode-server.nixosModules.default
        ./hosts/gui.nix
        ./hardware/desktop-amd64.nix
        {
          services.vscode-server = {
            enable = true;
            installPath = "$HOME/.cursor-server";
          };
        }
      ];
    };
    nixosConfigurations.server-amd64 = nixpkgs.lib.nixosSystem rec {
      system = "x86_64-linux";
      modules = [
        home-manager.nixosModules.home-manager
        vscode-server.nixosModules.default
        ./hosts/server.nix
        ./hardware/server-amd64.nix
        {
          services.vscode-server = {
            enable = true;
            installPath = "$HOME/.cursor-server";
          };
        }
      ];
    };
  };
}
