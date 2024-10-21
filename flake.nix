{
  description = "kylecarbs' NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager";
    cursor-arm = {
      url = "git+file:/home/kyle/projects/kylecarbs/cursor-arm";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, cursor-arm }: {
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
              homeConfig = import ./hosts/home.nix { 
                inherit pkgs;
                i3BarHeight = 37;
              };
            in
            nixpkgs.lib.recursiveUpdate homeConfig {
              services.picom.enable = true;
              home.pointerCursor.size = 30;
              home.packages = homeConfig.home.packages ++[ cursor-arm.packages.${system}.default ];
            };
        }
      ];
    };
    # My dual-booted desktop.
    nixosConfigurations.desktop-amd64 = nixpkgs.lib.nixosSystem rec {
      system = "amd64-linux";
      modules = [
        ./hardware/desktop-amd64.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.users.kyle =
            let
              pkgs = import nixpkgs {
                system = "x86_64-linux";
                config.allowUnfree = true;
                config.cudaSupport = true;
              };
              homeConfig = import ./hosts/home.nix { inherit pkgs; };
            in
            nixpkgs.lib.recursiveUpdate homeConfig {
              programs.alacritty.settings.font.size = 14;
              home.packages = homeConfig.home.packages ++[ cursor-arm.packages.x86_64-linux.default ];
            };
        }
      ];
    };
  };
}
