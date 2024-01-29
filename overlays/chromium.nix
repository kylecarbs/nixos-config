# This adds the default Chrome secrets to enable Chrome sync!
self: super: {
  chromium = super.chromium.overrideAttrs (oldAttrs: rec {
    name = "chromium";
    buildInputs = oldAttrs.buildInputs or [] ++ [ super.makeWrapper ];

    postInstall = oldAttrs.postInstall or "" + ''
      wrapProgram $out/bin/chromium \
        --set GOOGLE_API_KEY "AIzaSyCkfPOPZXDKNn8hhgu3JrA62wIgC93d44k" \
        --set GOOGLE_DEFAULT_CLIENT_ID "77185425430.apps.googleusercontent.com" \
        --set GOOGLE_DEFAULT_CLIENT_SECRET "OTJgUOQcT7lO7GsGZq2G4IlT"
    '';
  });
}
