{ lib, alsa-lib, expat, fontconfig, freetype, libGL, libX11, libXcursor
, libXext, libXinerama, libXrandr, libXrender, libXScrnSaver
}:
let
  runtimeLibs = [
    alsa-lib expat fontconfig freetype libGL libX11 libXcursor libXext
    libXinerama libXrandr libXrender libXScrnSaver
  ];
in {
  inherit runtimeLibs;
  runtimeRpath = lib.makeLibraryPath runtimeLibs;
}
