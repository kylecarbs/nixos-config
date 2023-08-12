{
  description = "kylecarbs' NixOS configuration";

  outputs = { self, nixpkgs, home-manager }: {
    nixosConfigurations.vm-aarch64 = nixpkgs.lib.nixosSystem rec {
      system = "aarch64-linux";
      modules = [
        ./hardware/vm-aarch64.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.users.kyle =
            let
              homeConfig = import ./hosts/home.nix;
            in
            homeConfig // {
              programs.alacritty.settings.env = {
                # In our VM we don't have LIBGL rendering!
                LIBGL_ALWAYS_SOFTWARE = "1";
              };
            };
        }
      ];
    };
    nixosConfigurations.desktop-amd64 = nixpkgs.lib.nixosSystem rec {
      system = "amd64-linux";
      modules = [
        ./hardware/desktop-amd64.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.users.kyle = import ./hosts/home.nix;
        }
      ];
    };
  };
}
