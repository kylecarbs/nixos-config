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