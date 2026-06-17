.SILENT: switch

laptop:
	sudo nixos-rebuild switch --flake .#laptop-amd64

desktop:
	sudo nixos-rebuild switch --flake .#desktop-amd64

server:
	git pull --ff-only
	sudo nixos-rebuild switch --flake .#server-amd64

server-boot:
	git pull --ff-only
	sudo nixos-rebuild boot --flake .#server-amd64

update:
	nix flake update
