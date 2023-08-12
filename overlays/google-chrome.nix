# Wraps Chrome to force dark mode and changes the name to `google-chrome` instead of `google-chrome-stable`.
self: super: {
  google-chrome = super.stdenv.mkDerivation {
    name = "google-chrome";
    src = null;
    builder = super.writeScript "builder" ''
      source $stdenv/setup
      mkdir -p $out/bin
      makeWrapper ${super.google-chrome}/bin/google-chrome-stable $out/bin/google-chrome --append-flags "--force-dark-mode"
    '';
    dontUnpack = true;
    nativeBuildInputs = [ super.makeWrapper ];
  };
}
