# Slack isn't compatible with arm64, so we have to launch Chromium in app mode.
self: super: {
  slack = super.stdenv.mkDerivation {
    name = "slack";
    src = null;
    builder = super.writeScript "builder" ''
      source $stdenv/setup
      mkdir -p $out/bin
      makeWrapper ${super.chromium}/bin/chromium $out/bin/slack --add-flags '--app="https://app.slack.com/client/T1ZPT2FL0"'
    '';
    dontUnpack = true;
    nativeBuildInputs = [ super.makeWrapper ];
  };
}
