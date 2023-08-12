# Adds the Apple Color Emoji font. The default emojis in Linux are gross.
{ stdenvNoCC, lib, fetchurl }:

stdenvNoCC.mkDerivation rec {
  pname = "apple-emoji";
  dontUnpack = true;
  version = "v16.4";

  src = fetchurl {
    url = "https://github.com/samuelngs/apple-emoji-linux/releases/download/${version}/AppleColorEmoji.ttf";
    sha256 = "sha256-goY9lWBtOnOUotitjVfe96zdmjYTPT6PVOnZ0MEWh0U=";
  };

  installPhase = ''
    install -Dm644 $src -t $out/share/fonts/truetype
  '';

  meta = with lib; {
    description = "Apple Color Emoji for Linux";
    longDescription = "AppleColorEmoji.ttf from Samuel Ng's apple-emoji-linux, release version ${version}, packaged for Nix.";
    homepage = "https://github.com/samuelngs/apple-emoji-linux";
    license = licenses.wtfpl;
    platforms = platforms.unix;
  };
}
