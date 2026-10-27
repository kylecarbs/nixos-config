# nixos-config

This repository holds the NixOS configuration for my computers.

Feel free to use it as a reference!

The `laptop-amd64` configuration allows AirPlay discovery (UDP 5353) and sender
timing/audio replies (UDP 60000–60010) on its Wi-Fi interface, `wlp0s20f3`.
These match the default ports used by the `airplay-linux` CLI. The rules take
effect after applying the configuration; temporary manual firewall rules are
replaced when the firewall restarts or the machine reboots.
