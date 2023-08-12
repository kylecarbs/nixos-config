.SILENT: switch

switch:
	if [ `uname -m` = "aarch64" ]; then \
		sudo nixos-rebuild switch --flake .#vm-aarch64; \
	else \
		sudo nixos-rebuild switch --flake .#desktop-amd64; \
	fi

update:
	nix flake update

update-vscode-extensions:
	deno run --allow-run --allow-net --allow-read --allow-write --unstable --no-check scripts/update-vscode-extensions.ts