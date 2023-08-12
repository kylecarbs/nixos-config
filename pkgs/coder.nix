{ stdenv, lib, fetchurl, makeWrapper, ... }:

let
  system = stdenv.system or stdenv.hostPlatform.system;
in
stdenv.mkDerivation rec {
  pname = "coder";
  version = "2.0.1";

  src = fetchurl {
    url = "https://github.com/coder/coder/releases/download/v${version}/coder_${version}_linux_${{
      "x86_64-linux"  = "amd64";
      "aarch64-linux" = "arm64";
    }.${system}}.tar.gz";
    sha256 = {
      "x86_64-linux"  = "sha256-EuySOs1Ln6OphX9jVzX3pZvzrboAv8JsZFBUj3XEUHA=";
      "aarch64-linux" = "sha256-WcNWzBW0ISxWtuQ4ZiITxUAdBWj1DhsUPoSRkYKUODc=";
    }.${system};
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