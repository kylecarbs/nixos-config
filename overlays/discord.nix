# Discord isn't compatible with arm64, so we have to launch Chromium in app mode.
self: super: {
  discord = super.stdenv.mkDerivation {
    name = "discord";
    src = null;
    builder = super.writeScript "builder" ''
      source $stdenv/setup
      mkdir -p $out/bin
      makeWrapper ${super.chromium}/bin/chromium $out/bin/discord --add-flags '--app="https://discord.com/app"'
    '';
    dontUnpack = true;
    nativeBuildInputs = [ super.makeWrapper ];
  };
}
