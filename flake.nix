{
  description = "kylecarbs' NixOS configuration";

  outputs = { self, nixpkgs, home-manager }: {
    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;
    formatter.aarch64-linux = nixpkgs.legacyPackages.aarch64-linux.nixpkgs-fmt;

    # A UTM VM on my M2 Macbook used when traveling or at coffee shops.
    nixosConfigurations.vm-aarch64 = nixpkgs.lib.nixosSystem rec {
      system = "aarch64-linux";
      modules = [
        ./hardware/vm-aarch64.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.users.kyle =
            let
              pkgs = import nixpkgs {
                inherit system;
              };
              homeConfig = import ./hosts/home.nix { inherit pkgs; };
            in
            nixpkgs.lib.recursiveUpdate homeConfig {
              programs.alacritty.settings.env = {
                # Our VM must use software rendering!
                LIBGL_ALWAYS_SOFTWARE = "1";
              };
              programs.rofi.font = "Fira Code 24";
              services.picom.enable = true;
              home.file.".local/bin/vmres".source = ./bin/vmres;
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
          home-manager.users.kyle =
            let
              pkgs = import nixpkgs {
                system = "x86_64-linux";
              };
              homeConfig = import ./hosts/home.nix { inherit pkgs; };
            in
            nixpkgs.lib.recursiveUpdate homeConfig {
              programs.vscode.userSettings."editor.fontSize" = 16;
              programs.vscode.userSettings."terminal.fontSize" = 16;
            };
        }
      ];
    };
  };
}
