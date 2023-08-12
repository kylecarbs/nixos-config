# Wraps alacritty to add the LIBGL_ALWAYS_SOFTWARE=1 env var for software rendering the terminal.
self: super:

{
  alacritty = super.alacritty.overrideAttrs (oldAttrs: {
    postInstall = oldAttrs.postInstall or "" + ''
      wrapProgram $out/bin/alacritty \
        --set LIBGL_ALWAYS_SOFTWARE "1"
    '';
  });
}
