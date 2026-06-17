This system:

- Uses NixOS. For any missing packages, use `nix-shell -p <package> --command '<command>'`
- Uses the Fish shell

Project structure:

- `hosts/home.nix` is the base Home Manager profile and must stay usable by headless servers.
- `hosts/home-gui.nix` extends the base profile with Sway, desktop apps, GUI theming, status bar, screenshot tooling, and launcher scripts for GUI hosts.

Agent behavior:

- Ask for direction when a decision would otherwise require an implicit assumption.
- After making changes, clean up old or legacy code and documentation that the change makes obsolete.
- When working on projects, always leverage the `code-review`, `code-style`, and `update-docs` skills.
- After modifying code, use `update-docs` to decide whether `AGENTS.md` should be created or updated.
