{
  alsa-lib,
  dejavu_fonts,
  fetchFromGitHub,
  fontconfig,
  freetype,
  gccStdenv,
  lib,
  libGL,
  libjack2,
  libX11,
  libXcursor,
  libXext,
  libXinerama,
  libXrandr,
  libXrender,
  libXScrnSaver,
  pkg-config,
  pluginArtifacts,
  projucer,
}:

gccStdenv.mkDerivation {
  pname = "rdpiano";
  version = "0-unstable-2024-01-01";

  src = fetchFromGitHub {
    owner = "giulioz";
    repo = "rdpiano";
    rev = "995e0679d6b9f1c8546d4924742f46f6e0d4741c";
    hash = "sha256-nBJ3NInwuT4KMGY5HpycfbZ4GjuEGQIqMqpoyUGT/TA=";
  };

  nativeBuildInputs = [ projucer pkg-config ];

  buildInputs = [
    alsa-lib
    dejavu_fonts
    fontconfig
    freetype
    libGL
    libjack2
    libX11
    libXcursor
    libXext
    libXinerama
    libXrandr
    libXrender
    libXScrnSaver
  ];

  configurePhase = ''
    runHook preConfigure
    ln -s "${projucer}/share/juce" rdpiano_juce/JUCE

    export HOME="$TMPDIR"
    export JUCE_FONT_PATH="${dejavu_fonts}/share/fonts/truetype"

    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild
    ${projucer}/bin/Projucer --resave rdpiano_juce/rdpiano_juce.jucer
    make -C rdpiano_juce/Builds/LinuxMakefile -j"$NIX_BUILD_CORES" CONFIG=Release
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    ${pluginArtifacts.install {
      sourceRoot = "rdpiano_juce/Builds/LinuxMakefile";
      artifacts = [
        {
          format = "vst3";
          source = "build/rdpiano_juce.vst3";
          type = "directory";
          destination = "rdpiano_juce.vst3";
        }
        {
          format = "lv2";
          source = "build/rdpiano_juce.lv2";
          type = "directory";
          destination = "rdpiano_juce.lv2";
        }
        {
          format = "standalone";
          source = "build/rdpiano_juce";
          type = "executable";
          destination = "rdpiano_juce";
        }
      ];
    }}
    runHook postInstall
  '';

  meta = {
    description = "RDPiano physical modeling piano instrument";
    homepage = "https://github.com/giulioz/rdpiano";
    license = lib.licenses.unfree;
    platforms = lib.platforms.linux;
  };
}
