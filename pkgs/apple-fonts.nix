# Adds all Apple fonts!
{ lib, stdenv, fetchurl, p7zip, cpio }:

stdenv.mkDerivation rec {
  pname = "apple-fonts";
  version = "2026-09-11";

  pro = fetchurl {
    url = "https://devimages-cdn.apple.com/design/resources/download/SF-Pro.dmg";
    sha256 = "sha256-loqzuLH5LC2K9h6waA9cIiTE541ZuYa/AEUCp/wBKRg=";
  };

  compact = fetchurl {
    url = "https://devimages-cdn.apple.com/design/resources/download/SF-Compact.dmg";
    sha256 = "sha256-wdDjROut1m62LwP4I3hMzknxeH9WVj+wmPygH8VUE1w=";
  };

  mono = fetchurl {
    url = "https://devimages-cdn.apple.com/design/resources/download/SF-Mono.dmg";
    sha256 = "sha256-bUoLeOOqzQb5E/ZCzq0cfbSvNO1IhW1xcaLgtV2aeUU=";
  };

  ny = fetchurl {
    url = "https://devimages-cdn.apple.com/design/resources/download/NY.dmg";
    sha256 = "sha256-HC7ttFJswPMm+Lfql49aQzdWR2osjFYHJTdgjtuI+PQ=";
  };

  nativeBuildInputs = [ p7zip cpio ];

  sourceRoot = ".";

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/fontfiles
    # The 2026 Pro/Compact APFS images expose a gzip-compressed CPIO payload
    # directly through p7zip, unlike the older Mono/New York HFS images.
    for image in ${pro} ${compact}; do
      mkdir unpack
      cd unpack
      7z x "$image"
      cpio -id --no-absolute-filenames < 'Payload~'
      mv Library/Fonts/* $out/fontfiles
      cd ..
      rm -r unpack
    done

    7z x ${mono}
    cd SFMonoFonts
    7z x 'SF Mono Fonts.pkg'
    7z x 'Payload~'
    mv Library/Fonts/* $out/fontfiles
    cd ..

    7z x ${ny}
    cd NYFonts
    7z x 'NY Fonts.pkg'
    7z x 'Payload~'
    mv Library/Fonts/* $out/fontfiles

    mkdir -p $out/usr/share/fonts/OTF $out/usr/share/fonts/TTF
    mv $out/fontfiles/*.otf $out/usr/share/fonts/OTF
    mv $out/fontfiles/*.ttf $out/usr/share/fonts/TTF
    rm -rf $out/fontfiles
  '';

  meta = {
    description = "Apple San Francisco, New York fonts";
    homepage = "https://developer.apple.com/fonts/";
    license = lib.licenses.unfree;
  };
}
