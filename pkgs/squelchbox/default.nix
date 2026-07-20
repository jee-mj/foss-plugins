{
  alsa-lib,
  fetchFromGitHub,
  git,
  jack2,
  lib,
  libGL,
  libX11,
  libXcursor,
  libXrandr,
  libxcb,
  libxkbcommon,
  pkg-config,
  pluginArtifacts,
  runCommand,
  rustPlatform,
}:

rustPlatform.buildRustPackage {
  pname = "squelchbox";
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "Hornfisk";
    repo = "squelchbox";
    rev = "6d0cebc304237cf8df19998d4fbad50b828b862a";
    hash = "sha256-e4bAWUhApUfQ70QE5rOdrwgJ/AFoXH1pY4M9orDOLAs=";
  };

  cargoHash = "sha256-mS8uUc9+8kiAOw9uxfXG3KdD6u/ODMMunCgRukAb/TE=";

  # Vendoring happens before postPatch, so provide the committed resolution first.
  cargoPatches = [
    (runCommand "squelchbox-cargo-lock.patch" { nativeBuildInputs = [ git ]; } ''
      cp ${./Cargo.lock} Cargo.lock
      git init --quiet
      git add Cargo.lock
      git diff --cached > "$out"
    '')
  ];

  postPatch = ''
    substituteInPlace xtask/Cargo.toml \
      --replace-fail \
      'nih_plug_xtask = { git = "https://github.com/robbert-vdh/nih-plug" }' \
      'nih_plug_xtask = { git = "https://github.com/robbert-vdh/nih-plug", rev = "28b149ec4d62757d0b448809148a0c3ca6e09a95" }'
    cp ${./Cargo.lock} Cargo.lock
  '';

  CARGO_NET_OFFLINE = "true";
  auditable = false;

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    alsa-lib
    jack2
    libGL
    libX11
    libXcursor
    libXrandr
    libxcb
    libxkbcommon
  ];

  buildPhase = ''
    runHook preBuild

    cargo xtask bundle squelchbox --release --target x86_64-unknown-linux-gnu

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    ${pluginArtifacts.install {
      sourceRoot = "target";
      artifacts = [
        {
          format = "vst3";
          source = "bundled/squelchbox.vst3";
          type = "directory";
          destination = "squelchbox.vst3";
        }
        {
          format = "clap";
          source = "bundled/squelchbox.clap";
          type = "executable";
          destination = "squelchbox.clap";
        }
        {
          format = "standalone";
          source = "x86_64-unknown-linux-gnu/release/squelchbox-standalone";
          type = "executable";
          destination = "squelchbox";
        }
      ];
    }}

    runHook postInstall
  '';

  meta = {
    description = "TB-303-style acid bassline synthesizer plugin";
    homepage = "https://github.com/Hornfisk/squelchbox";
    license = lib.licenses.gpl3Plus;
    mainProgram = "squelchbox";
    platforms = lib.platforms.linux;
  };
}
