{ config, pkgs, ... }:

let
  intelVisionDrivers = config.boot.kernelPackages.callPackage
    ({ lib, stdenv, fetchFromGitHub, kernel, kernelModuleMakeFlags }:
      stdenv.mkDerivation {
        pname = "intel-vision-drivers";
        version = "unstable-2026-05-29";

        src = fetchFromGitHub {
          owner = "intel";
          repo = "vision-drivers";
          rev = "845d6f8bdf66ff1f455901da9de5e00a53a83dce";
          hash = "sha256-i/qZN8GXyqaE6n6pRtxQLdmGhmPDjoArzVvflDmwuSs=";
        };

        nativeBuildInputs = kernel.moduleBuildDependencies;

        makeFlags = kernelModuleMakeFlags ++ [
          "KERNELRELEASE=${kernel.modDirVersion}"
          "KERNEL_SRC=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
        ];

        enableParallelBuilding = true;

        preInstall = ''
          sed -i -e "s,INSTALL_MOD_DIR=,INSTALL_MOD_PATH=$out INSTALL_MOD_DIR=," Makefile
        '';

        installTargets = [ "modules_install" ];

        meta = {
          description = "Intel Camera Vision Sensor kernel driver";
          homepage = "https://github.com/intel/vision-drivers";
          license = lib.licenses.gpl2Only;
          platforms = [ "x86_64-linux" ];
        };
      })
    { };

  ipuBridgeCameraModule = config.boot.kernelPackages.callPackage
    ({ lib, stdenv, kernel, kernelModuleMakeFlags, xz }:
      stdenv.mkDerivation {
        pname = "ipu-bridge-camera-module";
        version = kernel.modDirVersion;

        src = kernel.src;

        # Firmware reports this OV08X40 module as upright even though the
        # installed sensor is physically inverted, so libcamera clients need a
        # kernel fwnode rotation quirk to display the image right-side up.
        patches = [
          ../patches/linux/ipu-bridge-dell-xps-14-da14260-ov08x40-rotation.patch
        ];

        nativeBuildInputs = kernel.moduleBuildDependencies ++ [ xz ];

        preBuild = ''
          mkdir ipu-bridge-module
          cp drivers/media/pci/intel/ipu-bridge.c ipu-bridge-module/
          printf 'obj-m := ipu-bridge.o\n' > ipu-bridge-module/Makefile
        '';

        makeFlags = kernelModuleMakeFlags ++ [
          "-C"
          "${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
          "M=$(PWD)/ipu-bridge-module"
        ];

        buildFlags = [ "modules" ];

        installPhase = ''
          runHook preInstall

          install -Dm444 ipu-bridge-module/ipu-bridge.ko \
            $out/lib/modules/${kernel.modDirVersion}/updates/ipu-bridge.ko
          xz -T$NIX_BUILD_CORES \
            $out/lib/modules/${kernel.modDirVersion}/updates/ipu-bridge.ko

          runHook postInstall
        '';

        meta = {
          description = "Patched Intel IPU bridge camera module";
          license = lib.licenses.gpl2Only;
          platforms = [ "x86_64-linux" ];
        };
      })
    { };

  ov08x40CameraModule = config.boot.kernelPackages.callPackage
    ({ lib, stdenv, kernel, kernelModuleMakeFlags, xz }:
      stdenv.mkDerivation {
        pname = "ov08x40-camera-module";
        version = kernel.modDirVersion;

        src = kernel.src;

        # The upstream sensor driver is missing crop-selection metadata, and
        # this platform's 1928-wide binned modes produce black IPU7 frames.
        # Carry both quirks until the kernel exposes a working OV08X40 mode set.
        patches = [
          ../patches/linux/ov08x40-get-selection.patch
          ../patches/linux/ov08x40-disable-binned-modes.patch
        ];

        nativeBuildInputs = kernel.moduleBuildDependencies ++ [ xz ];

        preBuild = ''
          mkdir ov08x40-module
          cp drivers/media/i2c/ov08x40.c ov08x40-module/
          printf 'obj-m := ov08x40.o\n' > ov08x40-module/Makefile
        '';

        makeFlags = kernelModuleMakeFlags ++ [
          "-C"
          "${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
          "M=$(PWD)/ov08x40-module"
        ];

        buildFlags = [ "modules" ];

        installPhase = ''
          runHook preInstall

          install -Dm444 ov08x40-module/ov08x40.ko \
            $out/lib/modules/${kernel.modDirVersion}/updates/ov08x40.ko
          xz -T$NIX_BUILD_CORES \
            $out/lib/modules/${kernel.modDirVersion}/updates/ov08x40.ko

          runHook postInstall
        '';

        meta = {
          description = "Patched OV08X40 camera sensor kernel module";
          license = lib.licenses.gpl2Only;
          platforms = [ "x86_64-linux" ];
        };
      })
    { };

  libcameraOv08x40 = pkgs.libcamera.overrideAttrs (oldAttrs: {
    buildInputs = (oldAttrs.buildInputs or [ ]) ++ [
      pkgs.libglvnd
    ];

    # These upstream libcamera patches make the simple pipeline usable for
    # OV08X40/IPU7: add the sensor helper needed by AGC and fix simple-IPA
    # black-level handling for CPU/GPU software ISP output.
    patches = (oldAttrs.patches or [ ]) ++ [
      (pkgs.fetchpatch {
        url = "https://patchwork.libcamera.org/patch/26876/mbox/";
        hash = "sha256-isdEgFWTHxxl+b6D9ICEoaMOVixY1WpRewTJ15cl7sI=";
      })
      (pkgs.fetchpatch {
        url = "https://patchwork.libcamera.org/patch/26998/mbox/";
        hash = "sha256-KUdEsVJ9l7cH6XNiF/DTGW7bvFLoip05jA2DmpNOXro=";
      })
      (pkgs.fetchpatch {
        url = "https://patchwork.libcamera.org/patch/26999/mbox/";
        hash = "sha256-K71udV3IpcbrY2YqrAedV3IX/tWM4bEAWvmFS0mkwGs=";
      })
      (pkgs.fetchpatch {
        url = "https://patchwork.libcamera.org/patch/27000/mbox/";
        hash = "sha256-Quk/Uqqdp7kfj8XnbUsF0zo6yFeHqZWN72KXUnBBC1A=";
      })
      (pkgs.fetchpatch {
        url = "https://patchwork.libcamera.org/patch/27001/mbox/";
        hash = "sha256-xAj2WHJZJupBCksRjj1NmQnADqfc5orzU2mKQhssoD4=";
      })
    ];
  });

  pipewireWithLibcamera = (pkgs.pipewire.override {
    libcamera = libcameraOv08x40;
  }).overrideAttrs (oldAttrs: {
    # Zoom uses the legacy V4L2 camera path. Stock pw-v4l2 exposes this camera
    # as RGB-only, which Zoom detects but does not render; this patch provides
    # a converted YUYV stream and nudges legacy clients toward 1080p/30.
    patches = (oldAttrs.patches or [ ]) ++ [
      ../patches/pipewire/pw-v4l2-yuyv-compat-format.patch
    ];
  });

  # Keep the workaround scoped to the IPU7 laptop. Browser clients use native
  # PipeWire, but the Zoom desktop app needs pw-v4l2 to see the converted YUYV
  # compatibility stream.
  zoomWithIpu7Camera = pkgs.symlinkJoin {
    name = "zoom-us-ipu7-camera";
    paths = [ pkgs.zoom-us ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      rm -f $out/bin/zoom $out/bin/zoom-us
      makeWrapper ${pipewireWithLibcamera}/bin/pw-v4l2 $out/bin/zoom \
        --add-flags ${pkgs.zoom-us}/bin/zoom
      makeWrapper ${pipewireWithLibcamera}/bin/pw-v4l2 $out/bin/zoom-us \
        --add-flags ${pkgs.zoom-us}/bin/zoom-us
    '';
  };

in
{
  boot = {
    extraModulePackages = [
      intelVisionDrivers
      ipuBridgeCameraModule
      ov08x40CameraModule
    ];
    kernelModules = [
      "usbio"
      "gpio_usbio"
      "i2c_usbio"
      "intel_cvs"
      "intel_skl_int3472_discrete"
      "ov08x40"
      "intel_ipu7"
    ];
    blacklistedKernelModules = [ "intel_ipu7_psys" ];
    extraModprobeConfig = ''
      softdep intel_ipu7 pre: usbio gpio_usbio i2c_usbio intel_cvs intel_skl_int3472_discrete
      softdep ov08x40 pre: intel_cvs
    '';
  };

  hardware.firmware = [ pkgs.ivsc-firmware ];

  services.pipewire.package = pipewireWithLibcamera;

  services.pipewire.wireplumber.package = pkgs.wireplumber.override {
    pipewire = pipewireWithLibcamera;
  };

  services.pipewire.wireplumber.extraConfig."ipu7-camera-rules" = {
    "monitor.v4l2.rules" = [
      {
        matches = [{ "device.product.name" = "ipu7"; }];
        actions."update-props"."device.disabled" = true;
      }
    ];

    "monitor.libcamera.rules" = [
      {
        matches = [
          {
            "device.product.name" = "ov08x40";
            "node.name" = "~libcamera_input.*";
          }
        ];
        actions."update-props" = {
          "node.description" = "Intel MIPI Camera";
          "node.nick" = "Intel MIPI Camera";
          "node.pause-on-idle" = true;
          "priority.session" = 900;
        };
      }
    ];
  };

  environment.systemPackages = [
    zoomWithIpu7Camera
  ];
}
