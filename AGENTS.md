This repository contains NixOS configurations for Kyle's machines.

System assumptions:

- Hosts run NixOS.
- For missing tools, prefer `nix-shell -p <package> --command '<command>'`.
- Interactive shells are Fish, though agent commands may run under Bash.

Project structure:

- `hosts/base.nix` is shared by every NixOS host and must stay usable by headless servers. It owns shared system defaults, TCP tuning, and the shared Home Manager user environment.
- `hosts/gui.nix` imports `hosts/base.nix` and adds Sway, desktop apps, GUI theming, status bar, screenshot tooling, and GUI-only Home Manager settings.
- `hosts/server.nix` imports `hosts/base.nix` and adds server-only SSH hardening, firewall, and service publishing config.
- `hardware/*.nix` files contain host hardware details. Role composition and role-specific host overrides happen explicitly in `flake.nix`.
- `hosts/config/AGENTS.md` is installed onto actual hosts as user-level agent guidance. Keep repository architecture notes in this root file instead.

Server network exposure:

- The server's public interface (`eno1`) accepts no new inbound connections. An explicit `nixos-fw` rule drops new TCP on `eno1` even if a global port is opened, SSH is allowed only on `tailscale0`, and `DOCKER-USER` drops all new forwarded traffic from `eno1` for every protocol. tailscaled's `ts-input` chain accepts all `tailscale0` traffic first, so tailnet exposure is governed by Tailscale ACLs, not the NixOS firewall. Publish services through Tailscale or a Cloudflare tunnel rather than opening public ports, and ask before adding any public exception.
- Removing a rule from `networking.firewall.extraCommands` does not delete the live rule from Docker's `DOCKER-USER` chain. Delete stale rules by hand or reboot.

Kernel security updates:

- The server and desktop use `nixpkgs-kernel` for their 6.18 LTS kernel. Update that input independently of application packages and keep it at 6.18.63 or newer for NoisyTCP (CVE-2026-99288).
- The laptop carries the upstream NoisyTCP patch while its kernel is older than 7.3.4. Remove the backport when its main nixpkgs input supplies a fixed kernel.
- Building or staging a kernel does not fix the running kernel; verify the booted version after reboot. Backports keep the version number, so also compare the booted kernel store path against the staged generation. A patched host kernel also protects its containers.

Laptop display:

- Keep the Dell laptop's internal display at 120 Hz and use the Intel `xe` driver's default display power management. Avoid blanket kernel overrides that disable display power-saving features.
- Display power-management kernel parameters require a reboot to take effect; rebuilding alone does not change the running driver.

Apple keyboards:

- Keep keyboard fixes specific to the affected model. The USB Magic Keyboard with Numeric Keypad (`05ac:026c`) uses an hwdb mapping from left Ctrl to right Ctrl to bypass the global `hid_apple.swap_fn_leftctrl=1` setting; preserve that setting for compact keyboards. Trigger udev for the affected keyboard or reconnect it after applying hwdb changes.

Camera validation:

- Keep image processing and sensor tuning in the shared camera producer so every application receives the same processed image. The IPU7 laptop uses Intel's hardware ISP through the NixOS IPU7 module and V4L2 relay; prevent libcamera from competing for its raw sensor.
- Test exposure recovery after lighting changes and compare 720p/1080p output after auto-exposure settles. A successful stream alone does not establish image quality. Verify the shared PipeWire path as well as the processed V4L2 camera.
- After camera stack updates, verify microphone capture and relay restart discovery too: this Dell's CVS bridge shares an audio GPIO, and the loopback device only advertises capture after its producer starts.
- `fetchpatch` hashes cover normalized patches, not raw Patchwork mbox downloads. Inspect the patch content before correcting a hash mismatch.

Agent behavior:

- Ask for direction when a decision would otherwise require an implicit assumption.
- After making changes, clean up old or legacy code and documentation that the change makes obsolete.
- When working on projects, always leverage the `code-review`, `code-style`, and `update-docs` skills.
- After modifying code, use `update-docs` to decide whether `AGENTS.md` should be created or updated.
