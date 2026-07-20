{
  cmake,
  fetchFromGitHub,
  gccStdenv,
  juceRuntime,
  lib,
  ninja,
  patchelf,
  pkg-config,
  pluginArtifacts,
}:

let
  juceSrc = fetchFromGitHub {
    owner = "juce-framework";
    repo = "JUCE";
    rev = "46c2a95905abffe41a7aa002c70fb30bd3b626ef";
    hash = "sha256-2Bx3QHRcYRPrnw2zZzwleUQ+Q1zOKr4bl8cmsT7vUNs=";
  };

  fxmeFX = fetchFromGitHub {
    owner = "odoare";
    repo = "FxmeFX";
    rev = "391348633cf72b1d773e3b372c4a68f8622a2286";
    hash = "sha256-TdOLKUWNt6ra+eIWnhhDLDI8bbCLa6cNj1QBDlvilrQ=";
  };

  fxmeTools = fetchFromGitHub {
    owner = "odoare";
    repo = "FxmeTools";
    rev = "cd19f4b9ff10ce77a4db091abe31ca1f7e7f7c6b";
    hash = "sha256-/UzxaiqRD81h0MIwza1sa8u0KQs8X+osg1HDMqkWHM8=";
  };

  wdlSrc = fetchFromGitHub {
    owner = "odoare";
    repo = "WDL";
    rev = "599228ffee6ad8d02122a171e0e79271b24abbd3";
    hash = "sha256-La/VrwCVvY9wJvUZ0MPrWxKYJYB+1GmCpmkCUehV1lk=";
  };
in
gccStdenv.mkDerivation {
  pname = "mechanodd";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "odoare";
    repo = "Mechanodd";
    rev = "d9970ad0a25fff49740f9cfa5f5b0f1390fe2911";
    hash = "sha256-Ydjaho9iu8sACW8ANEyLS3PAO0olwCezvpXf80aoz78=";
  };

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
    patchelf
  ];

  buildInputs = juceRuntime.runtimeLibs;

  dontPatchELF = true;

  configurePhase = ''
    runHook preConfigure

    rm -rf lib/FxmeFX
    cp -r --no-preserve=mode ${fxmeFX} lib/FxmeFX
    chmod -R +w lib/FxmeFX
    rm -rf lib/FxmeFX/lib/FxmeTools
    cp -r --no-preserve=mode ${fxmeTools} lib/FxmeFX/lib/FxmeTools
    rm -rf lib/FxmeFX/lib/FxmeTools/WDL
    cp -r --no-preserve=mode ${wdlSrc} lib/FxmeFX/lib/FxmeTools/WDL

    substituteInPlace CMakeLists.txt \
      --replace-fail 'add_subdirectory(../JUCE JUCE)' "add_subdirectory(${juceSrc} JUCE)" \
      --replace-fail 'COPY_PLUGIN_AFTER_BUILD     TRUE' 'COPY_PLUGIN_AFTER_BUILD     FALSE'

    substituteInPlace lib/FxmeFX/lib/FxmeTools/FxmeTools/components/SpectrumDisplay.cpp \
      --replace-fail \
      'juce::GlyphArrangement::getStringWidth (juce::Font (10.0f), txt)' \
      'juce::Font (10.0f).getStringWidth (txt)' \
      --replace-fail \
      'juce::GlyphArrangement::getStringWidth (juce::Font (11.0f), label)' \
      'juce::Font (11.0f).getStringWidth (label)'

    substituteInPlace lib/FxmeFX/lib/FxmeTools/FxmeTools/components/PresetComponent.cpp \
      --replace-fail \
      'juce::GlyphArrangement::getStringWidthInt (g.getCurrentFont(), row.text)' \
      'g.getCurrentFont().getStringWidth (row.text)'

    cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_AR=${gccStdenv.cc.cc}/bin/gcc-ar \
      -DCMAKE_RANLIB=${gccStdenv.cc.cc}/bin/gcc-ranlib

    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild

    cmake --build build --target MechanOddBinaryData -j1
    cmake --build build --target MechanOdd_VST3 MechanOdd_Standalone -j2

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    patchelf --add-rpath "${juceRuntime.runtimeRpath}" \
      "build/MechanOdd_artefacts/Release/VST3/MechanOdd.vst3/Contents/x86_64-linux/MechanOdd.so"
    patchelf --add-rpath "${juceRuntime.runtimeRpath}" \
      "build/MechanOdd_artefacts/Release/Standalone/MechanOdd"

    ${pluginArtifacts.install {
      sourceRoot = "build";
      artifacts = [
        {
          format = "vst3";
          source = "MechanOdd_artefacts/Release/VST3/MechanOdd.vst3";
          type = "directory";
          destination = "MechanOdd.vst3";
        }
        {
          format = "standalone";
          source = "MechanOdd_artefacts/Release/Standalone/MechanOdd";
          type = "executable";
          destination = "MechanOdd";
        }
      ];
    }}

    runHook postInstall
  '';

  meta = {
    description = "Physical-modelling synthesizer audio plugin";
    homepage = "https://github.com/odoare/Mechanodd";
    license = lib.licenses.unfree;
    mainProgram = "MechanOdd";
    platforms = lib.platforms.linux;
  };
}
