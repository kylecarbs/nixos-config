# nixos-config

This repository holds the NixOS configuration for my computers.

Feel free to use it as a reference!

The laptop and desktop enable CUPS and Avahi to discover network printers,
including driverless IPP/AirPrint printers. Apply the configuration with
`make laptop` or `make desktop`, then reopen Chrome and select the printer under
**Print → Destination → See more**. If a printer needs to be added manually,
use the CUPS interface at <http://localhost:631>.

`hosts/server.nix` publishes private Tailscale Services with per-service systemd
units. Polydex forwards TCP ports 8123 and 9000 to ClickHouse on localhost.
With Tailscale 1.98.5, `set-config --service=svc:<name>` takes a per-service JSON
file with top-level `version` and `endpoints`; the `--all` format instead wraps
named services in `services`. Advertising a service alone does not load its
endpoint mappings. The publisher units restart with `tailscaled` to reapply them.
Verify the loaded mappings with `sudo tailscale serve get-config --service=svc:polydex`.

The server accepts SSH only over Tailscale (`tailscale0`), as `kyle` with a key;
root SSH login is disabled. Its public interface, `eno1`, accepts no new inbound
connections, including forwarded traffic to Docker containers on any protocol,
so a container port published on `0.0.0.0` is still unreachable from the
internet. tailscaled accepts all traffic on `tailscale0` before the NixOS
firewall runs, so Tailscale ACLs decide which peers reach which ports. If
Tailscale is down, use the hosting provider's console or rescue system to get in.

The `laptop-amd64` configuration allows AirPlay discovery (UDP 5353) and sender
timing/audio replies (UDP 60000–60010) on its Wi-Fi interface, `wlp0s20f3`.
These match the default ports used by the `airplay-linux` CLI. The rules take
effect after applying the configuration; temporary manual firewall rules are
replaced when the firewall restarts or the machine reboots.

The server and desktop use the 6.18 LTS kernel from a separate
`nixpkgs-kernel` input so kernel security updates do not require updating the
other system packages.
To update and stage a kernel for the next reboot:

```sh
nix flake update nixpkgs-kernel
sudo nixos-rebuild boot --flake .#server-amd64
```

Use `desktop-amd64` for the desktop. The laptop keeps its existing kernel
package and carries the upstream NoisyTCP patch until that package reaches
Linux 7.3.4 or newer; rebuild it with `laptop-amd64`.

Reboot when ready, then check `uname -r` to verify the new kernel is running.
The laptop backport keeps the same version number. After rebuilding and
rebooting it, verify that the booted kernel matches the staged generation:

```sh
readlink -f /run/booted-system/kernel /nix/var/nix/profiles/system/kernel
```

Both paths should resolve to the same patched kernel in the Nix store.
Staging a kernel does not patch the currently running kernel. For
CVE-2026-98432, the 6.18 branch requires version 6.18.56 or newer. For
[NoisyTCP (CVE-2026-99288)](https://github.com/V4bel/NoisyTCP), it requires
6.18.63 or newer. The kernel fix covers host and container networking.
Do not disable SYN cookies as a permanent workaround: that reduces SYN-flood
protection and would need to be applied separately to every network namespace.
