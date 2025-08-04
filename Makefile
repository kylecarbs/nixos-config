.SILENT: switch


vm:
	sudo nixos-rebuild switch --flake .#vm-aarch64

laptop:
	sudo nixos-rebuild switch --flake .#laptop-amd64

desktop:
	sudo nixos-rebuild switch --flake .#desktop-amd64

update:
	nix flake update

update-vscode-extensions:
	deno run --allow-run --allow-net --allow-read --allow-write --unstable --no-check scripts/update-vscode-extensions.ts