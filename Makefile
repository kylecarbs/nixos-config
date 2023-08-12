switch:
	if [ `uname -m` = "aarch64" ]; then \
		sudo nixos-rebuild switch --flake .#vm-aarch64-utm; \
	else \
		sudo nixos-rebuild switch --flake .#dev-amd64; \
	fi

update:
	nix flake update