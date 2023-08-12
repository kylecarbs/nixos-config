# The nixpkgs derivation builds Gateway which doesn't work on
# aarch64, and seemed unnecessary when it's so simple.
{ stdenv, lib, fetchurl, makeWrapper, unzip, jdk, ... }:

let
  system = stdenv.system or stdenv.hostPlatform.system;
in
stdenv.mkDerivation rec {
  pname = "jetbrains-gateway";
  version = "2023.2";

  src = fetchurl {
    url = "https://download.jetbrains.com/idea/gateway/JetBrainsGateway-${version}${
      { "x86_64-linux" = ""; "aarch64-linux" = "-aarch64"; }.${system}
    }.tar.gz";
    sha256 = {
      "x86_64-linux" = "sha256-i0BkZw9C0YEs9EBo3ZidUYtG/QSovUtrXo+E6aRPWLI=";
      "aarch64-linux" = "sha256-wMQOZYIXZj+1jJGXO7c8//624ycdnQ8pF0m9biCgnMo=";
    }.${system};
  };

  nativeBuildInputs = [ unzip makeWrapper ];

  installPhase = ''
    mkdir -p $out/bin $out/share
    mv * $out/share/
    makeWrapper $out/share/bin/gateway.sh $out/bin/jetbrains-gateway \
      --run "export GATEWAY_JDK=${jdk}" --run "export GDK_SCALE=1"
  '';

  meta = with lib; {
    description = "JetBrains Gateway";
    homepage = https://www.jetbrains.com/gateway/;
    license = licenses.asl20;
    platforms = platforms.linux;
    maintainers = with maintainers; [ ]; # Place your maintainer name within the brackets
  };
}
