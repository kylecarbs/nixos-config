{ stdenv, lib, fetchurl, makeWrapper }:

stdenv.mkDerivation rec {
  pname = "coder";
  version = "2.0.1";

  src = fetchurl {
    url = "https://github.com/coder/coder/releases/download/v${version}/coder_${version}_linux_arm64.tar.gz";
    sha256 = "sha256-WcNWzBW0ISxWtuQ4ZiITxUAdBWj1DhsUPoSRkYKUODc=";
  };

  sourceRoot = ".";

  installPhase = ''
    mkdir -p $out/bin
    ls -al
    install -Dm755 $pname $out/bin/$pname
  '';

  meta = with lib; {
    description = "A CLI interface for Coder";
    homepage = "https://github.com/coder/coder/";
    platforms = platforms.linux; 
  };
}