{ lib, stdenv, kernel, kernelModuleMakeFlags, xz }:

stdenv.mkDerivation {
  pname = "intel-cvs";
  version = kernel.modDirVersion;

  src = kernel.src;
  sourceRoot = "source";
  unpackPhase = ''
    runHook preUnpack
    mkdir source
    tar -xf "$src" --strip-components=1 -C source \
      --wildcards '*/drivers/media/i2c/cvs/*'
    runHook postUnpack
  '';

  patches = [ ../patches/ipu7/cvs-wake-irq.patch ];

  nativeBuildInputs = kernel.moduleBuildDependencies ++ [ xz ];
  enableParallelBuilding = true;

  makeFlags = kernelModuleMakeFlags ++ [
    "-C"
    "${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
    "M=$(PWD)/drivers/media/i2c/cvs"
    "CONFIG_VIDEO_INTEL_CVS=m"
  ];
  buildFlags = [ "modules" ];

  installPhase = ''
    runHook preInstall
    install -Dm444 drivers/media/i2c/cvs/intel_cvs.ko \
      $out/lib/modules/${kernel.modDirVersion}/updates/intel_cvs.ko
    xz -T$NIX_BUILD_CORES \
      $out/lib/modules/${kernel.modDirVersion}/updates/intel_cvs.ko
    runHook postInstall
  '';

  meta = {
    description = "Intel CVS camera bridge with shared audio GPIO fix";
    license = lib.licenses.gpl2Only;
    platforms = [ "x86_64-linux" ];
  };
}
