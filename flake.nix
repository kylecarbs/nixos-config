{
  description = "kylecarbs' NixOS configuration";

  outputs = { self, nixpkgs, home-manager }: {
    nixosConfigurations.vm-aarch64-utm = nixpkgs.lib.nixosSystem rec {
      system = "aarch64-linux";
      modules = [
        ./machines/vm-aarch64-utm.nix
        ./hardware/vm-aarch64-utm.nix
      ];
    };
    nixosConfigurations.dev-amd64 = nixpkgs.lib.nixosSystem rec {
      system = "amd64-linux";
      modules = [
        ./machines/dev-amd64.nix
        ./hardware/dev-amd64.nix
      ];
    };
  };
}
