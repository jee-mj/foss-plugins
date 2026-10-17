{
  cairo,
  fetchFromGitHub,
  freetype,
  lib,
  libsndfile,
  libX11,
  lv2,
  pkg-config,
  pluginArtifacts,
  stdenv,
  which,
  xxd,
}:

stdenv.mkDerivation {
  pname = "toneshifteq";
  version = "1.3.0";

  src = fetchFromGitHub {
    owner = "brummer10";
    repo = "ToneShiftEQ";
    rev = "2c9798ded641988d59e6d5e79fa88feb2d9ff13c"; # v1.3.0
    fetchSubmodules = true;
    hash = "sha256-y85UbyIbkFS8UDxzLg23nPQyqS/GRX1VEcVg5Rr/9Go=";
  };

  nativeBuildInputs = [ pkg-config which xxd ];
  buildInputs = [ cairo freetype libsndfile libX11 lv2 ];

  # Select the three actual plugin targets; the default also builds a JACK app.
  # Override upstream's /proc/cpuinfo probe with baseline x86_64 instructions.
  makeFlags = [ "STRIP=true" "TERM=" ];
  preBuild = ''
    makeFlagsArray+=("SSE_CFLAGS=-msse2 -mfpmath=sse -mfxsr -DUSE_SSE=1")
  '';
  buildFlags = [ "clap" "vst3" "lv2" ];
  enableParallelBuilding = true;

  installPhase = ''
    runHook preInstall
    ${pluginArtifacts.install {
      sourceRoot = "bin";
      artifacts = [
        {
          format = "clap";
          source = "toneshifteq.clap";
          type = "file";
          destination = "toneshifteq.clap";
        }
        {
          format = "vst3";
          source = "Toneshifteq.vst3";
          type = "directory";
          destination = "Toneshifteq.vst3";
        }
        {
          format = "lv2";
          source = "ToneShiftEQ.lv2";
          type = "directory";
          destination = "ToneShiftEQ.lv2";
        }
      ];
    }}
    install -Dm644 LICENSE "$out/share/licenses/toneshifteq/LICENSE"
    install -Dm644 libxputty/LICENSE "$out/share/licenses/toneshifteq/libxputty-LICENSE"
    install -Dm644 EQ12/AudioFFT/COPYING.txt "$out/share/licenses/toneshifteq/AudioFFT-COPYING.txt"
    install -Dm644 EQ12/vst3/travesty/LICENSE "$out/share/licenses/toneshifteq/travesty-LICENSE"
    install -Dm644 libxputty/xputty/resources/LICENSE.txt "$out/share/licenses/toneshifteq/Roboto-Apache-2.0.txt"
    # Preserve the embedded notices without installing the complete vendor code.
    sed -n '1,/^ \*\//p' libxputty/xputty/header/nanosvg.h > "$out/share/licenses/toneshifteq/NanoSVG.txt"
    sed -n '1,/^ \*\//p' libxputty/xputty/xdgmime/xdgmime.h > "$out/share/licenses/toneshifteq/xdgmime.txt"
    runHook postInstall
  '';

  meta = {
    description = "Twelve-band parametric equalizer with spectrum analysis and IR matching";
    homepage = "https://github.com/brummer10/ToneShiftEQ";
    # xdgmime: choose the AFL-2.0 alternative; Roboto: Apache-2.0.
    license = with lib.licenses; [ bsd3 bsd0 mit isc zlib afl20 asl20 ];
    platforms = [ "x86_64-linux" ];
  };
}
