.SILENT: switch


vm:
	sudo nixos-rebuild switch --flake .#vm-aarch64

framework:
	sudo nixos-rebuild switch --flake .#laptop-framework

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
