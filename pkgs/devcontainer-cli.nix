{
  lib,
  stdenv,
  fetchzip,
  nodejs_18
}:
let
  pname = "devcontainers-cli";
  version = "0.56.2";
  hash = "sha256-1cLw7FPfdbIE6ovZuimS+aBiSxTiXtx/EJx2kyTbgU4=";
in
stdenv.mkDerivation {
  inherit pname version;

  src = fetchzip {
    inherit hash;
    url = "https://registry.npmjs.org/@devcontainers/cli/-/cli-${version}.tgz";
  };

  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    mkdir -p $out/bin
    cp -a "$src/." "$out"
    rm devcontainer.js
  '';

  postFixup = ''
    cat <<EOF > $out/bin/devcontainer
    #!${nodejs_18}/bin/node
      require('$out/dist/spec-node/devContainersSpecCLI');
    EOF

    chmod +x $out/bin/devcontainer
  '';

  meta = with lib; {
    homepage = "https://containers.dev";
    description = "A reference implementation for the specification that can create and configure a dev container from a devcontainer.json";
    license = licenses.mit;
    platforms = lib.intersectLists (lib.platforms.linux) (lib.platforms.x86_64);
    maintainers = with maintainers; [ mr360 ];
  };
}