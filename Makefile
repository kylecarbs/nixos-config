switch:
	sudo nixos-rebuild switch --flake .#vm-aarch64-utm

update:
	nix flake update