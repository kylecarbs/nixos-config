{
  description = "kylecarbs' NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager";
    vscode-server.url = "github:nix-community/nixos-vscode-server";
  };

  outputs = { self, nixpkgs, home-manager, vscode-server }: {
    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;

    # Dell XPS 14"
    nixosConfigurations.laptop-amd64 = nixpkgs.lib.nixosSystem rec {
      system = "x86_64-linux";
      modules = [
        home-manager.nixosModules.home-manager
        ./hosts/gui.nix
        ./hardware/laptop-amd64.nix
        {
          kyle.gui = {
            swayModKey = "Mod4";
            swayExtraConfig = ''
              input "1:1:AT_Translated_Set_2_keyboard" {
                xkb_layout us
                xkb_options altwin:swap_lalt_lwin
              }

              output eDP-1 mode 2880x1800@120Hz scale 1.5 position 0 0
              output DP-1 mode 5120x2160@165.06Hz scale 1.5 position 1920 0
            '';
          };
          services.pipewire.extraConfig.pipewire."91-laptop-speaker-eq" =
            let
              speakerNode = "alsa_output.pci-0000_00_1f.3-platform-sof_sdw.HiFi__Speaker__sink";

              eqBand = name: frequency: gain: {
                inherit name;
                type = "builtin";
                label = "bq_peaking";
                control = {
                  Freq = frequency;
                  Q = 4.36;
                  Gain = gain;
                };
              };

              eqBands = [
                (eqBand "eq_band_1" 31.0 0.0)
                (eqBand "eq_band_2" 62.0 0.0)
                (eqBand "eq_band_3" 125.0 3.0)
                (eqBand "eq_band_4" 250.0 2.0)
                (eqBand "eq_band_5" 450.0 (-4.0))
                (eqBand "eq_band_6" 1250.0 (-11.0))
                (eqBand "eq_band_7" 3000.0 (-6.0))
                (eqBand "eq_band_8" 4500.0 (-9.0))
                (eqBand "eq_band_9" 6000.0 (-6.0))
                (eqBand "eq_band_10" 8000.0 (-6.0))
                (eqBand "eq_band_11" 16000.0 0.0)
              ];

              lastEqBand = builtins.length eqBands;

              eqLinks = builtins.genList
                (index: {
                  output = "eq_band_${toString (index + 1)}:Out";
                  input = "eq_band_${toString (index + 2)}:In";
                })
                (lastEqBand - 1);
            in
            {
              "context.modules" = [
                {
                  name = "libpipewire-module-filter-chain";
                  args = {
                    "node.name" = "filter.sink.laptop-speakers-eq";
                    "node.description" = "Laptop Speakers EQ";
                    "media.name" = "Laptop Speakers EQ";
                    "filter.graph" = {
                      nodes = eqBands ++ [
                        {
                          name = "trim";
                          type = "builtin";
                          label = "mixer";
                          control."Gain 1" = 0.8912509381337456;
                        }
                      ];
                      links = eqLinks ++ [
                        {
                          output = "eq_band_${toString lastEqBand}:Out";
                          input = "trim:In 1";
                        }
                      ];
                    };
                    "audio.channels" = 2;
                    "audio.position" = [ "FL" "FR" ];
                    "capture.props" = {
                      "media.class" = "Audio/Sink";
                      "filter.smart" = true;
                      "filter.smart.name" = "filter.sink.laptop-speakers-eq";
                      "filter.smart.target" = { "node.name" = speakerNode; };
                    };
                    "playback.props" = {
                      "node.passive" = true;
                      "media.role" = "DSP";
                    };
                  };
                }
              ];
            };
          system.stateVersion = nixpkgs.lib.mkForce "26.11";
        }
      ];
    };
    # My dual-booted desktop.
    nixosConfigurations.desktop-amd64 = nixpkgs.lib.nixosSystem rec {
      system = "x86_64-linux";
      modules = [
        home-manager.nixosModules.home-manager
        vscode-server.nixosModules.default
        ./hosts/gui.nix
        ./hardware/desktop-amd64.nix
        {
          services.vscode-server = {
            enable = true;
            installPath = "$HOME/.cursor-server";
          };
        }
      ];
    };
    nixosConfigurations.server-amd64 = nixpkgs.lib.nixosSystem rec {
      system = "x86_64-linux";
      modules = [
        home-manager.nixosModules.home-manager
        vscode-server.nixosModules.default
        ./hosts/server.nix
        ./hardware/server-amd64.nix
        {
          services.vscode-server = {
            enable = true;
            installPath = "$HOME/.cursor-server";
          };
        }
      ];
    };
  };
}
