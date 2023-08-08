{ stdenv, lib, fetchurl, makeWrapper, unzip, jdk }:

stdenv.mkDerivation rec {
  pname = "jetbrains-gateway";
  version = "2023.2";

  src = fetchurl {
    url = "https://download.jetbrains.com/idea/gateway/JetBrainsGateway-${version}-aarch64.tar.gz";
    sha256 = "sha256-wMQOZYIXZj+1jJGXO7c8//624ycdnQ8pF0m9biCgnMo=";  # Replace this line with the actual hash
  };

  nativeBuildInputs = [ unzip makeWrapper ];

  installPhase = ''
    mkdir -p $out/bin $out/share
    mv * $out/share/
    makeWrapper $out/share/bin/gateway.sh $out/bin/jetbrains-gateway \
      --run "export GATEWAY_JDK=${jdk}"
  '';

  meta = with lib; {
    description = "JetBrains Gateway";
    homepage = https://www.jetbrains.com/gateway/;
    license = licenses.asl20;
    platforms = platforms.linux;
    maintainers = with maintainers; [ ]; # Place your maintainer name within the brackets
  };
}