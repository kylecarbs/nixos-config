# This adds the default Chrome secrets to enable Chrome sync!
self: super: {
  chromium = super.stdenv.mkDerivation {
    name = "chromium";
    src = null;
    builder = super.writeScript "builder" ''
      source $stdenv/setup
      mkdir -p $out/bin
      makeWrapper ${super.chromium}/bin/chromium $out/bin/chromium \
        --set GOOGLE_API_KEY "AIzaSyCkfPOPZXDKNn8hhgu3JrA62wIgC93d44k" \
        --set GOOGLE_DEFAULT_CLIENT_ID "77185425430.apps.googleusercontent.com" \
        --set GOOGLE_DEFAULT_CLIENT_SECRET "OTJgUOQcT7lO7GsGZq2G4IlT"
    '';
    dontUnpack = true;
    nativeBuildInputs = [ super.makeWrapper ];
  };
}
