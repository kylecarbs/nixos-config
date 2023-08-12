switch:
	sudo nixos-rebuild switch --flake .#dev-amd64

update:
	nix flake update