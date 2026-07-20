{
  alsa-lib,
  curl,
  dssi,
  fetchurl,
  freetype,
  gettext,
  intltool,
  jack2,
  ladspa-header,
  lib,
  liblo,
  libpng,
  libX11,
  libXcursor,
  libXext,
  libXinerama,
  libXrandr,
  pandoc,
  pkg-config,
  pluginArtifacts,
  stdenv,
  zlib,
}:

stdenv.mkDerivation {
  pname = "amsynth";
  version = "2.0.0";

  src = fetchurl {
    url = "https://github.com/amsynth/amsynth/releases/download/release-2.0.0/amsynth-2.0.0.tar.gz";
    hash = "sha256-5vZkMWY5mk31H40F9Bvb77+mGfULaWAcdCDHGHQXClM=";
  };

  nativeBuildInputs = [
    pkg-config
    intltool
    gettext
    pandoc
  ];

  buildInputs = [
    alsa-lib
    jack2
    ladspa-header
    dssi
    liblo
    freetype
    libpng
    zlib
    curl
    libX11
    libXcursor
    libXext
    libXinerama
    libXrandr
  ];

  configureFlags = [
    "--prefix=/usr"
    "--with-gui"
    "--with-alsa"
    "--with-jack"
    "--with-dssi"
    "--with-nsm"
    "--with-lv2"
    "--with-vst"
    "--with-mts-esp"
    "--without-lash"
    "--without-oss"
  ];

  installPhase = ''
    runHook preInstall

    make install DESTDIR="$PWD/stage"

    ${pluginArtifacts.install {
      sourceRoot = "stage/usr";
      artifacts = [
        {
          format = "lv2";
          source = "lib/lv2/amsynth.lv2";
          type = "directory";
          destination = "amsynth.lv2";
        }
        {
          format = "standalone";
          source = "bin/amsynth";
          type = "executable";
          destination = "amsynth";
        }
      ];
    }}

    runHook postInstall
  '';

  meta = {
    description = "Analog modelling software synthesizer";
    homepage = "https://github.com/amsynth/amsynth";
    license = lib.licenses.gpl3Only;
    mainProgram = "amsynth";
    platforms = lib.platforms.linux;
  };
}
