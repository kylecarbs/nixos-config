# nixos-config

This repository holds the NixOS configuration for my computers.

Feel free to use it as a reference!

The `laptop-amd64` configuration allows AirPlay discovery (UDP 5353) and sender
timing/audio replies (UDP 60000–60010) on its Wi-Fi interface, `wlp0s20f3`.
These match the default ports used by the `airplay-linux` CLI. The rules take
effect after applying the configuration; temporary manual firewall rules are
replaced when the firewall restarts or the machine reboots.

The server uses the 6.18 LTS kernel from a separate `nixpkgs-kernel` input so
kernel security updates do not require updating the other system packages.
To update and stage a kernel for the next reboot:

```sh
nix flake update nixpkgs-kernel
sudo nixos-rebuild boot --flake .#server-amd64
```

Reboot when ready, then check `uname -r` to verify the new kernel is running.
Staging a kernel does not patch the currently running kernel. For
CVE-2026-98432, the 6.18 branch requires version 6.18.56 or newer.
