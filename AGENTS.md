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
