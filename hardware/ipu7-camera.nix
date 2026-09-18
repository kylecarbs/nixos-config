# Dell XPS 14 DA14260: OV08X40 on Panther Lake IPU7.
{ config, lib, pkgs, ... }:

{
  # CVS and the audio amplifiers share a GPIO on this Dell. The upstream
  # fix obtains the wake IRQ without reserving the amplifier's pin.
  boot.extraModulePackages = [
    (config.boot.kernelPackages.callPackage ../pkgs/intel-cvs.nix { })
  ];
  # Intel's packaged HAL predates the Linux 7.2 CVS media bridge. Backport
  # upstream topology support until nixpkgs includes it for Panther Lake.
  nixpkgs.overlays = [
    (final: prev: {
      ipu75xa-camera-hal = prev.ipu75xa-camera-hal.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [ ../patches/ipu7/cvs-media-path.patch ];
      });
    })
  ];

  # Linux 7.2 supplies CVS, USB-I/O and the sensor driver. The IPU7 module
  # adds Intel's PSys driver, factory tuning and the processed virtual camera.
  boot.kernelModules = [
    "usbio"
    "gpio_usbio"
    "i2c_usbio"
    "intel_cvs"
    "intel_skl_int3472_discrete"
    "ov08x40"
    "intel_ipu7"
    "intel_ipu7_psys"
  ];

  hardware.ipu7 = {
    enable = true;
    platform = "ipu75xa";
  };

  # GStreamer's output pool needs more than v4l2loopback's two-buffer default.
  boot.extraModprobeConfig = "options v4l2loopback max_buffers=8";

  # The exclusive-caps device starts as output-only. Reannounce it once the
  # relay has made it a capture device; PipeWire otherwise caches no source.
  systemd.services.v4l2-relayd-ipu7.postStart = ''
    device=$(cat "$V4L2_DEVICE_FILE")
    ready=false
    for attempt in $(seq 1 100); do
      if ${pkgs.v4l-utils}/bin/v4l2-ctl -d "$device" -D | ${pkgs.gnugrep}/bin/grep -q 'Video Capture'; then
        ready=true
        break
      fi
      sleep 0.1
    done
    if [ "$ready" != true ]; then
      echo "Camera relay did not become capture-ready" >&2
      exit 1
    fi
    ${pkgs.systemd}/bin/udevadm trigger --action=remove "/sys/class/video4linux/''${device##*/}"
    ${pkgs.systemd}/bin/udevadm settle
    ${pkgs.systemd}/bin/udevadm trigger --action=add "/sys/class/video4linux/''${device##*/}"
    ${pkgs.systemd}/bin/udevadm settle
  '';

  services.v4l2-relayd.instances.ipu7.input = {
    # This module is physically inverted. Intel's HAL does not consume the
    # firmware rotation property that libcamera used.
    pipeline = lib.mkForce "icamerasrc ! video/x-raw,format=NV12,width=1920,height=1080,framerate=30/1 ! videoflip method=rotate-180";
    width = 1920;
    height = 1080;
    framerate = 30;
  };

  # Only the HAL may own the raw sensor. Apps consume the processed loopback
  # camera through either native V4L2 or PipeWire.
  services.pipewire.wireplumber.package = pkgs.wireplumber.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ ../patches/ipu7/wireplumber-disabled-device.patch ];
  });
  services.pipewire.wireplumber.extraConfig."ipu7-camera-rules" = {
    "monitor.v4l2.rules" = [
      {
        matches = [{ "device.product.name" = "ipu7"; }];
        actions."update-props"."device.disabled" = true;
      }
    ];
    "wireplumber.profiles".main."monitor.libcamera" = "disabled";
  };
}
