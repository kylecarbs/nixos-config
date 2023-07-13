{
  description = "kylecarbs' NixOS configuration";

  outputs = { self, nixpkgs }: {
    nixosConfigurations.vm-aarch64-utm = nixpkgs.lib.nixosSystem rec {
      system = "aarch64-linux";
      modules = [
        ./machines/vm-aarch64-utm.nix
        ./hardware/vm-aarch64-utm.nix
      ];
    };
  };
}
