{
  alsa-lib,
  cmake,
  curl,
  expat,
  fetchFromGitHub,
  fontconfig,
  freetype,
  lib,
  libGL,
  libX11,
  libXcursor,
  libXext,
  libXinerama,
  libXrandr,
  libXrender,
  libXScrnSaver,
  ninja,
  pkg-config,
  stdenv,
}:

stdenv.mkDerivation {
  pname = "projucer";
  version = "8.0.1";

  src = fetchFromGitHub {
    owner = "juce-framework";
    repo = "JUCE";
    rev = "46c2a95905abffe41a7aa002c70fb30bd3b626ef";
    hash = "sha256-2Bx3QHRcYRPrnw2zZzwleUQ+Q1zOKr4bl8cmsT7vUNs=";
  };

  nativeBuildInputs = [ cmake ninja pkg-config ];

  buildInputs = [
    alsa-lib
    curl
    expat
    fontconfig
    freetype
    libGL
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
    cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DJUCE_BUILD_EXTRAS=ON
    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild
    cmake --build build --target Projucer -j"$NIX_BUILD_CORES"
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/bin" "$out/share/juce"
    cp build/extras/Projucer/Projucer_artefacts/Release/Projucer "$out/bin/"
    cp -r modules "$out/share/juce/"
    runHook postInstall
  '';

  meta = {
    description = "Projucer project management tool from JUCE";
    homepage = "https://juce.com";
    license = lib.licenses.gpl3Plus;
    platforms = lib.platforms.linux;
  };
}
