{
  autoPatchelfHook,
  cairo,
  glib,
  juceRuntime,
  lib,
  libxkbcommon,
  pango,
  pluginArtifacts,
  stdenv,
  unzip,
  xorg,
}:

stdenv.mkDerivation rec {
  pname = "mt-power-drum-kit";
  version = "2.1.5.0";

  # The zip must be downloaded manually from https://www.powerdrumkit.com/linux.php
  # Place it at the path below or override.
  src = builtins.path { path = /home/kalki/Downloads/MTPDK-2.1.5.0-VST3-64bit-Linux-FULL.zip; };

  nativeBuildInputs = [ autoPatchelfHook unzip ];

  buildInputs = juceRuntime.runtimeLibs ++ [
    cairo
    glib
    libxkbcommon
    pango
    stdenv.cc.cc.lib
    xorg.xcbutil
    xorg.xcbutilcursor
  ];

  # Binary distribution — no build needed
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    # The zip extracts with sourceRoot = MT-PowerDrumKit.vst3.
    # We are now inside that directory. Go up, create a wrapper,
    # copy the VST3 bundle into it, and use pluginArtifacts.
    dirname=$(basename "$PWD")
    cd ..
    mkdir -p wrapper
    cp -r "$dirname" wrapper/MT-PowerDrumKit.vst3

    ${pluginArtifacts.install {
      sourceRoot = "wrapper";
      artifacts = [
        {
          format = "vst3";
          source = "MT-PowerDrumKit.vst3";
          type = "directory";
          destination = "MT-PowerDrumKit.vst3";
        }
      ];
    }}

    runHook postInstall
  '';

  meta = with lib; {
    description = "MT Power Drum Kit 2 — acoustic drum sampler VST3 plugin";
    homepage = "https://www.powerdrumkit.com";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
  };
}
